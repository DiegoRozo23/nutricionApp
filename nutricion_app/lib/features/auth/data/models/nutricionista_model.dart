import '../../domain/entities/nutricionista.dart';

/// Modelo de Nutricionista para la capa de datos
/// Extiende de la entidad Nutricionista y agrega métodos de serialización
class NutricionistaModel extends Nutricionista {
  const NutricionistaModel({
    required super.id,
    required super.authUid,
    required super.nombre,
    required super.apellidos,
    super.dni,
    super.especialidad,
    super.privilegio,
    super.username,
    super.email,
    super.telefono,
    super.activo,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Crear un NutricionistaModel desde un JSON
  factory NutricionistaModel.fromJson(Map<String, dynamic> json) {
    return NutricionistaModel(
      id: json['id'] as String,
      authUid: json['auth_uid'] as String,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      dni: json['dni'] as String?,
      especialidad: json['especialidad'] as String?,
      privilegio: json['privilegio'] as String? ?? 'nutricionista',
      username: json['username'] as String?,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Crear un NutricionistaModel desde Supabase Row
  factory NutricionistaModel.fromSupabaseRow(Map<String, dynamic> row) {
    return NutricionistaModel.fromJson(row);
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_uid': authUid,
      'nombre': nombre,
      'apellidos': apellidos,
      'dni': dni,
      'especialidad': especialidad,
      'privilegio': privilegio,
      'username': username,
      'email': email,
      'telefono': telefono,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convertir a entidad de dominio
  Nutricionista toEntity() {
    return Nutricionista(
      id: id,
      authUid: authUid,
      nombre: nombre,
      apellidos: apellidos,
      dni: dni,
      especialidad: especialidad,
      privilegio: privilegio,
      username: username,
      email: email,
      telefono: telefono,
      activo: activo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Crear una copia con algunos campos modificados
  NutricionistaModel copyWith({
    String? id,
    String? authUid,
    String? nombre,
    String? apellidos,
    String? dni,
    String? especialidad,
    String? privilegio,
    String? username,
    String? email,
    String? telefono,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NutricionistaModel(
      id: id ?? this.id,
      authUid: authUid ?? this.authUid,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      dni: dni ?? this.dni,
      especialidad: especialidad ?? this.especialidad,
      privilegio: privilegio ?? this.privilegio,
      username: username ?? this.username,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

