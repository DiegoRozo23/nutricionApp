import '../repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión
/// 
/// Este es un caso de uso puro que no depende de detalles de implementación.
/// Solo conoce el repository interface y las entidades del dominio.
class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  /// Ejecutar login según el rol del usuario
  /// 
  /// [role] puede ser 'nutricionista' o 'paciente'
  /// [credential] es username/email para nutricionista o DNI para paciente
  /// [password] es la contraseña
  Future<AuthResult> call({
    required String role,
    required String credential,
    required String password,
  }) async {
    // Validaciones básicas
    if (credential.isEmpty) {
      return AuthFailure(
        message: 'Credenciales inválidas',
        code: 'empty_credential',
      );
    }

    if (password.isEmpty) {
      return AuthFailure(
        message: 'La contraseña no puede estar vacía',
        code: 'empty_password',
      );
    }

    if (password.length < 4) {
      return AuthFailure(
        message: 'La contraseña debe tener al menos 4 caracteres',
        code: 'invalid_password_length',
      );
    }

    // Llamar al repositorio según el rol
    if (role == 'nutricionista') {
      return await repository.loginNutricionista(
        credential: credential,
        password: password,
      );
    } else if (role == 'paciente') {
      return await repository.loginPaciente(
        dni: credential,
        password: password,
      );
    }

    return AuthFailure(
      message: 'Rol no válido',
      code: 'invalid_role',
    );
  }
}

