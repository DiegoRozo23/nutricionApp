import '../repositories/pacientes_repository.dart';
import '../entities/paciente.dart';

/// Caso de uso para crear un paciente
class CrearPacienteUseCase {
  final PacientesRepository repository;

  const CrearPacienteUseCase(this.repository);

  /// Ejecutar creación de paciente
  /// Crea la cuenta en Supabase Auth y el registro en la base de datos
  Future<PacientesResult<Paciente>> call({
    required String dni,
    required String password,
    String? nombre,
    String? apellidos,
    String? sexo,
    int? edad,
    double? peso,
    double? talla,
    double? imc,
    Map<String, dynamic>? medidasAntropometricas,
    String? actividadFisica,
    String? historialMedico,
    String? observaciones,
  }) async {
    // Validaciones básicas
    if (dni.isEmpty) {
      return PacientesFailure(
        message: 'El DNI es obligatorio',
        code: 'empty_dni',
      );
    }

    if (dni.length < 8) {
      return PacientesFailure(
        message: 'El DNI debe tener al menos 8 caracteres',
        code: 'invalid_dni_length',
      );
    }

    if (password.isEmpty) {
      return PacientesFailure(
        message: 'La contraseña inicial es obligatoria',
        code: 'empty_password',
      );
    }

    if (password.length < 6) {
      return PacientesFailure(
        message: 'La contraseña debe tener al menos 6 caracteres',
        code: 'weak_password',
      );
    }

    // Crear objeto paciente
    final paciente = Paciente(
      id: '', // Se asignará al crear en la BD
      nombre: nombre ?? '',
      apellidos: apellidos ?? '',
      dni: dni,
      sexo: sexo,
      edad: edad,
      peso: peso,
      talla: talla,
      imc: imc,
      medidasAntropometricas: medidasAntropometricas,
      actividadFisica: actividadFisica,
      historialMedico: historialMedico,
      observaciones: observaciones,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await repository.crearPaciente(paciente, password: password);
  }
}

