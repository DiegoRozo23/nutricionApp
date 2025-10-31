import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nutricionista_model.dart';
import '../models/paciente_model.dart';

/// Excepción personalizada para errores de autenticación
/// Renombrada para evitar conflicto con AuthException de Supabase
class AppAuthException implements Exception {
  final String message;
  final String? code;

  AppAuthException(this.message, {this.code});

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
        throw AppAuthException('Usuario no encontrado');
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
        throw AppAuthException('Cuenta desactivada');
      }

      return NutricionistaModel.fromSupabaseRow(nutriData);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      
      // Verificar si es un error de "no encontrado"
      if (e.code == 'PGRST116' || e.message.contains('No rows')) {
        throw AppAuthException('Usuario no encontrado en la base de datos');
      }
      
      throw AppAuthException(
        'Error al buscar nutricionista: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      
      // Manejar errores de Supabase Auth y otros
      String errorMessage = 'Error al iniciar sesión';
      String errorString = e.toString().toLowerCase();
      
      if (errorString.contains('invalid login credentials') ||
          errorString.contains('invalid credentials') ||
          errorString.contains('incorrect')) {
        errorMessage = 'Credenciales inválidas';
      } else if (errorString.contains('email not confirmed') ||
                 errorString.contains('email not verified')) {
        errorMessage = 'Email no confirmado';
      } else if (errorString.contains('user not found')) {
        errorMessage = 'Usuario no encontrado';
      } else if (errorString.contains('connection') ||
                 errorString.contains('network') ||
                 errorString.contains('timeout')) {
        errorMessage = 'Error de conexión. Verifica tu internet';
      } else if (e is AuthException) {
        // Si es AuthException de Supabase, usar su mensaje
        errorMessage = e.message;
      }
      
      throw AppAuthException(errorMessage);
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
        throw AppAuthException('Cuenta desactivada');
      }

      // Si el paciente tiene auth_uid, autenticamos con Supabase Auth
      final authUid = pacienteData['auth_uid'];
      if (authUid != null) {
        try {
          // Usamos el formato de email: dni@nutricionapp.local
          final email = '$dni@nutricionapp.local';
          await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } catch (e) {
          // Si falla la autenticación
          if (kDebugMode) {
            print('Error de autenticación: $e');
          }
          throw AppAuthException('Credenciales inválidas');
        }
      } else {
        throw AppAuthException('El paciente no tiene cuenta de usuario activa');
      }

      return PacienteModel.fromSupabaseRow(pacienteData);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      
      // Verificar si es un error de "no encontrado"
      if (e.code == 'PGRST116' || e.message.contains('No rows')) {
        throw AppAuthException('Paciente no encontrado');
      }
      
      throw AppAuthException(
        'Error al buscar paciente: ${e.message}',
        code: e.code,
      );
    } on AppAuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      
      // Manejar errores de Supabase Auth y otros
      String errorMessage = 'Error al iniciar sesión';
      String errorString = e.toString().toLowerCase();
      
      if (errorString.contains('invalid login credentials') ||
          errorString.contains('invalid credentials') ||
          errorString.contains('incorrect')) {
        errorMessage = 'Credenciales inválidas';
      } else if (errorString.contains('user not found')) {
        errorMessage = 'Paciente no encontrado';
      } else if (errorString.contains('connection') ||
                 errorString.contains('network') ||
                 errorString.contains('timeout')) {
        errorMessage = 'Error de conexión. Verifica tu internet';
      } else if (e is AuthException) {
        errorMessage = e.message;
      }
      
      throw AppAuthException(errorMessage);
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
      throw AppAuthException('Error al cerrar sesión');
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

