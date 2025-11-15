import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/chat_notification_service.dart';
import '../../../../shared/services/fcm_service.dart';
import '../../../pacientes/presentation/screens/lista_pacientes_screen.dart';
import '../../../pacientes/presentation/screens/crear_paciente_screen.dart';
import '../../../pacientes/presentation/screens/seleccionar_paciente_plan_screen.dart';
import '../../../pacientes/presentation/screens/metricas_evaluaciones_screen.dart';
import '../../../pacientes/domain/usecases/obtener_pacientes_usecase.dart';
import '../../../pacientes/data/repositories/pacientes_repository_impl.dart';
import '../../../pacientes/domain/repositories/pacientes_repository.dart';
import '../../../pacientes/domain/entities/paciente.dart';
import '../../../chat/presentation/screens/nutricionista_chats_screen.dart';
import '../../../../shared/services/planes_nutricionales_service.dart';
import 'role_selection_screen.dart';

class NutricionistaPanel extends StatefulWidget {
  const NutricionistaPanel({super.key});

  @override
  State<NutricionistaPanel> createState() => _NutricionistaPanelState();
}

class _NutricionistaPanelState extends State<NutricionistaPanel> with WidgetsBindingObserver {
  late final LogoutUseCase _logoutUseCase;
  final PacientesRepository _pacientesRepository = PacientesRepositoryImpl();
  final PlanesNutricionalesService _planesService = PlanesNutricionalesService();
  int _totalPacientes = 0;
  int _totalPlanes = 0;
  bool _isLoadingPacientes = true;
  bool _isLoadingPlanes = true;
  DateTime? _lastLoadTime;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _logoutUseCase = LogoutUseCase(AuthRepositoryImpl());
    WidgetsBinding.instance.addObserver(this);
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo recargar después de la carga inicial
    if (_isInitialLoad) {
      _isInitialLoad = false;
      return;
    }
    
