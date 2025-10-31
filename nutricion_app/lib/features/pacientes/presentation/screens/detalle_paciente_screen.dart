import 'package:flutter/material.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../../domain/usecases/obtener_paciente_por_id_usecase.dart';
import '../../data/repositories/pacientes_repository_impl.dart';
import 'editar_paciente_screen.dart';

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
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navegarAEditar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditarPacienteScreen(paciente: _paciente),
      ),
    ).then((_) {
      // Recargar paciente cuando vuelva de editar
      _cargarPaciente();
    });
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
            icon: const Icon(Icons.edit),
            onPressed: _navegarAEditar,
            tooltip: 'Editar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _paciente.activo
                                      ? Colors.green
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _paciente.activo ? 'Activo' : 'Inactivo',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
    );
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
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

