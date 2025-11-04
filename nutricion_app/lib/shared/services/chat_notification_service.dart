import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'fcm_service.dart';

/// Servicio para manejar notificaciones y contador de mensajes sin leer
class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  final supabase = supabaseService.client;
  RealtimeChannel? _messagesChannel;
  int _unreadCount = 0;
  StreamController<int> _unreadCountController = StreamController<int>.broadcast();
  bool _isInitialized = false;
  String? _currentUserId;
  Timer? _checkTimer;
  
  // Notificaciones locales
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  /// Mapa para almacenar contadores por room
  final Map<String, int> _unreadByRoom = {};
  final Map<String, StreamController<int>> _roomUnreadControllers = {};

  /// Stream del contador de mensajes sin leer
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Contador actual de mensajes sin leer
  int get unreadCount => _unreadCount;

  /// Obtener stream de mensajes sin leer para un room específico
  Stream<int> getUnreadCountStream(String roomId) {
    if (!_roomUnreadControllers.containsKey(roomId)) {
      _roomUnreadControllers[roomId] = StreamController<int>.broadcast();
    }
    return _roomUnreadControllers[roomId]!.stream;
  }

  /// Obtener contador de mensajes sin leer para un room específico
  int getUnreadCount(String roomId) {
    return _unreadByRoom[roomId] ?? 0;
  }

  /// Inicializar el servicio de notificaciones
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _isInitialized = false;
        return;
      }

      _currentUserId = user.id;
      
      // Registrar token FCM para notificaciones push cuando la app está cerrada
      try {
        await fcmService.registerUserToken(_currentUserId!);
      } catch (e) {
        // Si FCM no está disponible, continuar sin él
        if (kDebugMode) {
          print('[CHAT_NOTIFICATIONS] FCM no disponible: $e');
        }
      }
      
      // Inicializar notificaciones locales
      await _initLocalNotifications();
      
      // Cargar contador inicial
      await _loadUnreadCount();
      
      // Suscribirse a mensajes nuevos
      _subscribeToNewMessages();
      
      // Verificar periódicamente
      _startPeriodicCheck();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] ✅ Servicio inicializado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] ❌ Error al inicializar: $e');
      }
      _isInitialized = false;
    }
  }

  /// Inicializar notificaciones locales
  Future<void> _initLocalNotifications() async {
    if (_notificationsInitialized) return;

    try {
      // Configuración para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuración para iOS (si es necesario)
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Solicitar permisos en Android 13+
      await _requestPermissions();

      _notificationsInitialized = true;
      
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] ✅ Notificaciones locales inicializadas');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] ❌ Error al inicializar notificaciones: $e');
      }
    }
  }

  /// Solicitar permisos de notificación
  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('[CHAT_NOTIFICATIONS] Notificación tocada: ${response.payload}');
    }
    // Aquí podrías navegar al chat específico usando response.payload (roomId)
  }

  /// Cargar el contador de mensajes sin leer (público para recarga manual)
  Future<void> loadUnreadCount() async {
    await _loadUnreadCount();
  }

  /// Cargar el contador de mensajes sin leer (privado)
  Future<void> _loadUnreadCount() async {
    try {
      if (_currentUserId == null) return;

      // Obtener rooms donde el usuario es miembro
      final roomsResponse = await supabase
          .schema('chats')
          .from('room_members')
          .select('room_id')
          .eq('user_id', _currentUserId!);

      if (roomsResponse == null || (roomsResponse as List).isEmpty) {
        _updateUnreadCount(0);
        return;
      }

      final roomIds = (roomsResponse as List)
          .map((r) => (r as Map<String, dynamic>)['room_id'] as String)
          .toList();

      if (roomIds.isEmpty) {
        _updateUnreadCount(0);
        return;
      }

      // Contar mensajes no leídos
      // Por simplicidad, contamos mensajes recientes (últimas 24 horas) que no fueron enviados por el usuario actual
      // En una implementación completa, deberías usar una tabla de "message_reads" para marcar mensajes leídos
      
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final oneDayAgoMs = oneDayAgo.millisecondsSinceEpoch;

      int totalUnread = 0;
      
      // Obtener el último mensaje leído por room (última vez que el usuario abrió el chat)
      // Por simplicidad, consideramos que todos los mensajes desde hace más de 1 hora son no leídos
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final oneHourAgoMs = oneHourAgo.millisecondsSinceEpoch;
      
      for (final roomId in roomIds) {
        int roomUnread = 0;
        
        try {
          // Contar mensajes que el USUARIO ACTUAL no ha leído
          // Es decir, mensajes que NO son del usuario actual Y el usuario actual NO está en read_by
          final allMessagesResponse = await supabase
              .schema('chats')
              .from('messages')
              .select('id, read, authorId, read_by')
              .eq('roomId', roomId)
              .neq('authorId', _currentUserId!);

          // Filtrar manualmente: solo contar mensajes donde el usuario actual NO está en read_by
          final allMessages = (allMessagesResponse as List? ?? []);
          roomUnread = allMessages.where((msg) {
            final msgMap = msg as Map<String, dynamic>;
            final authorId = msgMap['authorId'] as String? ?? '';
            final readBy = (msgMap['read_by'] as List?) ?? [];
            
            // El mensaje debe:
            // 1. No ser del usuario actual
            // 2. El usuario actual NO debe estar en read_by (es decir, no lo ha leído)
            final isNotFromMe = authorId != _currentUserId;
            final iHaventReadIt = !readBy.contains(_currentUserId);
            
            return isNotFromMe && iHaventReadIt;
          }).length;

          totalUnread += roomUnread;
          
          if (kDebugMode) {
            print('[CHAT_NOTIFICATIONS] Room $roomId: $roomUnread mensajes sin leer por MÍ (de ${allMessages.length} mensajes del otro usuario)');
          }
        } catch (e) {
          if (kDebugMode) {
            print('[CHAT_NOTIFICATIONS] ❌ Error al contar mensajes en room $roomId: $e');
          }
          roomUnread = 0; // En caso de error, asumir 0
        }
        
        // Solo actualizar el contador del room si cambió, para evitar sobrescribir actualizaciones en tiempo real
        final previousCount = _unreadByRoom[roomId] ?? 0;
        if (previousCount != roomUnread) {
          _unreadByRoom[roomId] = roomUnread;
          if (_roomUnreadControllers.containsKey(roomId)) {
            _roomUnreadControllers[roomId]?.add(roomUnread);
          }
        }
      }

      // Solo actualizar el total si realmente cambió
      _updateUnreadCount(totalUnread);
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] Error al cargar contador: $e');
      }
      _updateUnreadCount(0);
    }
  }

  /// Suscribirse a mensajes nuevos en tiempo real
  void _subscribeToNewMessages() {
    try {
      if (_currentUserId == null) return;

      // Cancelar suscripción anterior si existe
      _messagesChannel?.unsubscribe();

      _messagesChannel = supabase
          .channel('messages_notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'chats',
            table: 'messages',
            callback: (payload) {
              if (!mounted) return;

              try {
                final newMessage = payload.newRecord as Map<String, dynamic>?;
                if (newMessage == null) return;

                final roomId = newMessage['roomId'] as String? ?? '';
                final authorId = newMessage['authorId'] as String? ?? '';
                final readBy = (newMessage['read_by'] as List?) ?? [];

                if (roomId.isEmpty) return;

                // Si el mensaje no es nuestro Y el usuario actual NO está en read_by, incrementar contador
                final isNotFromMe = authorId != _currentUserId;
                final iHaventReadIt = !readBy.contains(_currentUserId);
                
                if (isNotFromMe && iHaventReadIt) {
                  final currentCount = _unreadByRoom[roomId] ?? 0;
                  _unreadByRoom[roomId] = currentCount + 1;
                  
                  // Actualizar stream del room
                  if (_roomUnreadControllers.containsKey(roomId)) {
                    _roomUnreadControllers[roomId]?.add(currentCount + 1);
                  }

                  // Actualizar total
                  int newTotal = 0;
                  for (final count in _unreadByRoom.values) {
                    newTotal += count;
                  }
                  _updateUnreadCount(newTotal);

                  // NO mostrar notificación local cuando la app está en background/cerrada
                  // FCM ya envía la notificación push automáticamente
                  // Solo mostrar notificación local cuando la app está en primer plano
                  // (FCM maneja background/cerrada automáticamente)
                  // _showNotification(newMessage, roomId); // Comentado para evitar duplicados

                  if (kDebugMode) {
                    print('[CHAT_NOTIFICATIONS] Nuevo mensaje sin leer por MÍ en room $roomId, contador: ${currentCount + 1}');
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  print('[CHAT_NOTIFICATIONS] Error procesando nuevo mensaje: $e');
                }
              }
            },
          )
          .subscribe();

      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] Suscrito a nuevos mensajes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] Error al suscribirse a mensajes: $e');
      }
    }
  }

  /// Verificar si un mensaje pertenece a un room del usuario
  Future<void> _checkMessageRoom(Map<String, dynamic> message) async {
    try {
      final roomId = message['roomId'] as String?;
      if (roomId == null || _currentUserId == null) return;

      // Verificar si el usuario es miembro del room
      final memberResponse = await supabase
          .schema('chats')
          .from('room_members')
          .select('room_id')
          .eq('room_id', roomId)
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      if (memberResponse != null) {
        // El usuario es miembro, incrementar contador
        await loadUnreadCount();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] Error al verificar room: $e');
      }
    }
  }

  /// Iniciar verificación periódica
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    // Verificar cada 30 segundos (menos agresivo para evitar sobrescribir contadores en tiempo real)
    // Esto solo sirve como respaldo si se pierde una actualización en tiempo real
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_currentUserId != null) {
        // Solo recargar si no hay actividad reciente (para evitar sobrescribir contadores actualizados)
        _loadUnreadCount();
      }
    });
    
    if (kDebugMode) {
      print('[CHAT_NOTIFICATIONS] Verificación periódica iniciada (cada 30 segundos)');
    }
  }

  /// Actualizar contador de mensajes sin leer
  void _updateUnreadCount(int count) {
    // Solo actualizar si realmente cambió para evitar emisiones innecesarias
    if (_unreadCount != count) {
      final oldCount = _unreadCount;
      _unreadCount = count;
      
      // Solo agregar al stream si el controller no está cerrado
      if (!_unreadCountController.isClosed) {
        _unreadCountController.add(count);
      } else {
        // Si está cerrado, recrearlo
        _unreadCountController = StreamController<int>.broadcast();
        _unreadCountController.add(count);
      }
      
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] 📊 Mensajes sin leer: $oldCount → $count');
      }
    }
  }

  /// Marcar un room como leído
  Future<void> markRoomAsRead(String roomId) async {
    try {
      if (_currentUserId == null) return;

      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] 🔄 Marcando room $roomId como leído...');
      }

      // Primero obtener todos los mensajes del room que NO son del usuario actual
      final allMessages = await supabase
          .schema('chats')
          .from('messages')
          .select('id, read_by')
          .eq('roomId', roomId)
          .neq('authorId', _currentUserId!);

      if (allMessages == null || (allMessages as List).isEmpty) {
        if (kDebugMode) {
          print('[CHAT_NOTIFICATIONS] No hay mensajes del otro usuario en room $roomId');
        }
        // Actualizar contador de todos modos
        _unreadByRoom[roomId] = 0;
        if (_roomUnreadControllers.containsKey(roomId)) {
          _roomUnreadControllers[roomId]?.add(0);
        }
        await _loadUnreadCount();
        return;
      }

      // Filtrar solo los mensajes que el usuario actual NO ha leído (no está en read_by)
      final unreadMessages = (allMessages as List).where((msg) {
        final msgMap = msg as Map<String, dynamic>;
        final readBy = (msgMap['read_by'] as List?) ?? [];
        return !readBy.contains(_currentUserId);
      }).toList();

      if (unreadMessages.isEmpty) {
        if (kDebugMode) {
          print('[CHAT_NOTIFICATIONS] Ya he leído todos los mensajes en room $roomId');
        }
        // Actualizar contador de todos modos
        _unreadByRoom[roomId] = 0;
        if (_roomUnreadControllers.containsKey(roomId)) {
          _roomUnreadControllers[roomId]?.add(0);
        }
        await _loadUnreadCount();
        return;
      }

      final messageIds = unreadMessages
          .map((msg) => (msg as Map<String, dynamic>)['id'] as String)
          .toList();

      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] Encontrados ${messageIds.length} mensajes para marcar como leídos');
      }

      // Actualizar cada mensaje individualmente para asegurar que funcione
      int updatedCount = 0;
      for (final messageId in messageIds) {
        try {
          // Obtener read_by actual
          final message = await supabase
              .schema('chats')
              .from('messages')
              .select('read_by')
              .eq('id', messageId)
              .maybeSingle();

          if (message != null) {
            final readBy = (message['read_by'] as List?) ?? [];
            if (!readBy.contains(_currentUserId)) {
              final updatedReadBy = [...readBy, _currentUserId!];
              
              await supabase
                  .schema('chats')
                  .from('messages')
                  .update({
                    'read': true,
                    'read_by': updatedReadBy,
                  })
                  .eq('id', messageId);
              
              updatedCount++;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('[CHAT_NOTIFICATIONS] ❌ Error actualizando mensaje $messageId: $e');
          }
        }
      }

      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] ✅ $updatedCount mensajes marcados como leídos en room $roomId');
      }

      // Actualizar contador del room inmediatamente
      _unreadByRoom[roomId] = 0;
      if (_roomUnreadControllers.containsKey(roomId)) {
        _roomUnreadControllers[roomId]?.add(0);
      }

      // Hacer una recarga completa para asegurar que el total es correcto
      await _loadUnreadCount();

    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] ❌ Error al marcar room como leído: $e');
      }
      // Intentar recargar el contador de todos modos
      await _loadUnreadCount();
    }
  }

  /// Mostrar notificación local cuando llega un mensaje
  Future<void> _showNotification(Map<String, dynamic> message, String roomId) async {
    try {
      if (!_notificationsInitialized) return;

      final text = message['text'] as String? ?? 'Nuevo mensaje';
      final authorId = message['authorId'] as String? ?? '';

      // Obtener nombre del remitente
      String senderName = 'Usuario';
      try {
        final userResponse = await supabase
            .schema('chats')
            .from('users')
            .select('firstName, lastName')
            .eq('id', authorId)
            .maybeSingle();

        if (userResponse != null) {
          final firstName = userResponse['firstName'] as String? ?? '';
          final lastName = userResponse['lastName'] as String? ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            senderName = '$firstName $lastName'.trim();
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('[CHAT_NOTIFICATIONS] Error al obtener nombre del remitente: $e');
        }
      }

      // Configuración de Android
      const androidDetails = AndroidNotificationDetails(
        'chat_messages', // channel id
        'Mensajes de Chat', // channel name
        channelDescription: 'Notificaciones de nuevos mensajes en el chat',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      // Configuración de iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Usar roomId como ID único para agrupar notificaciones del mismo chat
      final notificationId = roomId.hashCode;

      await _notifications.show(
        notificationId,
        senderName,
        text.length > 50 ? '${text.substring(0, 50)}...' : text,
        notificationDetails,
        payload: roomId, // Enviar roomId como payload para navegación
      );

      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] 📲 Notificación mostrada: $senderName - $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_NOTIFICATIONS] ❌ Error al mostrar notificación: $e');
      }
    }
  }

  /// Limpiar y desuscribirse
  void dispose() {
    _messagesChannel?.unsubscribe();
    _checkTimer?.cancel();
    if (!_unreadCountController.isClosed) {
      _unreadCountController.close();
    }
    _isInitialized = false;
    _currentUserId = null;
  }

  /// Reinicializar cuando el usuario cambia
  Future<void> reinit() async {
    _messagesChannel?.unsubscribe();
    _checkTimer?.cancel();
    // Cerrar controller si no está cerrado y crear uno nuevo
    if (!_unreadCountController.isClosed) {
      _unreadCountController.close();
    }
    _unreadCountController = StreamController<int>.broadcast();
    _isInitialized = false;
    _currentUserId = null;
    await init();
  }

  bool get mounted => _currentUserId != null;
}

/// Singleton instance
final chatNotificationService = ChatNotificationService();

