import '../repositories/pacientes_repository.dart';
import '../entities/paciente.dart';

/// Caso de uso para actualizar un paciente
class ActualizarPacienteUseCase {
  final PacientesRepository repository;

  const ActualizarPacienteUseCase(this.repository);

  /// Ejecutar actualización de paciente
  Future<PacientesResult<Paciente>> call(Paciente paciente) async {
    // Validaciones básicas
    if (paciente.nombre.isEmpty) {
      return PacientesFailure(
        message: 'El nombre es obligatorio',
        code: 'empty_name',
      );
    }

    if (paciente.apellidos.isEmpty) {
      return PacientesFailure(
        message: 'Los apellidos son obligatorios',
        code: 'empty_lastname',
      );
    }

    return await repository.actualizarPaciente(paciente);
  }
}

