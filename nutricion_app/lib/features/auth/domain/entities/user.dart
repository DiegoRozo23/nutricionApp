/// Entidad de Usuario - Representa un usuario en el dominio
/// Esta es una clase pura de Dart, sin dependencias de Flutter
class User {
  final String id;
  final String dni;
  final String name;
  final String email;
  final String role; // 'nutricionista' o 'paciente'
  final DateTime createdAt;
  
  const User({
    required this.id,
    required this.dni,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });
  
  /// Verificar si el usuario es nutricionista
  bool get isNutricionista => role == 'nutricionista';
  
  /// Verificar si el usuario es paciente
  bool get isPaciente => role == 'paciente';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is User &&
        other.id == id &&
        other.dni == dni &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.createdAt == createdAt;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        dni.hashCode ^
        name.hashCode ^
        email.hashCode ^
        role.hashCode ^
        createdAt.hashCode;
  }
  
  @override
  String toString() {
    return 'User(id: $id, dni: $dni, name: $name, role: $role)';
  }
}

