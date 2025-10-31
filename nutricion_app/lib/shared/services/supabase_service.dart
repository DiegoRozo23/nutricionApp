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
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ No se encontró archivo .env');
          print('📝 Copia env.example a .env y configura tus credenciales');
        }
        return;
      }
      
      final String url = dotenv.env['SUPABASE_URL'] ?? '';
      final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      if (url.isEmpty || anonKey.isEmpty) {
        if (kDebugMode) {
          print('⚠️ AVISO: SUPABASE_URL o SUPABASE_ANON_KEY no están configurados en .env');
          print('📝 Edita el archivo .env con tus credenciales de Supabase');
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

