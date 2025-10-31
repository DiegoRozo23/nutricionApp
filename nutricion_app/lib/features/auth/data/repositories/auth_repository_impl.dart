import 'package:flutter/foundation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/nutricionista.dart';
import '../../domain/entities/paciente.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../shared/services/supabase_service.dart';

// Importar la excepción renombrada
import '../datasources/auth_remote_datasource.dart' as auth_data;

/// Implementación del repositorio de autenticación
/// 
/// Esta clase coordina las llamadas entre el dominio y las fuentes de datos
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    AuthRemoteDataSource? remoteDataSource,
  }) : remoteDataSource = remoteDataSource ?? 
      AuthRemoteDataSourceImpl(supabaseService.client);

  @override
  Future<AuthResult> loginNutricionista({
    required String credential,
    required String password,
  }) async {
    try {
      final nutricionista = await remoteDataSource.loginNutricionista(
        credential: credential,
        password: password,
      );

      return AuthSuccess(
        nutricionista: nutricionista,
        token: nutricionista.id,
      );
    } on auth_data.AppAuthException catch (e) {
      if (kDebugMode) {
        print('Error de autenticación: ${e.message}');
      }
      return AuthFailure(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      return AuthFailure(
        message: 'Error al iniciar sesión',
      );
    }
  }

  @override
  Future<AuthResult> loginPaciente({
    required String dni,
    required String password,
  }) async {
    try {
      final paciente = await remoteDataSource.loginPaciente(
        dni: dni,
        password: password,
      );

      return AuthSuccess(
        paciente: paciente,
        token: paciente.id,
      );
    } on auth_data.AppAuthException catch (e) {
      if (kDebugMode) {
        print('Error de autenticación: ${e.message}');
      }
      return AuthFailure(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      return AuthFailure(
        message: 'Error al iniciar sesión',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } on auth_data.AppAuthException catch (e) {
      if (kDebugMode) {
        print('Error al cerrar sesión: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Future<AuthResult> checkSession() async {
    try {
      final hasSession = remoteDataSource.hasActiveSession();
      
      if (!hasSession) {
        return AuthFailure(
          message: 'No hay sesión activa',
        );
      }

      // Intentar obtener nutricionista primero
      final nutricionista = await remoteDataSource.getCurrentNutricionista();
      if (nutricionista != null) {
        return AuthSuccess(
          nutricionista: nutricionista,
          token: nutricionista.id,
        );
      }

      // Si no hay nutricionista, intentar obtener paciente
      final paciente = await remoteDataSource.getCurrentPaciente();
      if (paciente != null) {
        return AuthSuccess(
          paciente: paciente,
          token: paciente.id,
        );
      }

      return AuthFailure(
        message: 'No se pudo obtener la información del usuario',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error al verificar sesión: $e');
      }
      return AuthFailure(
        message: 'Error al verificar sesión',
      );
    }
  }

  @override
  Future<Nutricionista?> getCurrentNutricionista() async {
    try {
      final model = await remoteDataSource.getCurrentNutricionista();
      return model?.toEntity();
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener nutricionista: $e');
      }
      return null;
    }
  }

  @override
  Future<Paciente?> getCurrentPaciente() async {
    try {
      final model = await remoteDataSource.getCurrentPaciente();
      return model?.toEntity();
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener paciente: $e');
      }
      return null;
    }
  }
}

