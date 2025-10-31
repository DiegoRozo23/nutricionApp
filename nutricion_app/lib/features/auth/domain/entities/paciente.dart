/// Entidad de Paciente - Representa un paciente en el dominio
/// Esta es una clase pura de Dart, sin dependencias de Flutter
class Paciente {
  final String id;
  final String? authUid; // UUID de auth.users(id) si tiene cuenta
  final String? nutricionistaId; // ID del nutricionista asignado
  final String nombre;
  final String apellidos;
  final String? dni;
  final String? sexo; // M, F, Otro
  final int? edad;
  final double? peso;
  final double? talla;
  final double? imc;
  final Map<String, dynamic>? medidasAntropometricas;
  final String? historialMedico;
  final String? observaciones;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Paciente({
    required this.id,
    this.authUid,
    this.nutricionistaId,
    required this.nombre,
    required this.apellidos,
    this.dni,
    this.sexo,
    this.edad,
    this.peso,
    this.talla,
    this.imc,
    this.medidasAntropometricas,
    this.historialMedico,
    this.observaciones,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nombre completo del paciente
  String get nombreCompleto => '$nombre $apellidos';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Paciente &&
        other.id == id &&
        other.nombre == nombre &&
        other.apellidos == apellidos &&
        other.dni == dni;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nombre.hashCode ^
        apellidos.hashCode ^
        dni.hashCode;
  }

  @override
  String toString() {
    return 'Paciente(id: $id, nombreCompleto: $nombreCompleto, dni: $dni)';
  }
}

