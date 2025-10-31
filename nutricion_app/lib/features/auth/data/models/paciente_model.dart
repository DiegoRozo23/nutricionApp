import 'dart:convert';
import '../../domain/entities/paciente.dart';

/// Modelo de Paciente para la capa de datos
/// Extiende de la entidad Paciente y agrega métodos de serialización
class PacienteModel extends Paciente {
  const PacienteModel({
    required super.id,
    super.authUid,
    super.nutricionistaId,
    required super.nombre,
    required super.apellidos,
    super.dni,
    super.sexo,
    super.edad,
    super.peso,
    super.talla,
    super.imc,
    super.medidasAntropometricas,
    super.historialMedico,
    super.observaciones,
    super.activo,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Crear un PacienteModel desde un JSON
  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    return PacienteModel(
      id: json['id'] as String,
      authUid: json['auth_uid'] as String?,
      nutricionistaId: json['nutricionista_id'] as String?,
      nombre: json['nombre'] as String,
      apellidos: json['apellidos'] as String,
      dni: json['dni'] as String?,
      sexo: json['sexo'] as String?,
      edad: json['edad'] as int?,
      peso: json['peso'] != null ? (json['peso'] as num).toDouble() : null,
      talla: json['talla'] != null ? (json['talla'] as num).toDouble() : null,
      imc: json['imc'] != null ? (json['imc'] as num).toDouble() : null,
      medidasAntropometricas: _parseMedidasAntropometricas(json['medidas_antropometricas']),
      historialMedico: json['historial_medico'] as String?,
      observaciones: json['observaciones'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Crear un PacienteModel desde Supabase Row
  factory PacienteModel.fromSupabaseRow(Map<String, dynamic> row) {
    return PacienteModel.fromJson(row);
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_uid': authUid,
      'nutricionista_id': nutricionistaId,
      'nombre': nombre,
      'apellidos': apellidos,
      'dni': dni,
      'sexo': sexo,
      'edad': edad,
      'peso': peso,
      'talla': talla,
      'imc': imc,
      'medidas_antropometricas': medidasAntropometricas,
      'historial_medico': historialMedico,
      'observaciones': observaciones,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convertir a entidad de dominio
  Paciente toEntity() {
    return Paciente(
      id: id,
      authUid: authUid,
      nutricionistaId: nutricionistaId,
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
      activo: activo,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Crear una copia con algunos campos modificados
  PacienteModel copyWith({
    String? id,
    String? authUid,
    String? nutricionistaId,
    String? nombre,
    String? apellidos,
    String? dni,
    String? sexo,
    int? edad,
    double? peso,
    double? talla,
    double? imc,
    Map<String, dynamic>? medidasAntropometricas,
    String? historialMedico,
    String? observaciones,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PacienteModel(
      id: id ?? this.id,
      authUid: authUid ?? this.authUid,
      nutricionistaId: nutricionistaId ?? this.nutricionistaId,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      dni: dni ?? this.dni,
      sexo: sexo ?? this.sexo,
      edad: edad ?? this.edad,
      peso: peso ?? this.peso,
      talla: talla ?? this.talla,
      imc: imc ?? this.imc,
      medidasAntropometricas: medidasAntropometricas ?? this.medidasAntropometricas,
      historialMedico: historialMedico ?? this.historialMedico,
      observaciones: observaciones ?? this.observaciones,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parsear medidas antropométricas desde JSONB (puede venir como String o Map)
  static Map<String, dynamic>? _parseMedidasAntropometricas(dynamic data) {
    if (data == null) return null;
    
    if (data is Map<String, dynamic>) {
      return data;
    }
    
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (e) {
        // Si falla el parseo, retornar null
        return null;
      }
    }
    
    return null;
  }
}

