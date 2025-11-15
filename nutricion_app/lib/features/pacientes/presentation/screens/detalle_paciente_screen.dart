import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../../domain/usecases/obtener_paciente_por_id_usecase.dart';
import '../../data/repositories/pacientes_repository_impl.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../../shared/services/chat_service.dart';
import 'editar_paciente_screen.dart';
import 'plan_nutricional_screen.dart';
import 'seleccionar_plantilla_screen.dart';
import 'lista_planes_paciente_screen.dart';

/// Pantalla que muestra los detalles de un paciente
class DetallePacienteScreen extends StatefulWidget {
  final Paciente paciente;

  const DetallePacienteScreen({
    super.key,
    required this.paciente,
  });

  @override
  State<DetallePacienteScreen> createState() => _DetallePacienteScreenState();
}

class _DetallePacienteScreenState extends State<DetallePacienteScreen> {
  late Paciente _paciente;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paciente = widget.paciente;
    _cargarPaciente();
  }

  Future<void> _cargarPaciente() async {
    // Verificar que el paciente tenga ID válido
    if (_paciente.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Paciente sin ID válido. Volviendo a la lista...'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final repository = PacientesRepositoryImpl();
    final useCase = ObtenerPacientePorIdUseCase(repository);
    final result = await useCase(_paciente.id);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result is PacientesSuccess<Paciente>) {
      setState(() {
        _paciente = result.data;
      });
    } else if (result is PacientesFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.message}. Intentando recargar...'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      // Esperar un momento y reintentar
      await Future.delayed(const Duration(milliseconds: 500));
      await _cargarPaciente();
    }
  }

  Future<void> _abrirChatConPaciente() async {
    if (_paciente.authUid == null || _paciente.authUid!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El paciente no tiene cuenta de usuario asociada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Crear o obtener el room de chat
      if (kDebugMode) {
        print('[DETALLE_PACIENTE] Iniciando chat con paciente: ${_paciente.authUid}');
      }
      
      final room = await chatService.createOrGetDirectRoom(_paciente.authUid!);
      
      if (kDebugMode) {
        print('[DETALLE_PACIENTE] ✅ Room obtenido/creado: ${room.id}');
      }

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Navegar a la pantalla de chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(room: room),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading si está abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navegarAEditar() async {
    final resultado = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditarPacienteScreen(paciente: _paciente),
      ),
    );
    
    // Si se actualizó el paciente, cerrar esta pantalla también y volver a la lista
    if (resultado == true && mounted) {
      // Cerrar esta pantalla (detalle) y volver a la lista
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_paciente.nombreCompleto),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: _abrirChatConPaciente,
            tooltip: 'Chat',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navegarAEditar,
            tooltip: 'Editar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 80, // Padding considerable para botones de Android
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de información básica
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _paciente.nombreCompleto,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_paciente.dni != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'DNI: ${_paciente.dni}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón para iniciar chat
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _abrirChatConPaciente,
                      icon: const Icon(Icons.chat, size: 24),
                      label: const Text(
                        'Iniciar Chat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón Generar Plan Nutricional
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeleccionarPlantillaScreen(
                              paciente: _paciente,
                            ),
                          ),
                        ).then((result) {
                          // Si se generó el plan, recargar datos
                          if (result == true) {
                            _cargarPaciente();
                          }
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: const Text(
                        'Generar Plan Nutricional',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón Ver Plan Nutricional
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListaPlanesPacienteScreen(
                              paciente: _paciente,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu, size: 24),
                      label: const Text(
                        'Ver Planes Nutricionales',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información personal
                  const Text(
                    'Información Personal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'Sexo',
                            value: _paciente.sexo ?? 'No especificado',
                          ),
                          _InfoRow(
                            label: 'Edad',
                            value: _paciente.edad?.toString() ?? 'No especificada',
                          ),
                          _InfoRow(
                            label: 'Peso',
                            value: _paciente.peso != null
                                ? '${_paciente.peso} kg'
                                : 'No especificado',
                          ),
                          _InfoRow(
                            label: 'Talla',
                            value: _paciente.talla != null
                                ? '${_paciente.talla} m'
                                : 'No especificada',
                          ),
                          _InfoRow(
                            label: 'IMC',
                            value: _paciente.imc != null
                                ? _paciente.imc!.toStringAsFixed(2)
                                : 'No calculado',
                          ),
                          _InfoRow(
                            label: 'Actividad Física',
                            value: _paciente.actividadFisica ?? 'No especificada',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medidas Antropométricas
                  if (_paciente.medidasAntropometricas != null && 
                      _paciente.medidasAntropometricas!.isNotEmpty) ...[
                    const Text(
                      'Medidas Antropométricas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ..._paciente.medidasAntropometricas!.entries.map((entry) {
                              return _InfoRow(
                                label: entry.key,
                                value: _formatMedidaValue(entry.value),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Historial médico
                  if (_paciente.historialMedico != null) ...[
                    const Text(
                      'Historial Médico',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_paciente.historialMedico!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Observaciones
                  if (_paciente.observaciones != null) ...[
                    const Text(
                      'Observaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_paciente.observaciones!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
            ),
              ),
            ),
    );
  }

  /// Formatear el valor de una medida antropométrica
  String _formatMedidaValue(dynamic value) {
    if (value is num) {
      // Si es un número, mostrar con formato apropiado
      if (value is int) {
        return value.toString();
      } else if (value is double) {
        // Redondear a 2 decimales si es necesario
        return value == value.roundToDouble()
            ? value.round().toString()
            : value.toStringAsFixed(2);
      }
    }
    return value.toString();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

