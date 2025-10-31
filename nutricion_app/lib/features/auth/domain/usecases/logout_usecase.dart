import '../repositories/auth_repository.dart';

/// Caso de uso para cerrar sesión
/// 
/// Este es un caso de uso puro que no depende de detalles de implementación.
class LogoutUseCase {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  /// Ejecutar logout
  Future<void> call() async {
    await repository.logout();
  }
}

