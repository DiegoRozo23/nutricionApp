import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Servicio para manejar Firebase Cloud Messaging (FCM)
/// Permite recibir notificaciones push incluso cuando la app está cerrada
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  /// Instancia global para acceso fácil
  static FCMService get instance => _instance;

  final supabase = supabaseService.client;
  FirebaseMessaging? _messaging;
  String? _currentToken;
  String? _currentUserId;
  bool _handlersConfigured = false;
  bool _tokenListenerConfigured = false;

  /// Inicializar FCM (sin solicitar permisos todavía)
  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        if (kDebugMode) {
          print('[FCM] Firebase inicializado');
        }
      }

      _messaging = FirebaseMessaging.instance;

      // Configurar handlers para diferentes estados de la app (solo una vez)
      if (!_handlersConfigured) {
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
        _handlersConfigured = true;
      }

      // Verificar si la app fue abierta desde una notificación
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }

      if (kDebugMode) {
        print('[FCM] Servicio inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error al inicializar: $e');
      }
    }
  }

  /// Solicitar permisos de notificaciones (debe llamarse después del login)
  /// Retorna true si el usuario otorgó permisos, false si los denegó
  Future<bool> requestNotificationPermissions() async {
    try {
      if (_messaging == null) {
        await init();
      }

      // Solicitar permisos
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('[FCM] Estado de permisos: ${settings.authorizationStatus}');
      }

      // NO mostrar notificaciones en foreground (primer plano)
      // Cuando la app está abierta, el Realtime subscription ya actualiza la UI
      // Solo mostrar notificaciones cuando la app está en background/cerrada
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: false, // Deshabilitado para evitar duplicados
        badge: true,
        sound: false, // Deshabilitado para evitar duplicados
      );

      // Verificar si se otorgaron permisos
      final isAuthorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (isAuthorized) {
        // Obtener token después de otorgar permisos
        final token = await _messaging!.getToken();
        if (token != null) {
          _currentToken = token;
          
          // Escuchar cambios de token (solo configurar una vez)
          if (!_tokenListenerConfigured) {
            _messaging!.onTokenRefresh.listen((newToken) {
              _currentToken = newToken;
              _saveTokenToSupabase(newToken);
              if (kDebugMode) {
                print('[FCM] Token actualizado: ${newToken.substring(0, 20)}...');
              }
            });
            _tokenListenerConfigured = true;
          }

          // Guardar token si hay usuario actual
          if (_currentUserId != null) {
            await _saveTokenToSupabase(_currentToken!);
          }

          if (kDebugMode) {
            print('[FCM] Token obtenido: ${token.substring(0, 20)}...');
          }
        }
      }

      return isAuthorized;
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error al solicitar permisos: $e');
      }
      return false;
    }
  }

  

  /// Registrar usuario y solicitar permisos (llamar después del login)
  /// Si ya se tienen permisos, solo registra el token
  Future<bool> registerUserToken(String userId) async {
    try {
      _currentUserId = userId;

      // Primero verificar si ya tenemos permisos
      final settings = await _messaging?.getNotificationSettings();
      final hasPermissions = settings?.authorizationStatus == AuthorizationStatus.authorized ||
          settings?.authorizationStatus == AuthorizationStatus.provisional;

      // Si no hay permisos, solicitarlos
      if (!hasPermissions) {
        final granted = await requestNotificationPermissions();
        if (!granted) {
          if (kDebugMode) {
            print('[FCM] Permisos denegados por el usuario');
          }
          return false;
        }
      }

      // Obtener o usar token existente
      if (_currentToken == null) {
        final token = await _messaging?.getToken();
        if (token != null) {
          _currentToken = token;
        } else {
          if (kDebugMode) {
            print('[FCM] No se pudo obtener token');
          }
          return false;
        }
      }

      // Guardar token en Supabase
      await _saveTokenToSupabase(_currentToken!);

      if (kDebugMode) {
        print('[FCM] Token registrado para usuario: $userId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error al registrar token: $e');
      }
      return false;
    }
  }

  /// Guardar token en Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      if (_currentUserId == null) {
        if (kDebugMode) {
          print('[FCM] No hay usuario actual, no se puede guardar token');
        }
        return;
      }

      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
      final deviceId = await _getDeviceId();

      // Upsert: insertar o actualizar si ya existe
      await supabase.from('fcm_tokens').upsert({
        'user_id': _currentUserId,
        'token': token,
        'device_id': deviceId,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('[FCM] Token guardado en Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error al guardar token en Supabase: $e');
      }
    }
  }

  /// Obtener ID del dispositivo (simplificado)
  Future<String> _getDeviceId() async {
    // Usar el token como device_id por ahora
    // En producción podrías usar device_info_plus para obtener un ID único
    return _currentToken?.substring(0, 16) ?? 'unknown';
  }

  /// Manejar mensaje cuando la app está en primer plano
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[FCM] Mensaje recibido en primer plano:');
      print('[FCM] - Título: ${message.notification?.title}');
      print('[FCM] - Cuerpo: ${message.notification?.body}');
      print('[FCM] - Data: ${message.data}');
    }

    // Cuando la app está en primer plano, FCM no muestra notificaciones automáticamente
    // En este caso, el Realtime subscription ya actualiza la UI
    // No necesitamos mostrar notificación local porque el usuario ya está viendo la app
    // Si quieres mostrar notificación local en foreground, puedes usar chatNotificationService aquí
  }

  /// Manejar mensaje cuando la app está en background o cerrada
  void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[FCM] Mensaje recibido en background/cerrada:');
      print('[FCM] - Título: ${message.notification?.title}');
      print('[FCM] - Cuerpo: ${message.notification?.body}');
      print('[FCM] - Data: ${message.data}');
    }

    // Cuando la app se abre desde una notificación, puedes navegar al chat
    // Esto se maneja en el widget principal o en un servicio de navegación
    final roomId = message.data['roomId'];
    if (roomId != null && kDebugMode) {
      print('[FCM] Abrir chat: $roomId');
    }
  }

  /// Limpiar token cuando el usuario cierra sesión
  Future<void> unregisterUserToken() async {
    try {
      if (_currentUserId == null || _currentToken == null) return;

      // Eliminar token de Supabase
      await supabase
          .from('fcm_tokens')
          .delete()
          .eq('user_id', _currentUserId!)
          .eq('token', _currentToken!);

      _currentUserId = null;
      _currentToken = null;

      if (kDebugMode) {
        print('[FCM] Token eliminado de Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error al eliminar token: $e');
      }
    }
  }

  /// Handler estático para mensajes en background (requerido por Firebase)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    if (kDebugMode) {
      print('[FCM] Handler de background ejecutado');
      print('[FCM] - Mensaje: ${message.notification?.title}');
    }
  }
}

/// Instancia global del servicio FCM
final fcmService = FCMService();

