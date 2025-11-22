import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio para obtener predicciones de planes nutricionales usando API en Render
class PrediccionPlanService {
  // URL de la API en Render
  static const String _apiUrl = 'https://randomforest-af5a.onrender.com/predecir';

  PrediccionPlanService();

  /// Obtener predicción de plan nutricional basado en datos del paciente
  /// 
  /// [datosPaciente] debe contener:
  /// - Edad (int)
  /// - Sexo (String: "Masculino" o "Femenino")
  /// - Peso actual (kg) (double)
  /// - Talla (m) (double)
  /// - IMC (double)
  /// - Circunferencia de cintura (cm) (double)
  /// - Nivel de actividad física (String)
  Future<Map<String, dynamic>> obtenerPrediccionPlan({
    required int edad,
    required String sexo,
    required double pesoActual,
    required double talla,
    required double imc,
    required double circunferenciaCintura,
    required String nivelActividadFisica,
  }) async {
    try {
      // Mapear los datos al formato que espera la API de Python/Pydantic
      final datosPaciente = {
        'Edad': edad,
        'Sexo': sexo,
        'Peso_actual_kg': pesoActual,
        'Talla_m': talla,
        'IMC_Indice_de_Masa_Corporal': imc,
        'Circunferencia_de_cintura_cm': circunferenciaCintura,
        'Nivel_de_actividad_fisica': nivelActividadFisica,
      };

      if (kDebugMode) {
        print('[PREDICCION] Enviando datos del paciente: $datosPaciente');
        print('[PREDICCION] URL: $_apiUrl');
      }

      // Llamar a la API en Render
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(datosPaciente),
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('Timeout: La API no respondió en 90 segundos');
        },
      );

      if (kDebugMode) {
        print('[PREDICCION] Status Code: ${response.statusCode}');
        print('[PREDICCION] Response Body: ${response.body}');
      }

      // Verificar el status de la respuesta
      if (response.statusCode != 200) {
        throw Exception(
          'Error en la API (${response.statusCode}): ${response.body.isNotEmpty ? response.body : "Sin detalles"}',
        );
      }

      // Parsear la respuesta JSON
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData;
      } catch (e) {
        if (kDebugMode) {
          print('[PREDICCION] Error al parsear respuesta: $e');
        }
        throw Exception('Error al parsear la respuesta de la API: ${e.toString()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PREDICCION] Error al obtener predicción: $e');
      }
      
      // Proporcionar un mensaje más útil si es un error de conexión
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
          'No se pudo conectar con la API en Render. '
          'Por favor verifica que:\n'
          '1. La API esté desplegada y funcionando\n'
          '2. Tengas conexión a internet\n'
          '3. La URL sea correcta: $_apiUrl',
        );
      }
      
      rethrow;
    }
  }
}