    // Recargar estadísticas cada vez que se vuelve a esta pantalla
    // Usar addPostFrameCallback para asegurar que el contexto esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent) {
        final now = DateTime.now();
        // Solo recargar si ha pasado al menos 50ms desde la última carga
        // Reducido aún más para que se actualice inmediatamente cuando se vuelve desde otras pantallas
        if (_lastLoadTime == null || 
            now.difference(_lastLoadTime!).inMilliseconds >= 50) {
          if (kDebugMode) {
            print('[NUTRICIONISTA_PANEL] Recargando estadísticas - Ruta activa detectada en didChangeDependencies');
          }
          _cargarEstadisticas();
        } else {
          if (kDebugMode) {
            print('[NUTRICIONISTA_PANEL] Saltando recarga - muy reciente (${now.difference(_lastLoadTime!).inMilliseconds}ms)');
          }
        }
      } else {
        if (kDebugMode) {
          print('[NUTRICIONISTA_PANEL] Ruta no está activa - no recargando. Route: ${route?.settings.name}, isCurrent: ${route?.isCurrent}');
        }
      }
    });
  }

  @override
  void didUpdateWidget(NutricionistaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar cuando el widget se actualiza (por ejemplo, cuando se reemplaza con pushReplacement)
    if (kDebugMode) {
      print('[NUTRICIONISTA_PANEL] Widget actualizado - recargando estadísticas');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cargarEstadisticas();
      }
    });
  }

  // Método para forzar recarga desde fuera (útil cuando se vuelve desde otras pantallas)
  void recargarEstadisticas() {
    if (mounted) {
      _cargarEstadisticas();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Recargar estadísticas cuando la app vuelve al foreground
    if (state == AppLifecycleState.resumed && mounted) {
      _cargarEstadisticas();
    }
  }

  Future<void> _cargarEstadisticas() async {
    // Actualizar tiempo de última carga
    _lastLoadTime = DateTime.now();
    
    // Cargar pacientes y planes en paralelo para mejor rendimiento
    await Future.wait([
      _cargarPacientes(),
      _cargarPlanes(),
    ]);
  }

  Future<void> _cargarPacientes() async {
    try {
      final useCase = ObtenerPacientesUseCase(_pacientesRepository);
      final result = await useCase();

      if (!mounted) return;

      if (result is PacientesSuccess<List<Paciente>>) {
        setState(() {
          _totalPacientes = result.data.length;
          _isLoadingPacientes = false;
        });
      } else {
        setState(() {
          _isLoadingPacientes = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NUTRICIONISTA_PANEL] Error al cargar pacientes: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingPacientes = false;
        });
      }
    }
  }

  Future<void> _cargarPlanes() async {
    try {
      // Resetear estado de carga
      if (mounted) {
        setState(() {
          _isLoadingPlanes = true;
        });
      }

      final user = supabaseService.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _totalPlanes = 0;
            _isLoadingPlanes = false;
          });
        }
        return;
      }

      final nutriResponse = await supabaseService.client
          .from('nutricionistas')
          .select('id')
          .eq('auth_uid', user.id)
          .maybeSingle();

      if (nutriResponse == null) {
        if (mounted) {
          setState(() {
            _totalPlanes = 0;
            _isLoadingPlanes = false;
          });
        }
        if (kDebugMode) {
          print('[NUTRICIONISTA_PANEL] No se encontró nutricionista para el usuario: ${user.id}');
        }
        return;
      }

      final nutricionistaId = nutriResponse['id'] as String;
      
      if (kDebugMode) {
        print('[NUTRICIONISTA_PANEL] Cargando planes para nutricionista: $nutricionistaId');
      }
      
      // Obtener todos los planes del nutricionista
      final planesResponse = await supabaseService.client
          .from('planes_nutricionales')
          .select('id')
          .eq('nutricionista_id', nutricionistaId);

      // Verificar que la respuesta sea una lista
      int totalPlanes = 0;
      if (planesResponse != null) {
        if (planesResponse is List) {
          totalPlanes = planesResponse.length;
        } else {
          // Si no es una lista, intentar convertirla
          try {
            final lista = List.from(planesResponse);
            totalPlanes = lista.length;
          } catch (e) {
            if (kDebugMode) {
              print('[NUTRICIONISTA_PANEL] Error al convertir respuesta a lista: $e');
            }
            totalPlanes = 0;
          }
        }
      }

      if (kDebugMode) {
        print('[NUTRICIONISTA_PANEL] Planes obtenidos: $totalPlanes');
        print('[NUTRICIONISTA_PANEL] Tipo de respuesta: ${planesResponse.runtimeType}');
      }

      if (mounted) {
        setState(() {
          _totalPlanes = totalPlanes;
          _isLoadingPlanes = false;
        });
        if (kDebugMode) {
          print('[NUTRICIONISTA_PANEL] Estado actualizado: $_totalPlanes planes');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[NUTRICIONISTA_PANEL] Error al cargar planes nutricionales: $e');
        print('[NUTRICIONISTA_PANEL] Stack trace: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _totalPlanes = 0;
          _isLoadingPlanes = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // Limpiar token FCM antes de cerrar sesión
      try {
        await fcmService.unregisterUserToken();
      } catch (fcmError) {
        if (kDebugMode) {
          print('Error al limpiar token FCM: $fcmError');
        }
        // Continuar con el logout aunque falle
      }
      
      await _logoutUseCase();
      
      // Desactivar servicio de notificaciones
      chatNotificationService.dispose();
      
      if (!mounted) return;
      
      // Limpiar datos guardados localmente
      await storageService.remove('current_role');
      await storageService.remove('current_user_id');
      
      if (!mounted) return;
      
      // Navegar a la pantalla de selección de rol
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const RoleSelectionScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Nutricionista'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Bienvenido/a!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestión de pacientes y planes nutricionales',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Estadísticas
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Pacientes',
                        value: _isLoadingPacientes ? '-' : '$_totalPacientes',
                        icon: Icons.people_outline,
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ListaPacientesScreen(),
                            ),
                          ).then((_) {
                            // Recargar estadísticas cuando vuelva
                            _cargarEstadisticas();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Planes',
                        value: _isLoadingPlanes ? '-' : '$_totalPlanes',
                        icon: Icons.restaurant_menu,
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Acciones rápidas
                const Text(
                  'Acciones rápidas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _ActionCard(
                  title: 'Crear Paciente',
                  subtitle: 'Registrar nuevo paciente',
                  icon: Icons.person_add,
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CrearPacienteScreen(),
                      ),
                    ).then((_) {
                      // Recargar estadísticas cuando vuelva
                      _cargarEstadisticas();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Ver Pacientes',
                  subtitle: 'Lista de pacientes registrados',
                  icon: Icons.list,
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ListaPacientesScreen(),
                      ),
                    ).then((_) {
                      // Recargar estadísticas cuando vuelva
                      _cargarEstadisticas();
                    });
                  },
                ),
                const SizedBox(height: 12),

                _ActionCard(
                  title: 'Chats',
                  subtitle: 'Mensajes con pacientes',
                  icon: Icons.chat_bubble_outline,
                  color: const Color(0xFF9C27B0),
                  badgeStream: chatNotificationService.unreadCountStream,
                  initialBadgeCount: chatNotificationService.unreadCount,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NutricionistaChatsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                        _ActionCard(
                          title: 'Generar Plan',
                          subtitle: 'Crear plan nutricional',
                          icon: Icons.assignment_outlined,
                          color: const Color(0xFFFF9800),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SeleccionarPacientePlanScreen(),
                              ),
                            );
                            // Si se creó un plan o se volvió desde cualquier pantalla, recargar estadísticas
                            // Siempre recargar cuando se vuelve para asegurar que los datos estén actualizados
                            if (mounted) {
                              // Pequeño delay para asegurar que la navegación se completó
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) {
                                  _cargarEstadisticas();
                                }
                              });
                            }
                          },
                        ),
                const SizedBox(height: 12),

                _ActionCard(
                  title: 'Métricas y Reportes',
                  subtitle: 'Evaluaciones de modelos',
                  icon: Icons.assessment,
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MetricasEvaluacionesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;
  final Stream<int>? badgeStream;
  final int initialBadgeCount;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount,
    this.badgeStream,
    this.initialBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                // Badge estático o dinámico
                badgeStream != null
                    ? StreamBuilder<int>(
                        stream: badgeStream,
                        initialData: initialBadgeCount,
                        builder: (context, snapshot) {
                          // Usar la misma lógica que el badge verde: snapshot.data ?? initialData
                          final count = snapshot.data ?? initialBadgeCount;
                          // Solo mostrar si hay mensajes sin leer (igual que el badge verde)
                          if (count <= 0) return const SizedBox.shrink();
                          return Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  count > 99 ? '99+' : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : (badgeCount != null && badgeCount! > 0)
                        ? Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  badgeCount! > 99 ? '99+' : badgeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

