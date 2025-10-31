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
      final nutriResponse = await supabase
          .from('nutricionistas')
          .select()
          .eq('auth_uid', authUid);

      if (nutriResponse == null || nutriResponse.isEmpty) {
        throw AppAuthException('Usuario no encontrado en la base de datos');
      }

      final nutriData = nutriResponse.first as Map<String, dynamic>;

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
      // Primero, intentar autenticar con Supabase Auth usando el formato de email
      // Esto es más eficiente y evita problemas con RLS al buscar por DNI
      final email = 'paciente$dni@app.com';
      
      AuthResponse? authResponse;
      try {
        authResponse = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // Si falla la autenticación con Supabase Auth
        if (kDebugMode) {
          print('Error de autenticación Auth: $e');
        }
        
        // Verificar si es un error de credenciales o usuario no encontrado
        if (e is AuthException) {
          if (e.message.toLowerCase().contains('email not confirmed') ||
              e.message.toLowerCase().contains('email not verified')) {
            throw AppAuthException(
              'El email no está confirmado. Contacta a tu nutricionista para activar tu cuenta.',
            );
          } else if (e.message.toLowerCase().contains('invalid') ||
              e.message.toLowerCase().contains('incorrect')) {
            throw AppAuthException('Credenciales inválidas');
          } else if (e.message.toLowerCase().contains('not found') ||
                     e.message.toLowerCase().contains('does not exist')) {
            throw AppAuthException('Paciente no encontrado');
          }
        }
        throw AppAuthException('Credenciales inválidas');
      }

      if (authResponse.user == null) {
        throw AppAuthException('Usuario no encontrado');
      }

      final authUid = authResponse.user!.id;

      // Buscar el paciente en la tabla por auth_uid
      final pacienteResponse = await supabase
          .from('pacientes')
          .select()
          .eq('auth_uid', authUid);

      // Si no existe en la tabla, crear un registro básico automáticamente
      if (pacienteResponse == null || pacienteResponse.isEmpty) {
        if (kDebugMode) {
          print('📝 Paciente autenticado pero no existe en tabla. Creando registro básico...');
        }
        
        // Extraer DNI del email o de los metadatos
        final userMetadata = authResponse.user!.userMetadata;
        final pacienteDni = userMetadata['dni'] as String? ?? dni;
        
        // Crear registro básico en la tabla pacientes
        // Nota: nutricionista_id puede ser NULL inicialmente
        // El nutricionista puede asignarlo después
        final pacienteDataToInsert = {
          'auth_uid': authUid,
          'dni': pacienteDni,
          'nombre': '', // Se completará después
          'apellidos': '', // Se completará después
          'activo': true,
        };
        
        try {
          final insertResponse = await supabase
              .from('pacientes')
              .insert(pacienteDataToInsert)
              .select();
          
          if (insertResponse == null || insertResponse.isEmpty) {
            throw AppAuthException('Error al crear el registro del paciente');
          }
          
          final nuevoPaciente = insertResponse.first as Map<String, dynamic>;
          
          if (kDebugMode) {
            print('✅ Registro de paciente creado exitosamente');
          }
          
          return PacienteModel.fromSupabaseRow(nuevoPaciente);
        } on PostgrestException catch (e) {
          if (kDebugMode) {
            print('❌ Error al crear registro de paciente: ${e.message}');
          }
          
          // Si falla por RLS o otro error, permitir login con datos básicos
          // pero informar que necesita completar su perfil
          return PacienteModel(
            id: '',
            authUid: authUid,
            nutricionistaId: null,
            nombre: '',
            apellidos: '',
            dni: pacienteDni,
            sexo: null,
            edad: null,
            peso: null,
            talla: null,
            imc: null,
            medidasAntropometricas: null,
            historialMedico: null,
            observaciones: null,
            activo: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }

      final pacienteData = pacienteResponse.first as Map<String, dynamic>;

      // Verificar si está activo
      if (pacienteData['activo'] == false) {
        throw AppAuthException('Cuenta desactivada');
      }

      return PacienteModel.fromSupabaseRow(pacienteData);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      
      // Verificar si es un error de "no encontrado"
      if (e.code == 'PGRST116' || 
          e.message.contains('No rows') ||
          e.message.contains('Could not find')) {
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
        print('Error inesperado en login paciente: $e');
      }
      
      // Manejar errores de Supabase Auth y otros
      String errorMessage = 'Error al iniciar sesión';
      String errorString = e.toString().toLowerCase();
      
      if (errorString.contains('invalid login credentials') ||
          errorString.contains('invalid credentials') ||
          errorString.contains('incorrect')) {
        errorMessage = 'Credenciales inválidas';
      } else if (errorString.contains('user not found') ||
                 errorString.contains('does not exist')) {
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

      final nutriResponse = await supabase
          .from('nutricionistas')
          .select()
          .eq('auth_uid', user.id);

      if (nutriResponse == null || nutriResponse.isEmpty) {
        return null;
      }

      final nutriData = nutriResponse.first as Map<String, dynamic>;
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

