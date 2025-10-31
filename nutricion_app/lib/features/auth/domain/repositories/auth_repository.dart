import '../entities/nutricionista.dart';
import '../entities/paciente.dart';

/// Resultado de una operación de autenticación
sealed class AuthResult {}

/// Resultado exitoso de autenticación
class AuthSuccess extends AuthResult {
  final Nutricionista? nutricionista;
  final Paciente? paciente;
  final String token;

  AuthSuccess({
    this.nutricionista,
    this.paciente,
    required this.token,
  });

  /// Verificar si es nutricionista
  bool get isNutricionista => nutricionista != null;

  /// Verificar si es paciente
  bool get isPaciente => paciente != null;
}

/// Resultado de error de autenticación
class AuthFailure extends AuthResult {
  final String message;
  final String? code;

  AuthFailure({
    required this.message,
    this.code,
  });
}

/// Interfaz del repositorio de autenticación
/// Define los contratos que debe cumplir cualquier implementación
abstract class AuthRepository {
  /// Iniciar sesión como nutricionista (por username/email y contraseña)
  Future<AuthResult> loginNutricionista({
    required String credential, // Username o email
    required String password,
  });

  /// Iniciar sesión como paciente (por DNI y contraseña)
  Future<AuthResult> loginPaciente({
    required String dni,
    required String password,
  });

  /// Cerrar sesión
  Future<void> logout();

  /// Verificar si hay una sesión activa
  Future<AuthResult> checkSession();

  /// Obtener el nutricionista actual autenticado
  Future<Nutricionista?> getCurrentNutricionista();

  /// Obtener el paciente actual autenticado
  Future<Paciente?> getCurrentPaciente();
}

