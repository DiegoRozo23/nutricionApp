import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/usecases/obtener_pacientes_usecase.dart';
import '../../domain/usecases/eliminar_paciente_usecase.dart';
import '../../data/repositories/pacientes_repository_impl.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../../domain/entities/paciente.dart';
import '../widgets/paciente_card.dart';
import 'detalle_paciente_screen.dart';
import 'editar_paciente_screen.dart';
import 'crear_paciente_screen.dart';
import '../../../../shared/services/supabase_service.dart';

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
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _obtenerPacientesUseCase = ObtenerPacientesUseCase(_repository);
    _eliminarPacienteUseCase = EliminarPacienteUseCase(_repository);
    _cargarPacientes();
    _suscribirATiempoReal();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  /// Suscribirse a cambios en tiempo real de la tabla pacientes
  void _suscribirATiempoReal() {
    try {
      final supabase = supabaseService.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) return;

      // Obtener el nutricionista_id del usuario autenticado
      supabase
          .from('nutricionistas')
          .select('id')
          .eq('auth_uid', user.id)
          .single()
          .then((nutriData) {
        final nutricionistaId = nutriData['id'] as String;

        // Suscribirse a cambios en pacientes del nutricionista
        _channel = supabase
            .channel('pacientes_changes_${user.id}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'pacientes',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'nutricionista_id',
                value: nutricionistaId,
              ),
              callback: (payload) {
                if (mounted) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _cargarPacientes();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          _cargarPacientes();
                        }
                      });
                    }
                  });
                }
              },
            )
            .subscribe((status, [error]) {});
      }).catchError((error) {});
    } catch (e) {
      // Si falla la suscripción, continuar sin tiempo real
    }
  }

  Future<void> _cargarPacientes() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar que el usuario esté autenticado antes de intentar cargar
      final supabase = supabaseService.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión no válida. Por favor, inicia sesión nuevamente.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final result = await _obtenerPacientesUseCase();

      if (!mounted) return;

      if (result is PacientesSuccess<List<Paciente>>) {
        final nuevaLista = result.data;
        setState(() {
          _pacientes = nuevaLista;
          _isLoading = false;
        });
      } else if (result is PacientesFailure) {
        setState(() {
          _isLoading = false;
        });
        
        if (result.message.contains('Nutricionista no encontrado')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión expirada. Por favor, sal y vuelve a entrar.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pacientes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _navegarADetalle(Paciente paciente) async {
    // Verificar que el paciente tenga ID válido
    if (paciente.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Paciente sin ID válido. Por favor, recarga la lista.'),
          backgroundColor: Colors.orange,
        ),
      );
      await _cargarPacientes();
      return;
    }

    final resultado = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetallePacienteScreen(paciente: paciente),
      ),
    );

    // Si el detalle retornó true (se actualizó el paciente), cerrar esta pantalla también
    // para volver al dashboard
    if (mounted && resultado == true) {
      // Cerrar esta pantalla (lista) y volver al dashboard
      Navigator.of(context).pop();
    } else if (mounted) {
      // Si solo se vio el detalle, recargar la lista
      await Future.delayed(const Duration(milliseconds: 300));
      await _cargarPacientes();
    }
  }

  void _navegarAEditar(Paciente paciente) async {
    // Verificar que el paciente tenga ID válido
    if (paciente.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Paciente sin ID válido. Por favor, recarga la lista.'),
          backgroundColor: Colors.orange,
        ),
      );
      await _cargarPacientes();
      return;
    }

    final resultado = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditarPacienteScreen(paciente: paciente),
      ),
    );

    // Si se actualizó el paciente, cerrar esta pantalla y volver al dashboard
    if (mounted && resultado == true) {
      // Cerrar esta pantalla (lista) y volver al dashboard
      Navigator.of(context).pop();
    } else if (mounted) {
      // Si solo se editó sin actualizar, recargar la lista
      await Future.delayed(const Duration(milliseconds: 300));
      await _cargarPacientes();
    }
  }

  void _navegarACrear() async {
    final resultado = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CrearPacienteScreen(),
      ),
    );

    // Siempre recargar cuando volvamos, independientemente del resultado
    if (!mounted) return;

    // Recargar inmediatamente
    await _cargarPacientes();
    
    // Si se creó exitosamente, recargar varias veces para asegurar
    if (resultado == true) {
      // Primera recarga después de un pequeño delay
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        await _cargarPacientes();
      }
      
      // Segunda recarga después de otro delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _cargarPacientes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Pacientes${_pacientes.isNotEmpty ? ' (${_pacientes.length})' : ''}'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _cargarPacientes();
            },
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
                  child: Scrollbar(
                    thumbVisibility: true, // Siempre mostrar la barra cuando hay scroll
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      itemCount: _pacientes.length,
                      itemBuilder: (context, index) {
                        final paciente = _pacientes[index];
                        return PacienteCard(
                          paciente: paciente,
                          onTap: () => _navegarADetalle(paciente),
                          onEdit: () => _navegarAEditar(paciente),
                          onDelete: () => _eliminarPaciente(paciente),
                        );
                      },
                    ),
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

