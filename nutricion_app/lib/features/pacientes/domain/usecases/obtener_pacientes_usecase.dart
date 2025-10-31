import '../repositories/pacientes_repository.dart';
import '../entities/paciente.dart';

/// Caso de uso para obtener todos los pacientes del nutricionista
class ObtenerPacientesUseCase {
  final PacientesRepository repository;

  const ObtenerPacientesUseCase(this.repository);

  /// Ejecutar obtención de pacientes
  Future<PacientesResult<List<Paciente>>> call() async {
    return await repository.obtenerPacientes();
  }
}

