import 'package:flutter/material.dart';
import '../../domain/usecases/obtener_pacientes_usecase.dart';
import '../../domain/usecases/eliminar_paciente_usecase.dart';
import '../../data/repositories/pacientes_repository_impl.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../../domain/entities/paciente.dart';
import '../widgets/paciente_card.dart';
import 'detalle_paciente_screen.dart';
import 'crear_paciente_screen.dart';

/// Pantalla que muestra la lista de pacientes del nutricionista
class ListaPacientesScreen extends StatefulWidget {
  const ListaPacientesScreen({super.key});

  @override
  State<ListaPacientesScreen> createState() => _ListaPacientesScreenState();
}

class _ListaPacientesScreenState extends State<ListaPacientesScreen> {
  final PacientesRepository _repository = PacientesRepositoryImpl();
  late final ObtenerPacientesUseCase _obtenerPacientesUseCase;
  late final EliminarPacienteUseCase _eliminarPacienteUseCase;

  bool _isLoading = true;
  List<Paciente> _pacientes = [];

  @override
  void initState() {
    super.initState();
    _obtenerPacientesUseCase = ObtenerPacientesUseCase(_repository);
    _eliminarPacienteUseCase = EliminarPacienteUseCase(_repository);
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _obtenerPacientesUseCase();

    if (!mounted) return;

    if (result is PacientesSuccess<List<Paciente>>) {
      setState(() {
        _pacientes = result.data;
        _isLoading = false;
      });
    } else if (result is PacientesFailure) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarPaciente(Paciente paciente) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Paciente'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${paciente.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final result = await _eliminarPacienteUseCase(paciente.id);

    if (!mounted) return;

    if (result is PacientesSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarPacientes(); // Recargar lista
    } else if (result is PacientesFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navegarADetalle(Paciente paciente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetallePacienteScreen(paciente: paciente),
      ),
    ).then((_) {
      // Recargar lista cuando vuelva de detalle
      _cargarPacientes();
    });
  }

  void _navegarACrear() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CrearPacienteScreen(),
      ),
    ).then((_) {
      // Recargar lista cuando vuelva de crear
      _cargarPacientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pacientes'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPacientes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _pacientes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes pacientes registrados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primer paciente',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarPacientes,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _pacientes.length,
                    itemBuilder: (context, index) {
                      final paciente = _pacientes[index];
                      return Dismissible(
                        key: Key(paciente.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          await _eliminarPaciente(paciente);
                          return false; // Ya se maneja en _eliminarPaciente
                        },
                        child: PacienteCard(
                          paciente: paciente,
                          onTap: () => _navegarADetalle(paciente),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navegarACrear,
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Paciente'),
      ),
    );
  }
}

