import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/plan_nutricional.dart';
import '../../../../shared/services/planes_nutricionales_service.dart';
import '../../../../shared/services/plan_nutricional_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/evaluaciones_modelo_service.dart';
import '../../../auth/domain/entities/paciente.dart';
import 'editar_plan_nutricional_screen.dart';
import 'plan_nutricional_screen.dart';
import 'detalle_plan_sugerido_screen.dart';

/// Pantalla para mostrar el plan sugerido por la IA y permitir editarlo o guardarlo
class PlanSugeridoScreen extends StatefulWidget {
  final Paciente paciente;
  final String planRecomendadoNombre; // Nombre del plan recomendado por la IA
  final double tiempoGeneracionSegundos; // Tiempo que tardó la generación

  const PlanSugeridoScreen({
    super.key,
    required this.paciente,
    required this.planRecomendadoNombre,
    required this.tiempoGeneracionSegundos,
  });

  @override
  State<PlanSugeridoScreen> createState() => _PlanSugeridoScreenState();
}

class _PlanSugeridoScreenState extends State<PlanSugeridoScreen> {
  final PlanNutricionalService _planService = PlanNutricionalService();
  final PlanesNutricionalesService _planesService = PlanesNutricionalesService();
  final EvaluacionesModeloService _evaluacionesService = EvaluacionesModeloService();
  PlanNutricional? _planSugerido;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarPlanSugerido();
  }

  Future<void> _cargarPlanSugerido() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Buscar la plantilla que coincida con el nombre recomendado
      final plantillas = await _planService.obtenerPlanesActivos();
      
      // Buscar por nombre (puede ser parcial)
      PlanNutricional? planEncontrado;
      for (final plan in plantillas) {
        if (plan.nombre.toLowerCase().contains(
              widget.planRecomendadoNombre.toLowerCase(),
            ) ||
            widget.planRecomendadoNombre.toLowerCase().contains(
              plan.nombre.toLowerCase(),
            )) {
          planEncontrado = plan;
          break;
        }
      }

      // Si no se encuentra exacto, buscar por código
      if (planEncontrado == null) {
        final nombreLimpio = widget.planRecomendadoNombre
            .toLowerCase()
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^\w_]'), '');
        
        for (final plan in plantillas) {
          if (plan.codigo.toLowerCase().contains(nombreLimpio) ||
              nombreLimpio.contains(plan.codigo.toLowerCase())) {
            planEncontrado = plan;
            break;
          }
        }
      }

      // Si aún no se encuentra, usar la primera plantilla disponible
      if (planEncontrado == null && plantillas.isNotEmpty) {
        planEncontrado = plantillas.first;
        if (kDebugMode) {
          print('[PLAN_SUGERIDO] No se encontró plan exacto, usando: ${planEncontrado.nombre}');
        }
      }

      if (planEncontrado != null) {
        setState(() {
          _planSugerido = planEncontrado;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se encontró una plantilla que coincida con el plan recomendado';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar plan sugerido: $e');
      }
      setState(() {
        _errorMessage = 'Error al cargar el plan sugerido: ${e.toString()}';
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plan Sugerido para ${widget.paciente.nombre}'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                )
              : _planSugerido == null
                  ? const Center(child: Text('No se encontró el plan sugerido'))
                  : Column(
                      children: [
                        // Banner informativo
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: const Color(0xFFFF9800).withOpacity(0.1),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Plan Recomendado por Machine Learning',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Basado en los datos del paciente, se recomienda:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Vista previa del plan
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _planSugerido!.nombre,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _planSugerido!.descripcion,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Objetivo Principal:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _planSugerido!.objetivoPrincipal,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Botón Siguiente
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (_planSugerido != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetallePlanSugeridoScreen(
                                          paciente: widget.paciente,
                                          planSugerido: _planSugerido!,
                                          tiempoGeneracionSegundos: widget.tiempoGeneracionSegundos,
                                        ),
                                      ),
                                    ).then((result) {
                                      if (result == true && mounted) {
                                        // Si se guardó exitosamente, cerrar esta pantalla también
                                        Navigator.of(context).pop(true);
                                      }
                                    });
                                  }
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text(
                                  'Siguiente',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9800),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

