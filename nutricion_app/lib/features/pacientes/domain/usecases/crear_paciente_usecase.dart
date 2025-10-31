import '../repositories/pacientes_repository.dart';
import '../entities/paciente.dart';

/// Caso de uso para crear un paciente
class CrearPacienteUseCase {
  final PacientesRepository repository;

  const CrearPacienteUseCase(this.repository);

  /// Ejecutar creación de paciente
  Future<PacientesResult<Paciente>> call({
    required String nombre,
    required String apellidos,
    String? dni,
    String? sexo,
    int? edad,
    double? peso,
    double? talla,
    double? imc,
    Map<String, dynamic>? medidasAntropometricas,
    String? historialMedico,
    String? observaciones,
  }) async {
    // Validaciones básicas
    if (nombre.isEmpty) {
      return PacientesFailure(
        message: 'El nombre es obligatorio',
        code: 'empty_name',
      );
    }

    if (apellidos.isEmpty) {
      return PacientesFailure(
        message: 'Los apellidos son obligatorios',
        code: 'empty_lastname',
      );
    }

    // Crear objeto paciente (el ID y fechas se generan en el datasource)
    final paciente = Paciente(
      id: '', // Se generará en el datasource
      nombre: nombre,
      apellidos: apellidos,
      dni: dni,
      sexo: sexo,
      edad: edad,
      peso: peso,
      talla: talla,
      imc: imc,
      medidasAntropometricas: medidasAntropometricas,
      historialMedico: historialMedico,
      observaciones: observaciones,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await repository.crearPaciente(paciente);
  }
}

