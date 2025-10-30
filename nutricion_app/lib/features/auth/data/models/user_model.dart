import '../../domain/entities/user.dart';

/// Modelo de Usuario para la capa de datos
/// Extiende de la entidad User y agrega métodos de serialización
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.dni,
    required super.name,
    required super.email,
    required super.role,
    required super.createdAt,
  });
  
  /// Crear un UserModel desde un JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      dni: json['dni'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dni': dni,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  /// Crear una copia con algunos campos modificados
  UserModel copyWith({
    String? id,
    String? dni,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      dni: dni ?? this.dni,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

