import '../entities/paciente.dart';

/// Resultado de una operación de pacientes
sealed class PacientesResult<T> {}

/// Resultado exitoso
class PacientesSuccess<T> extends PacientesResult<T> {
  final T data;

  PacientesSuccess(this.data);
}

/// Resultado de error
class PacientesFailure extends PacientesResult<Never> {
  final String message;
  final String? code;

  PacientesFailure({
    required this.message,
    this.code,
  });
}

/// Interfaz del repositorio de pacientes
/// Define los contratos que debe cumplir cualquier implementación
abstract class PacientesRepository {
  /// Obtener todos los pacientes del nutricionista actual
  Future<PacientesResult<List<Paciente>>> obtenerPacientes();

  /// Obtener un paciente por ID
  Future<PacientesResult<Paciente>> obtenerPacientePorId(String id);

  /// Crear un nuevo paciente
  Future<PacientesResult<Paciente>> crearPaciente(Paciente paciente);

  /// Actualizar un paciente existente
  Future<PacientesResult<Paciente>> actualizarPaciente(Paciente paciente);

  /// Eliminar un paciente
  Future<PacientesResult<void>> eliminarPaciente(String id);
}

