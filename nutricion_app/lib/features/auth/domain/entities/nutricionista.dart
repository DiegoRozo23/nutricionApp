/// Entidad de Nutricionista - Representa un nutricionista en el dominio
/// Esta es una clase pura de Dart, sin dependencias de Flutter
class Nutricionista {
  final String id;
  final String authUid; // UUID de auth.users(id)
  final String nombre;
  final String apellidos;
  final String? dni;
  final String? especialidad;
  final String privilegio;
  final String? username;
  final String? email;
  final String? telefono;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Nutricionista({
    required this.id,
    required this.authUid,
    required this.nombre,
    required this.apellidos,
    this.dni,
    this.especialidad,
    this.privilegio = 'nutricionista',
    this.username,
    this.email,
    this.telefono,
    this.activo = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nombre completo del nutricionista
  String get nombreCompleto => '$nombre $apellidos';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Nutricionista &&
        other.id == id &&
        other.authUid == authUid &&
        other.nombre == nombre &&
        other.apellidos == apellidos &&
        other.dni == dni &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        authUid.hashCode ^
        nombre.hashCode ^
        apellidos.hashCode;
  }

  @override
  String toString() {
    return 'Nutricionista(id: $id, nombreCompleto: $nombreCompleto, email: $email)';
  }
}

