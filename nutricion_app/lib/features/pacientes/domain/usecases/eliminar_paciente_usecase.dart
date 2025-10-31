import '../repositories/pacientes_repository.dart';

/// Caso de uso para eliminar un paciente
class EliminarPacienteUseCase {
  final PacientesRepository repository;

  const EliminarPacienteUseCase(this.repository);

  /// Ejecutar eliminación de paciente
  Future<PacientesResult<void>> call(String id) async {
    if (id.isEmpty) {
      return PacientesFailure(
        message: 'El ID del paciente es requerido',
        code: 'empty_id',
      );
    }

    return await repository.eliminarPaciente(id);
  }
}

