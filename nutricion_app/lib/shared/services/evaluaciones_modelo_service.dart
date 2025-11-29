import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Servicio para gestionar evaluaciones de modelos de planes nutricionales
class EvaluacionesModeloService {
  final SupabaseClient _supabase;

  EvaluacionesModeloService({SupabaseClient? supabase})
      : _supabase = supabase ?? supabaseService.client;

  /// Crear una evaluación de modelo
  Future<Map<String, dynamic>> crearEvaluacion({
    required String planId,
    required String codigoPlan,
    required String tipoPlanNutricional,
    required double tiempoGeneracionSegundos,
    required String calificacionNutricionista,
    required String nutricionistaId,
    required String pacienteId,
    required int filasCorrectas,
    required int filasIncorrectas,
  }) async {
    try {
      final evaluacionData = {
        'plan_id': planId,
        'codigo_plan': codigoPlan,
        'tipo_plan_nutricional': tipoPlanNutricional,
        'tiempo_generacion_segundos': tiempoGeneracionSegundos,
        'calificacion_nutricionista': calificacionNutricionista,
        'nutricionista_id': nutricionistaId,
        'paciente_id': pacienteId,
        'filas_correctas': filasCorrectas,
        'filas_incorrectas': filasIncorrectas,
      };

      final response = await _supabase
          .from('evaluaciones_modelo')
          .insert(evaluacionData)
          .select()
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error al crear evaluación: $e');
      }
      rethrow;
    }
  }

  /// Actualizar la calificación de una evaluación
  Future<void> actualizarCalificacion({
    required String planId,
    required String calificacionNutricionista,
  }) async {
    try {
      final updateData = {
        'calificacion_nutricionista': calificacionNutricionista,
      };

      await _supabase
          .from('evaluaciones_modelo')
          .update(updateData)
          .eq('plan_id', planId);
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar calificación: $e');
      }
      rethrow;
    }
  }

  /// Obtener todas las evaluaciones del nutricionista logueado
  Future<List<Map<String, dynamic>>> obtenerTodasLasEvaluaciones() async {
    try {
      // Obtener el nutricionista actual
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('No hay usuario autenticado');
        }
        return [];
      }

      // Obtener el ID del nutricionista
      final nutriResponse = await _supabase
          .from('nutricionistas')
          .select('id')
          .eq('auth_uid', user.id)
          .maybeSingle();

      if (nutriResponse == null) {
        if (kDebugMode) {
          print('No se encontró nutricionista para el usuario');
        }
        return [];
      }

      final nutricionistaId = nutriResponse['id'] as String;

      // Obtener solo las evaluaciones del nutricionista logueado
      final response = await _supabase
          .from('evaluaciones_modelo')
          .select('''
            *,
            pacientes:paciente_id(nombre, apellidos)
          ''')
          .eq('nutricionista_id', nutricionistaId)
          .order('fecha_evaluacion', ascending: false);

      if (response == null || response.isEmpty) {
        return [];
      }

      return (response as List).map((row) => row as Map<String, dynamic>).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener evaluaciones: $e');
      }
      rethrow;
    }
  }

  /// Obtener el siguiente número secuencial para el código del plan
  Future<int> obtenerSiguienteNumeroSecuencial(int anio) async {
    try {
      final evaluaciones = await obtenerTodasLasEvaluaciones();
      final evaluacionesAnio = evaluaciones
          .where((e) {
            final codigo = e['codigo_plan']?.toString() ?? '';
            return codigo.endsWith('-$anio');
          })
          .toList();
      return evaluacionesAnio.length + 1;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener siguiente número secuencial: $e');
      }
      return 1; // Retornar 1 por defecto si hay error
    }
  }

  /// Obtener evaluación por plan_id
  Future<Map<String, dynamic>?> obtenerEvaluacionPorPlanId(String planId) async {
    try {
      final response = await _supabase
          .from('evaluaciones_modelo')
          .select()
          .eq('plan_id', planId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener evaluación por plan_id: $e');
      }
      rethrow;
    }
  }

  /// Generar código de plan en formato ###-AAAA
  /// ### = número secuencial, AAAA = año
  static String generarCodigoPlan(int numeroSecuencial, int anio) {
    return '${numeroSecuencial.toString().padLeft(3, '0')}-$anio';
  }
}

