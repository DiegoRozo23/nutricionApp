import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../../domain/usecases/obtener_pacientes_usecase.dart';
import '../../data/repositories/pacientes_repository_impl.dart';
import 'seleccionar_plantilla_screen.dart';

/// Pantalla para seleccionar un paciente y luego generar un plan nutricional
class SeleccionarPacientePlanScreen extends StatefulWidget {
  const SeleccionarPacientePlanScreen({super.key});

  @override
  State<SeleccionarPacientePlanScreen> createState() => _SeleccionarPacientePlanScreenState();
}

class _SeleccionarPacientePlanScreenState extends State<SeleccionarPacientePlanScreen> {
  final PacientesRepository _repository = PacientesRepositoryImpl();
  List<Paciente> _pacientes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final useCase = ObtenerPacientesUseCase(_repository);
      final result = await useCase();

      if (result is PacientesSuccess<List<Paciente>>) {
        setState(() {
          _pacientes = result.data;
          _isLoading = false;
        });
      } else if (result is PacientesFailure) {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar pacientes: $e');
      }
      setState(() {
        _errorMessage = 'Error al cargar pacientes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _seleccionarPaciente(Paciente paciente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarPlantillaScreen(paciente: paciente),
      ),
    ).then((result) {
      // Si se generó el plan exitosamente, recargar la lista
      // Si result es true, significa que se guardó el plan y la navegación al plan ya se hizo
      // Si result es null/false, significa que se volvió sin guardar
      if (result == true && mounted) {
        _cargarPacientes();
        // NO hacer pop aquí porque la navegación al plan ya se hizo desde PlanSugeridoScreen
        // El dashboard se actualizará cuando se vuelva a él
      } else if (mounted) {
        // Si se volvió sin guardar, retornar true para actualizar el dashboard
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Paciente'),
        backgroundColor: const Color(0xFF4CAF50),
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
                        onPressed: _cargarPacientes,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _pacientes.isEmpty
                  ? const Center(
                      child: Text('No hay pacientes disponibles'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pacientes.length,
                      itemBuilder: (context, index) {
                        final paciente = _pacientes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            title: Text(
                              paciente.nombreCompleto,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: paciente.dni != null
                                ? Text('DNI: ${paciente.dni}')
                                : null,
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => _seleccionarPaciente(paciente),
                          ),
                        );
                      },
                    ),
    );
  }
}

