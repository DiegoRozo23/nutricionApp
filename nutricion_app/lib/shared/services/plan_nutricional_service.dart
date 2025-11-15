import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plan_nutricional.dart';
import 'supabase_service.dart';

/// Servicio para consultar planes nutricionales desde la tabla plantillas_planes
class PlanNutricionalService {
  final SupabaseClient _supabase;

  PlanNutricionalService({SupabaseClient? supabase})
      : _supabase = supabase ?? supabaseService.client;

  /// Obtener el plan nutricional con id específico
  Future<PlanNutricional?> obtenerPlanPorId(String id) async {
    try {
      final response = await _supabase
          .from('plantillas_planes')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          print('Plan nutricional con id $id no encontrado');
        }
        return null;
      }

      return PlanNutricional.fromSupabaseRow(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener plan nutricional: $e');
      }
      rethrow;
    }
  }

  /// Obtener todos los planes activos
  Future<List<PlanNutricional>> obtenerPlanesActivos() async {
    try {
      final response = await _supabase
          .from('plantillas_planes')
          .select()
          .eq('activo', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => PlanNutricional.fromSupabaseRow(
                row as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener planes nutricionales: $e');
      }
      rethrow;
    }
  }
}

