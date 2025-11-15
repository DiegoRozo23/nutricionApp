import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/plan_nutricional.dart';
import '../../../../shared/services/planes_nutricionales_service.dart';
import '../../../../shared/services/supabase_service.dart';
import 'plan_nutricional_screen.dart';
import 'seleccionar_plantilla_screen.dart';
import '../../../auth/domain/entities/paciente.dart';

/// Pantalla para listar todos los planes nutricionales de un paciente
class ListaPlanesPacienteScreen extends StatefulWidget {
  final Paciente paciente;

  const ListaPlanesPacienteScreen({
    super.key,
    required this.paciente,
  });

  @override
  State<ListaPlanesPacienteScreen> createState() => _ListaPlanesPacienteScreenState();
}

class _ListaPlanesPacienteScreenState extends State<ListaPlanesPacienteScreen> {
  final PlanesNutricionalesService _planesService = PlanesNutricionalesService();
  List<Map<String, dynamic>> _planes = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _esNutricionista = false;

  @override
  void initState() {
    super.initState();
    _verificarRol();
    _cargarPlanes();
  }

  Future<void> _verificarRol() async {
    try {
      final user = supabaseService.client.auth.currentUser;
      if (user != null) {
        final nutriResponse = await supabaseService.client
            .from('nutricionistas')
            .select('id')
            .eq('auth_uid', user.id)
            .maybeSingle();
        
        setState(() {
          _esNutricionista = nutriResponse != null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al verificar rol: $e');
      }
    }
  }

  Future<void> _cargarPlanes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final planes = await _planesService.obtenerTodosLosPlanesPorPaciente(widget.paciente.id);
      setState(() {
        _planes = planes;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar planes: $e');
      }
      setState(() {
        _errorMessage = 'Error al cargar los planes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _obtenerNombrePlan(Map<String, dynamic> planData) {
    try {
      final planEditado = planData['plan_editado'];
      final planGenerado = planData['plan_generado'];
      
      Map<String, dynamic> planMap;
      if (planEditado != null) {
        planMap = planEditado is String 
            ? jsonDecode(planEditado) as Map<String, dynamic>
            : planEditado as Map<String, dynamic>;
      } else if (planGenerado != null) {
        planMap = planGenerado is String
            ? jsonDecode(planGenerado) as Map<String, dynamic>
            : planGenerado as Map<String, dynamic>;
      } else {
        return 'Plan sin nombre';
      }
      
      return planMap['nombre'] as String? ?? 'Plan sin nombre';
    } catch (e) {
      return 'Plan sin nombre';
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  Future<void> _eliminarPlan(String planId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Plan'),
        content: const Text('¿Estás seguro de que deseas eliminar este plan? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      await _planesService.eliminarPlanNutricional(planId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarPlanes();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planes de ${widget.paciente.nombre}'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          if (_esNutricionista)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeleccionarPlantillaScreen(
                      paciente: widget.paciente,
                    ),
                  ),
                );
                if (result == true) {
                  _cargarPlanes();
                }
              },
              tooltip: 'Generar Nuevo Plan',
            ),
        ],
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
                        onPressed: _cargarPlanes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _planes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay planes nutricionales',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_esNutricionista)
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SeleccionarPlantillaScreen(
                                      paciente: widget.paciente,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _cargarPlanes();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Generar Primer Plan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarPlanes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _planes.length,
                        itemBuilder: (context, index) {
                          final planData = _planes[index];
                          final planId = planData['id'] as String;
                          final createdAt = DateTime.parse(planData['created_at'] as String);
                          final nombrePlan = _obtenerNombrePlan(planData);
                          final tieneEdicion = planData['plan_editado'] != null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      nombrePlan,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ),
                                  if (tieneEdicion)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Editado',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Creado: ${_formatearFecha(createdAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              trailing: _esNutricionista
                                  ? PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(
                                          value: 'ver',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.visibility, size: 20),
                                              SizedBox(width: 8),
                                              Text('Ver'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'editar',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.edit, size: 20),
                                              SizedBox(width: 8),
                                              Text('Editar'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        PopupMenuItem<String>(
                                          value: 'eliminar',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.delete, size: 20, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) async {
                                        if (value == 'ver') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PlanNutricionalScreen(
                                                pacienteId: widget.paciente.id,
                                                planId: planId,
                                              ),
                                            ),
                                          );
                                        } else if (value == 'editar') {
                                          // Cargar el plan y navegar a edición
                                          final plan = await _planesService.obtenerPlanPorId(planId);
                                          if (plan != null) {
                                            final planData = plan['plan_editado'] ?? plan['plan_generado'];
                                            if (planData != null) {
                                              Map<String, dynamic> planMap;
                                              if (planData is String) {
                                                planMap = jsonDecode(planData) as Map<String, dynamic>;
                                              } else {
                                                planMap = planData as Map<String, dynamic>;
                                              }
                                              final planNutricional = PlanNutricional.fromSupabaseRow(planMap);
                                              
                                              // Navegar a edición (necesitarás crear esta pantalla o usar la existente)
                                              // Por ahora, navegamos a la pantalla de visualización que tiene botón de editar
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PlanNutricionalScreen(
                                                    pacienteId: widget.paciente.id,
                                                    planId: planId,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        } else if (value == 'eliminar') {
                                          _eliminarPlan(planId);
                                        }
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.visibility),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlanNutricionalScreen(
                                              pacienteId: widget.paciente.id,
                                              planId: planId,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlanNutricionalScreen(
                                      pacienteId: widget.paciente.id,
                                      planId: planId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

