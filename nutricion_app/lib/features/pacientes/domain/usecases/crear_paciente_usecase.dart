import '../repositories/pacientes_repository.dart';
import '../entities/paciente.dart';

/// Caso de uso para crear un paciente
class CrearPacienteUseCase {
  final PacientesRepository repository;

  const CrearPacienteUseCase(this.repository);

  /// Ejecutar creación de paciente
  /// Solo crea la cuenta en Supabase Auth con DNI y contraseña
  /// El paciente completará su perfil después de iniciar sesión
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

    if (password.isEmpty) {
      return PacientesFailure(
        message: 'La contraseña inicial es obligatoria',
        code: 'empty_password',
      );
    }

    if (password.length < 4) {
      return PacientesFailure(
        message: 'La contraseña debe tener al menos 4 caracteres',
        code: 'weak_password',
      );
    }

    // Crear objeto paciente mínimo (solo DNI)
    // El resto se completará cuando el paciente inicie sesión
    final paciente = Paciente(
      id: '', // Se creará cuando complete su perfil
      nombre: nombre ?? '',
      apellidos: apellidos ?? '',
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

    return await repository.crearPaciente(paciente, password: password);
  }
}

