import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio principal para interactuar con Supabase
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() => _instance;
  
  SupabaseService._internal();
  
  bool _initialized = false;
  
  /// Inicializar Supabase con credenciales del archivo .env
  Future<void> init() async {
    if (_initialized) {
      if (kDebugMode) {
        print('Supabase ya está inicializado');
      }
      return;
    }
    
    try {
      // Cargar variables de entorno
      String url = '';
      String anonKey = '';
      
      try {
        // Intentar cargar .env desde el root del proyecto
        await dotenv.load(fileName: ".env");
        url = dotenv.env['SUPABASE_URL'] ?? '';
        anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      } catch (e) {
        // Si falla, intentar desde assets (build de release)
        try {
          await dotenv.load(fileName: "assets/.env");
          url = dotenv.env['SUPABASE_URL'] ?? '';
          anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
        } catch (e2) {
          // Si también falla, intentar sin "assets/" (algunos builds)
          try {
            await dotenv.load();
            url = dotenv.env['SUPABASE_URL'] ?? '';
            anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
          } catch (e3) {
            final errorMsg = 'No se pudo cargar archivo .env. Errores: $e, $e2, $e3';
            if (kDebugMode) {
              print('⚠️ $errorMsg');
              print('📝 Asegúrate de que el archivo .env existe y está en pubspec.yaml');
            } else {
              // En release, lanzar excepción para que el usuario sepa qué pasó
              throw Exception('Error de configuración: $errorMsg');
            }
            return;
          }
        }
      }
      
      if (url.isEmpty || anonKey.isEmpty) {
        final errorMsg = '⚠️ AVISO: SUPABASE_URL o SUPABASE_ANON_KEY no están configurados';
        if (kDebugMode) {
          print(errorMsg);
          print('📝 Edita el archivo .env con tus credenciales de Supabase');
        } else {
          throw Exception('$errorMsg. Verifica la configuración.');
        }
        return;
      }
      
      // Inicializar Supabase
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );
      
      _initialized = true;
      
      if (kDebugMode) {
        print('✅ Supabase inicializado correctamente');
        print('📍 URL: $url');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al inicializar Supabase: $e');
        print('⚠️ La app funcionará en modo desconectado');
      }
      _initialized = false;
    }
  }
  
  /// Obtener cliente de Supabase
  SupabaseClient get client {
    if (!_initialized) {
      throw Exception('Supabase no está inicializado. Llama a init() primero.');
    }
    return Supabase.instance.client;
  }
  
  /// Verificar si está conectado
  bool get isConnected => _initialized;
  
  /// Verificar si está autenticado
  bool get isAuthenticated {
    if (!_initialized) return false;
    return Supabase.instance.client.auth.currentUser != null;
  }
  
  /// Obtener usuario actual
  User? get currentUser {
    if (!_initialized) return null;
    return Supabase.instance.client.auth.currentUser;
  }
  
  /// Cerrar sesión
  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await Supabase.instance.client.auth.signOut();
      if (kDebugMode) {
        print('✅ Sesión cerrada correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cerrar sesión: $e');
      }
    }
  }
  
  /// Desconectar servicio
  Future<void> disconnect() async {
    if (kDebugMode) {
      print('Supabase desconectado');
    }
    _initialized = false;
  }
}

/// Singleton instance
final supabaseService = SupabaseService();

