import 'dart:convert';

/// Modelo para representar un plan nutricional de la tabla plantilla_planes
class PlanNutricional {
  final String id;
  final String nombre;
  final String codigo;
  final String descripcion;
  final String objetivoPrincipal;
  final Map<String, dynamic> gruposAlimentos;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanNutricional({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.descripcion,
    required this.objetivoPrincipal,
    required this.gruposAlimentos,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear desde un Map de Supabase
  factory PlanNutricional.fromSupabaseRow(Map<String, dynamic> row) {
    // Parsear grupos_alimentos que viene como JSON string
    Map<String, dynamic> gruposAlimentos = {};
    if (row['grupos_alimentos'] != null) {
      if (row['grupos_alimentos'] is String) {
        gruposAlimentos = Map<String, dynamic>.from(
          // ignore: avoid_dynamic_calls
          jsonDecode(row['grupos_alimentos'] as String),
        );
      } else if (row['grupos_alimentos'] is Map) {
        gruposAlimentos = Map<String, dynamic>.from(row['grupos_alimentos']);
      }
    }

    return PlanNutricional(
      id: row['id'] as String,
      nombre: row['nombre'] as String,
      codigo: row['codigo'] as String,
      descripcion: row['descripcion'] as String? ?? '',
      objetivoPrincipal: row['objetivo_principal'] as String? ?? '',
      gruposAlimentos: gruposAlimentos,
      activo: row['activo'] as bool? ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'objetivo_principal': objetivoPrincipal,
      'grupos_alimentos': gruposAlimentos,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Modelo para un grupo de alimentos dentro del plan
class GrupoAlimento {
  final String grupo;
  final String cantidadDiaria;
  final String formasPreparacion;
  final List<String> alimentosPermitidos;

  GrupoAlimento({
    required this.grupo,
    required this.cantidadDiaria,
    required this.formasPreparacion,
    required this.alimentosPermitidos,
  });

  factory GrupoAlimento.fromJson(Map<String, dynamic> json) {
    return GrupoAlimento(
      grupo: json['grupo'] as String? ?? '',
      cantidadDiaria: json['cantidad_diaria'] as String? ?? '',
      formasPreparacion: json['formas_preparacion'] as String? ?? '',
      alimentosPermitidos: (json['alimentos_permitidos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grupo': grupo,
      'cantidad_diaria': cantidadDiaria,
      'formas_preparacion': formasPreparacion,
      'alimentos_permitidos': alimentosPermitidos,
    };
  }
}

