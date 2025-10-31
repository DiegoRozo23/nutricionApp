import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nutricionista_model.dart';
import '../models/paciente_model.dart';

/// Excepción personalizada para errores de autenticación
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Datasource remoto para autenticación
/// 
/// Este datasource maneja toda la comunicación con Supabase
/// para operaciones de autenticación
abstract class AuthRemoteDataSource {
  /// Login como nutricionista usando Supabase Auth
  Future<NutricionistaModel> loginNutricionista({
    required String credential,
    required String password,
  });

  /// Login como paciente usando Supabase Auth
  Future<PacienteModel> loginPaciente({
    required String dni,
    required String password,
  });

  /// Logout del usuario actual
  Future<void> logout();

  /// Obtener el nutricionista actual autenticado
  Future<NutricionistaModel?> getCurrentNutricionista();

  /// Obtener el paciente actual autenticado
  Future<PacienteModel?> getCurrentPaciente();

  /// Verificar si hay sesión activa
  bool hasActiveSession();
}

/// Implementación del datasource remoto
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabase;

  AuthRemoteDataSourceImpl(this.supabase);

  @override
  Future<NutricionistaModel> loginNutricionista({
    required String credential,
    required String password,
  }) async {
    try {
      // Primero, autenticar con Supabase Auth usando email/username
      final response = await supabase.auth.signInWithPassword(
        email: credential, // Supabase espera email
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Usuario no encontrado');
      }

      final authUid = response.user!.id;

      // Buscar el nutricionista en la tabla por auth_uid
      final nutriData = await supabase
          .from('nutricionistas')
          .select()
          .eq('auth_uid', authUid)
          .single();

      // Verificar si está activo
      if (nutriData['activo'] == false) {
        throw AuthException('Cuenta desactivada');
      }

      return NutricionistaModel.fromSupabaseRow(nutriData);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      throw AuthException(
        'Error al autenticar',
        code: e.code,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      throw AuthException(
        'Error al iniciar sesión: ${e.toString()}',
      );
    }
  }

  @override
  Future<PacienteModel> loginPaciente({
    required String dni,
    required String password,
  }) async {
    try {
      // Para pacientes, necesitamos buscar primero por DNI
      final pacienteData = await supabase
          .from('pacientes')
          .select()
          .eq('dni', dni)
          .single();

      // Verificar si está activo
      if (pacienteData['activo'] == false) {
        throw AuthException('Cuenta desactivada');
      }

      // Si el paciente tiene auth_uid, autenticamos con Supabase Auth
      final authUid = pacienteData['auth_uid'];
      if (authUid != null) {
        try {
          await supabase.auth.signInWithPassword(
            email: authUid, // Usamos el UUID como email
            password: password,
          );
        } catch (e) {
          // Si falla la autenticación, podríamos usar credenciales locales
          // Por ahora, rechazamos
          throw AuthException('Credenciales inválidas');
        }
      }

      return PacienteModel.fromSupabaseRow(pacienteData);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      throw AuthException(
        'Error al autenticar',
        code: e.code,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      throw AuthException(
        'Error al iniciar sesión: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error al cerrar sesión: $e');
      }
      throw AuthException('Error al cerrar sesión');
    }
  }

  @override
  Future<NutricionistaModel?> getCurrentNutricionista() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final nutriData = await supabase
          .from('nutricionistas')
          .select()
          .eq('auth_uid', user.id)
          .single();

      return NutricionistaModel.fromSupabaseRow(nutriData);
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener nutricionista: $e');
      }
      return null;
    }
  }

  @override
  Future<PacienteModel?> getCurrentPaciente() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final pacienteData = await supabase
          .from('pacientes')
          .select()
          .eq('auth_uid', user.id)
          .maybeSingle();

      if (pacienteData == null) return null;

      return PacienteModel.fromSupabaseRow(pacienteData);
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener paciente: $e');
      }
      return null;
    }
  }

  @override
  bool hasActiveSession() {
    return supabase.auth.currentUser != null;
  }
}

