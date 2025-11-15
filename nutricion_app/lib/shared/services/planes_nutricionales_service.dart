import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plan_nutricional.dart';
import 'supabase_service.dart';

/// Servicio para gestionar planes nutricionales asignados a pacientes
class PlanesNutricionalesService {
  final SupabaseClient _supabase;

  PlanesNutricionalesService({SupabaseClient? supabase})
      : _supabase = supabase ?? supabaseService.client;

  /// Obtener el plan nutricional más reciente asignado a un paciente
  Future<Map<String, dynamic>?> obtenerPlanPorPaciente(String pacienteId) async {
    try {
      final response = await _supabase
          .from('planes_nutricionales')
          .select()
          .eq('paciente_id', pacienteId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener plan nutricional: $e');
      }
      rethrow;
    }
  }

  /// Obtener todos los planes nutricionales de un paciente
  Future<List<Map<String, dynamic>>> obtenerTodosLosPlanesPorPaciente(String pacienteId) async {
    try {
      final response = await _supabase
          .from('planes_nutricionales')
          .select()
          .eq('paciente_id', pacienteId)
          .order('created_at', ascending: false);

      if (response == null || response.isEmpty) {
        return [];
      }

      return (response as List).map((row) => row as Map<String, dynamic>).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener planes nutricionales: $e');
      }
      rethrow;
    }
  }

  /// Obtener un plan nutricional por su ID
  Future<Map<String, dynamic>?> obtenerPlanPorId(String planId) async {
    try {
      final response = await _supabase
          .from('planes_nutricionales')
          .select()
          .eq('id', planId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener plan nutricional por ID: $e');
      }
      rethrow;
    }
  }

  /// Crear un nuevo plan nutricional para un paciente
  Future<Map<String, dynamic>> crearPlanNutricional({
    required String pacienteId,
    required String nutricionistaId,
    required Map<String, dynamic> planGenerado,
    Map<String, dynamic>? planEditado,
  }) async {
    try {
      final planData = {
        'paciente_id': pacienteId,
        'nutricionista_id': nutricionistaId,
        'plan_generado': planGenerado,
        if (planEditado != null) 'plan_editado': planEditado,
      };

      final response = await _supabase
          .from('planes_nutricionales')
          .insert(planData)
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error al crear plan nutricional: $e');
      }
      rethrow;
    }
  }

  /// Actualizar el plan nutricional editado
  Future<void> actualizarPlanNutricional({
    required String planId,
    required Map<String, dynamic> planEditado,
  }) async {
    try {
      await _supabase
          .from('planes_nutricionales')
          .update({'plan_editado': planEditado})
          .eq('id', planId);
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar plan nutricional: $e');
      }
      rethrow;
    }
  }

  /// Eliminar un plan nutricional
  Future<void> eliminarPlanNutricional(String planId) async {
    try {
      await _supabase
          .from('planes_nutricionales')
          .delete()
          .eq('id', planId);
    } catch (e) {
      if (kDebugMode) {
        print('Error al eliminar plan nutricional: $e');
      }
      rethrow;
    }
  }

  /// Obtener todas las plantillas activas
  Future<List<PlanNutricional>> obtenerPlantillasActivas() async {
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
        print('Error al obtener plantillas: $e');
      }
      rethrow;
    }
  }
}

