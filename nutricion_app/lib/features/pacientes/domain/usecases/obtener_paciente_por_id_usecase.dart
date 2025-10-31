import '../repositories/pacientes_repository.dart';
import '../entities/paciente.dart';

/// Caso de uso para obtener un paciente por ID
class ObtenerPacientePorIdUseCase {
  final PacientesRepository repository;

  const ObtenerPacientePorIdUseCase(this.repository);

  /// Ejecutar obtención de paciente por ID
  Future<PacientesResult<Paciente>> call(String id) async {
    if (id.isEmpty) {
      return PacientesFailure(
        message: 'El ID del paciente es requerido',
        code: 'empty_id',
      );
    }

    return await repository.obtenerPacientePorId(id);
  }
}

