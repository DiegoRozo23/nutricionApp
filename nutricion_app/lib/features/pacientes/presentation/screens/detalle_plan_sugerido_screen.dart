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

/// Pantalla para mostrar el detalle del plan sugerido y realizar la evaluación fila por fila
class DetallePlanSugeridoScreen extends StatefulWidget {
  final Paciente paciente;
  final PlanNutricional planSugerido;
  final double tiempoGeneracionSegundos;

  const DetallePlanSugeridoScreen({
    super.key,
    required this.paciente,
    required this.planSugerido,
    required this.tiempoGeneracionSegundos,
  });

  @override
  State<DetallePlanSugeridoScreen> createState() => _DetallePlanSugeridoScreenState();
}

class _DetallePlanSugeridoScreenState extends State<DetallePlanSugeridoScreen> {
  final PlanNutricionalService _planService = PlanNutricionalService(); // Helper para parsear grupos si es necesario
  final PlanesNutricionalesService _planesService = PlanesNutricionalesService();
  final EvaluacionesModeloService _evaluacionesService = EvaluacionesModeloService();
  
  // Mapa para almacenar la evaluación de cada fila: index -> esCorrecto (true/false)
  final Map<int, bool> _evaluacionesFilas = {};
  List<GrupoAlimento> _gruposAlimentos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarGruposAlimentos();
  }

  void _cargarGruposAlimentos() {
    // Parsear los grupos de alimentos del plan
    final gruposData = widget.planSugerido.gruposAlimentos;
    if (gruposData.containsKey('grupos') && gruposData['grupos'] is List) {
      final gruposList = gruposData['grupos'] as List;
      _gruposAlimentos = gruposList.map((grupoData) {
        if (grupoData is Map<String, dynamic>) {
          return GrupoAlimento.fromJson(grupoData);
        }
        return GrupoAlimento(
          grupo: '',
          cantidadDiaria: '',
          formasPreparacion: '',
          alimentosPermitidos: [],
        );
      }).toList();
    }
  }

  bool _validarEvaluacionCompleta() {
    return _evaluacionesFilas.length == _gruposAlimentos.length;
  }

  Future<void> _guardarPlan(bool editarDespues) async {
    if (!_validarEvaluacionCompleta()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor evalúa todas las filas de la tabla antes de continuar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calcular métricas
      final filasCorrectas = _evaluacionesFilas.values.where((v) => v).length;
      final filasIncorrectas = _evaluacionesFilas.values.where((v) => !v).length;
      
      final calificacionGeneral = editarDespues ? 'Incorrecto' : 'Correcto';

      // Obtener el nutricionista actual
      final user = supabaseService.client.auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final nutriResponse = await supabaseService.client
          .from('nutricionistas')
          .select('id')
          .eq('auth_uid', user.id)
          .single();

      final nutricionistaId = nutriResponse['id'] as String;

      // Convertir el plan a JSON para guardar
      final planGenerado = widget.planSugerido.toJson();

      // Crear el plan nutricional en la BD
      final planCreado = await _planesService.crearPlanNutricional(
        pacienteId: widget.paciente.id,
        nutricionistaId: nutricionistaId,
        planGenerado: planGenerado,
      );

      final planId = planCreado['id'] as String;

      // Obtener el número secuencial para el código del plan
      final anioActual = DateTime.now().year;
      final numeroSecuencial = await _evaluacionesService.obtenerSiguienteNumeroSecuencial(anioActual);

      // Generar código del plan
      final codigoPlan = EvaluacionesModeloService.generarCodigoPlan(numeroSecuencial, anioActual);

      // Registrar evaluación con las nuevas métricas
      await _evaluacionesService.crearEvaluacion(
        planId: planId,
        codigoPlan: codigoPlan,
        tipoPlanNutricional: widget.planSugerido.nombre,
        tiempoGeneracionSegundos: widget.tiempoGeneracionSegundos,
        calificacionNutricionista: calificacionGeneral,
        nutricionistaId: nutricionistaId,
        pacienteId: widget.paciente.id,
        filasCorrectas: filasCorrectas,
        filasIncorrectas: filasIncorrectas,
      );

      if (editarDespues) {
        // Navegar a la pantalla de edición
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditarPlanNutricionalScreen(
                pacienteId: widget.paciente.id,
                planId: planId,
                planActual: widget.planSugerido,
              ),
            ),
          );

          if (result == true && mounted) {
            // Cerrar pantallas hasta volver al dashboard o lista
            Navigator.of(context).pop(true); // Cerrar DetallePlanSugeridoScreen
            Navigator.of(context).pop(true); // Cerrar PlanSugeridoScreen
            Navigator.of(context).pop(true); // Cerrar SeleccionarPlantillaScreen
          }
        }
      } else {
        // Guardado directo ("Guardar tal cual")
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan nutricional guardado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navegar a la visualización del plan
          Navigator.of(context).pop(); // Cerrar DetallePlanSugeridoScreen
          Navigator.of(context).pop(); // Cerrar PlanSugeridoScreen
          Navigator.of(context).pop(); // Cerrar SeleccionarPlantillaScreen
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlanNutricionalScreen(
                planId: planId,
                pacienteId: widget.paciente.id,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Plan Sugerido'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumen del plan
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.planSugerido.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.planSugerido.descripcion,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Objetivo:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        widget.planSugerido.objetivoPrincipal,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Tabla de evaluación
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: double.infinity,
                        columnSpacing: 20,
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                        columns: const [
                          DataColumn(
                            label: Text(
                              '¿Correcto?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Grupo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Cantidad',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Alimentos',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Preparación',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: _gruposAlimentos.asMap().entries.map((entry) {
                          final index = entry.key;
                          final grupo = entry.value;
                          final esCorrecto = _evaluacionesFilas[index];

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                                if (esCorrecto == false) return Colors.red.shade50;
                                if (esCorrecto == true) return Colors.green.shade50;
                                return null;
                              },
                            ),
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.check_circle,
                                        color: esCorrecto == true ? Colors.green : Colors.grey.shade400,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _evaluacionesFilas[index] = true;
                                        });
                                      },
                                      tooltip: 'Correcto',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.cancel,
                                        color: esCorrecto == false ? Colors.red : Colors.grey.shade400,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _evaluacionesFilas[index] = false;
                                        });
                                      },
                                      tooltip: 'Incorrecto',
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    grupo.grupo,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    grupo.cantidadDiaria,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 250,
                                  child: Text(
                                    grupo.alimentosPermitidos.join(', '),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    grupo.formasPreparacion,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // Botones de acción
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _guardarPlan(true),
                            icon: const Icon(Icons.edit),
                            label: const Text(
                              'Editar y Guardar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => _guardarPlan(false),
                            icon: const Icon(Icons.save),
                            label: const Text(
                              'Guardar Tal Cual',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4CAF50),
                              side: const BorderSide(
                                color: Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
