import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/plan_nutricional.dart';
import '../../../../shared/services/planes_nutricionales_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/evaluaciones_modelo_service.dart';
import 'plan_nutricional_screen.dart';

/// Pantalla para editar un plan nutricional asignado a un paciente
class EditarPlanNutricionalScreen extends StatefulWidget {
  final String pacienteId;
  final String? planId; // ID del plan específico a editar
  final PlanNutricional planActual;

  const EditarPlanNutricionalScreen({
    super.key,
    required this.pacienteId,
    this.planId,
    required this.planActual,
  });

  @override
  State<EditarPlanNutricionalScreen> createState() => _EditarPlanNutricionalScreenState();
}

class _EditarPlanNutricionalScreenState extends State<EditarPlanNutricionalScreen> {
  final PlanesNutricionalesService _planesService = PlanesNutricionalesService();
  final EvaluacionesModeloService _evaluacionesService = EvaluacionesModeloService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _objetivoController;
  
  List<GrupoAlimentoEditado> _gruposAlimentos = [];
  bool _isLoading = false;
  String? _planId;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.planActual.nombre);
    _descripcionController = TextEditingController(text: widget.planActual.descripcion);
    _objetivoController = TextEditingController(text: widget.planActual.objetivoPrincipal);
    
    // Cargar grupos de alimentos
    _cargarGruposAlimentos();
    _cargarPlanId();
  }

  Future<void> _cargarPlanId() async {
    try {
      Map<String, dynamic>? planAsignado;
      if (widget.planId != null) {
        planAsignado = await _planesService.obtenerPlanPorId(widget.planId!);
      } else {
        planAsignado = await _planesService.obtenerPlanPorPaciente(widget.pacienteId);
      }
      if (planAsignado != null) {
        setState(() {
          _planId = planAsignado!['id'] as String;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar plan ID: $e');
      }
    }
  }

  void _cargarGruposAlimentos() {
    final gruposData = widget.planActual.gruposAlimentos;
    if (gruposData.containsKey('grupos') && gruposData['grupos'] is List) {
      final gruposList = gruposData['grupos'] as List;
      _gruposAlimentos = gruposList.map((grupoData) {
        if (grupoData is Map<String, dynamic>) {
          return GrupoAlimentoEditado.fromJson(grupoData);
        }
        return GrupoAlimentoEditado(
          grupo: '',
          cantidadDiaria: '',
          formasPreparacion: '',
          alimentosPermitidos: [],
        );
      }).toList();
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Construir el plan editado
      final planEditado = {
        'id': widget.planActual.id,
        'nombre': _nombreController.text,
        'codigo': widget.planActual.codigo,
        'descripcion': _descripcionController.text,
        'objetivo_principal': _objetivoController.text,
        'grupos_alimentos': {
          'grupos': _gruposAlimentos.map((g) => g.toJson()).toList(),
        },
        'activo': widget.planActual.activo,
        'created_at': widget.planActual.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_planId != null) {
        await _planesService.actualizarPlanNutricional(
          planId: _planId!,
          planEditado: planEditado,
        );

        // Actualizar evaluación a "Incorrecto" si existe, o crear una nueva
        try {
          final evaluacionExistente = await _evaluacionesService.obtenerEvaluacionPorPlanId(_planId!);
          if (evaluacionExistente != null) {
            // Actualizar calificación existente a "Incorrecto"
            await _evaluacionesService.actualizarCalificacion(
              planId: _planId!,
              calificacionNutricionista: 'Incorrecto',
            );
          } else {
            // Si no existe evaluación, crear una nueva (caso raro, pero por si acaso)
            final user = supabaseService.client.auth.currentUser;
            if (user != null) {
              final nutriResponse = await supabaseService.client
                  .from('nutricionistas')
                  .select('id')
                  .eq('auth_uid', user.id)
                  .maybeSingle();
              
              if (nutriResponse != null) {
                final anioActual = DateTime.now().year;
                final numeroSecuencial = await _evaluacionesService.obtenerSiguienteNumeroSecuencial(anioActual);
                final codigoPlan = EvaluacionesModeloService.generarCodigoPlan(numeroSecuencial, anioActual);
                
                await _evaluacionesService.crearEvaluacion(
                  planId: _planId!,
                  codigoPlan: codigoPlan,
                  tipoPlanNutricional: _nombreController.text,
                  tiempoGeneracionSegundos: 0.0, // No se conoce el tiempo original
                  calificacionNutricionista: 'Incorrecto',
                  nutricionistaId: nutriResponse['id'] as String,
                  pacienteId: widget.pacienteId,
                );
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error al actualizar evaluación: $e');
          }
          // Continuar aunque falle la actualización de evaluación
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan nutricional actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Cerrar esta pantalla y navegar a la visualización del plan
          Navigator.of(context).pop(); // Cerrar EditarPlanNutricionalScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlanNutricionalScreen(
                planId: _planId,
                pacienteId: widget.pacienteId,
              ),
            ),
          );
        }
      } else {
        throw Exception('No se encontró el ID del plan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cambios: ${e.toString()}'),
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
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _objetivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Plan Nutricional'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarCambios,
              tooltip: 'Guardar cambios',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 80, // Margen para botón flotante
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del plan
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Plan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  minLines: 3,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La descripción es requerida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Objetivo principal
                TextFormField(
                  controller: _objetivoController,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo Principal',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  minLines: 5,
                  textInputAction: TextInputAction.newline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El objetivo principal es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Grupos de alimentos
                const Text(
                  'Grupos de Alimentos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ..._gruposAlimentos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final grupo = entry.value;
                  return _GrupoAlimentoEditor(
                    grupo: grupo,
                    onChanged: (grupoActualizado) {
                      setState(() {
                        _gruposAlimentos[index] = grupoActualizado;
                      });
                    },
                  );
                }).toList(),

                const SizedBox(height: 80), // Espacio para el botón flotante
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _guardarCambios,
        icon: const Icon(Icons.save),
        label: const Text('Guardar Cambios'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Clase para editar grupos de alimentos
class GrupoAlimentoEditado {
  String grupo;
  String cantidadDiaria;
  String formasPreparacion;
  List<String> alimentosPermitidos;

  GrupoAlimentoEditado({
    required this.grupo,
    required this.cantidadDiaria,
    required this.formasPreparacion,
    required this.alimentosPermitidos,
  });

  factory GrupoAlimentoEditado.fromJson(Map<String, dynamic> json) {
    return GrupoAlimentoEditado(
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

/// Widget para editar un grupo de alimentos
class _GrupoAlimentoEditor extends StatefulWidget {
  final GrupoAlimentoEditado grupo;
  final Function(GrupoAlimentoEditado) onChanged;

  const _GrupoAlimentoEditor({
    required this.grupo,
    required this.onChanged,
  });

  @override
  State<_GrupoAlimentoEditor> createState() => _GrupoAlimentoEditorState();
}

class _GrupoAlimentoEditorState extends State<_GrupoAlimentoEditor> {
  late TextEditingController _grupoController;
  late TextEditingController _cantidadController;
  late TextEditingController _formasController;
  late TextEditingController _alimentosController;

  @override
  void initState() {
    super.initState();
    _grupoController = TextEditingController(text: widget.grupo.grupo);
    _cantidadController = TextEditingController(text: widget.grupo.cantidadDiaria);
    _formasController = TextEditingController(text: widget.grupo.formasPreparacion);
    _alimentosController = TextEditingController(
      text: widget.grupo.alimentosPermitidos.join(', '),
    );
  }

  @override
  void dispose() {
    _grupoController.dispose();
    _cantidadController.dispose();
    _formasController.dispose();
    _alimentosController.dispose();
    super.dispose();
  }

  void _actualizarGrupo() {
    final alimentos = _alimentosController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    widget.onChanged(GrupoAlimentoEditado(
      grupo: _grupoController.text,
      cantidadDiaria: _cantidadController.text,
      formasPreparacion: _formasController.text,
      alimentosPermitidos: alimentos,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _grupoController,
              decoration: const InputDecoration(
                labelText: 'Grupo',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _actualizarGrupo(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad Diaria',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _actualizarGrupo(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _formasController,
              decoration: const InputDecoration(
                labelText: 'Formas de Preparación',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              minLines: 3,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _actualizarGrupo(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _alimentosController,
              decoration: const InputDecoration(
                labelText: 'Alimentos Permitidos (separados por comas)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                helperText: 'Separa los alimentos con comas',
              ),
              maxLines: null,
              minLines: 4,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => _actualizarGrupo(),
            ),
          ],
        ),
      ),
    );
  }
}

