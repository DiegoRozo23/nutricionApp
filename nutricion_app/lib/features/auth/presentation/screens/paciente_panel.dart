import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/services/chat_notification_service.dart';
import '../../../../shared/services/fcm_service.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../domain/entities/nutricionista.dart';
import '../../domain/entities/paciente.dart';
import 'role_selection_screen.dart';
import 'perfil_paciente_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PacientePanel extends StatefulWidget {
  const PacientePanel({super.key});

  @override
  State<PacientePanel> createState() => _PacientePanelState();
}

class _PacientePanelState extends State<PacientePanel> {
  late final LogoutUseCase _logoutUseCase;
  final AuthRepository _authRepository = AuthRepositoryImpl();
  
  Nutricionista? _nutricionista;
  Paciente? _paciente;
  bool _isLoadingNutricionista = true;

  @override
  void initState() {
    super.initState();
    _logoutUseCase = LogoutUseCase(_authRepository);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (kDebugMode) {
      print('[PACIENTE_PANEL] Iniciando _cargarDatos()');
    }
    
    // Obtener el paciente actual
    final paciente = await _authRepository.getCurrentPaciente();
    
    if (kDebugMode) {
      print('[PACIENTE_PANEL] Paciente obtenido: ${paciente?.id}');
      print('[PACIENTE_PANEL] nutricionistaId en paciente: ${paciente?.nutricionistaId}');
      print('[PACIENTE_PANEL] authUid del paciente: ${paciente?.authUid}');
    }
    
    if (!mounted) {
      if (kDebugMode) print('[PACIENTE_PANEL] Widget no montado, saliendo');
      return;
    }
    
    setState(() {
      _paciente = paciente;
    });

    // Usar función SQL primero (salta políticas RLS) si tenemos authUid
    if (paciente?.authUid != null && paciente!.authUid!.isNotEmpty) {
      if (kDebugMode) {
        print('[PACIENTE_PANEL] Intentando primero con función SQL (authUid: ${paciente.authUid})');
      }
      await _cargarNutricionistaConFuncionSQL(paciente.authUid!);
      
      // Si la función SQL no funcionó, intentar otros métodos
      if (_nutricionista == null) {
        if (kDebugMode) {
          print('[PACIENTE_PANEL] Función SQL falló, intentando métodos alternativos');
        }
        // Usar el nutricionista_id del paciente si está disponible
        if (paciente.nutricionistaId != null && paciente.nutricionistaId!.isNotEmpty) {
          if (kDebugMode) {
            print('[PACIENTE_PANEL] Usando nutricionistaId del paciente: ${paciente.nutricionistaId}');
          }
          await _cargarNutricionista(paciente.nutricionistaId!);
        } else {
          if (kDebugMode) {
            print('[PACIENTE_PANEL] nutricionistaId no disponible, intentando join');
          }
          // Si no está disponible, intentar obtenerlo directamente con join
          await _cargarNutricionistaConJoin();
        }
      }
    } else {
      // Si no hay authUid, usar el método tradicional
      if (paciente?.nutricionistaId != null && paciente!.nutricionistaId!.isNotEmpty) {
        if (kDebugMode) {
          print('[PACIENTE_PANEL] Usando nutricionistaId del paciente: ${paciente.nutricionistaId}');
        }
        await _cargarNutricionista(paciente.nutricionistaId!);
      } else {
        if (kDebugMode) {
          print('[PACIENTE_PANEL] nutricionistaId no disponible, intentando join');
        }
        await _cargarNutricionistaConJoin();
      }
    }
  }

  Future<void> _cargarNutricionistaConJoin() async {
    if (kDebugMode) {
      print('[PACIENTE_PANEL] Iniciando _cargarNutricionistaConJoin()');
    }
    
    try {
      final supabase = supabaseService.client;
      final user = supabase.auth.currentUser;
      
      if (kDebugMode) {
        print('[PACIENTE_PANEL] Auth user ID: ${user?.id}');
      }
      
      if (user == null) {
        if (kDebugMode) print('[PACIENTE_PANEL] No hay usuario autenticado');
        setState(() {
          _isLoadingNutricionista = false;
        });
        return;
      }

      // Intentar obtener nutricionista usando join (esto respeta políticas RLS)
      if (kDebugMode) {
        print('[PACIENTE_PANEL] Haciendo query con join: pacientes + nutricionistas');
      }
      
      final pacienteResponse = await supabase
          .from('pacientes')
          .select('nutricionista_id, nutricionistas(*)')
          .eq('auth_uid', user.id)
          .maybeSingle();
      
      if (kDebugMode) {
        print('[PACIENTE_PANEL] Respuesta del join: ${pacienteResponse != null ? "OK" : "NULL"}');
        if (pacienteResponse != null) {
          print('[PACIENTE_PANEL] Keys en respuesta join: ${pacienteResponse.keys.toList()}');
          print('[PACIENTE_PANEL] nutricionista_id en respuesta: ${pacienteResponse['nutricionista_id']}');
          print('[PACIENTE_PANEL] nutricionistas en respuesta (tipo): ${pacienteResponse['nutricionistas']?.runtimeType}');
          print('[PACIENTE_PANEL] nutricionistas en respuesta (valor): ${pacienteResponse['nutricionistas']}');
          if (pacienteResponse['nutricionistas'] != null) {
            if (pacienteResponse['nutricionistas'] is List) {
              print('[PACIENTE_PANEL] nutricionistas es una Lista con ${(pacienteResponse['nutricionistas'] as List).length} elementos');
            } else if (pacienteResponse['nutricionistas'] is Map) {
              print('[PACIENTE_PANEL] nutricionistas es un Map con keys: ${(pacienteResponse['nutricionistas'] as Map).keys.toList()}');
            }
          }
        }
      }
      
      if (pacienteResponse != null) {
        // Si el join trajo el nutricionista
        if (pacienteResponse['nutricionistas'] != null) {
          final nutriData = pacienteResponse['nutricionistas'] as Map<String, dynamic>;
          
          if (kDebugMode) {
            print('[PACIENTE_PANEL] ✅ Nutricionista obtenido del join: ${nutriData['nombre']} ${nutriData['apellidos']}');
          }
          
          setState(() {
            _nutricionista = Nutricionista(
              id: nutriData['id'] as String,
              authUid: nutriData['auth_uid'] as String,
              nombre: nutriData['nombre'] as String,
              apellidos: nutriData['apellidos'] as String,
              dni: nutriData['dni'] as String?,
              especialidad: nutriData['especialidad'] as String?,
              privilegio: nutriData['privilegio'] as String? ?? 'nutricionista',
              username: nutriData['username'] as String?,
              email: nutriData['email'] as String?,
              telefono: nutriData['telefono'] as String?,
              activo: nutriData['activo'] as bool? ?? true,
              createdAt: DateTime.parse(nutriData['created_at'] as String),
              updatedAt: DateTime.parse(nutriData['updated_at'] as String),
            );
            _isLoadingNutricionista = false;
          });
          return;
        }
        
        // Si el join no trajo nutricionista pero hay nutricionista_id, intentar consulta directa
        final nutricionistaId = pacienteResponse['nutricionista_id'] as String?;
        if (kDebugMode) {
          print('[PACIENTE_PANEL] Join no trajo nutricionista pero nutricionista_id existe: $nutricionistaId');
        }
        if (nutricionistaId != null && nutricionistaId.isNotEmpty) {
          await _cargarNutricionista(nutricionistaId);
          return;
        }
      }
      
      // Si el join falló completamente, intentar con función SQL
      if (user != null) {
        if (kDebugMode) {
          print('[PACIENTE_PANEL] Join falló, intentando función SQL');
        }
        await _cargarNutricionistaConFuncionSQL(user.id);
        return;
      }
      
      // Si llegamos aquí, no hay nutricionista
      if (kDebugMode) {
        print('[PACIENTE_PANEL] ❌ No se pudo obtener nutricionista con ningún método');
      }
      setState(() {
        _isLoadingNutricionista = false;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[PACIENTE_PANEL] ❌ Error en _cargarNutricionistaConJoin: $e');
        print('[PACIENTE_PANEL] StackTrace: $stackTrace');
      }
      setState(() {
        _isLoadingNutricionista = false;
      });
    }
  }

  Future<void> _cargarNutricionistaConFuncionSQL(String authUid) async {
    if (kDebugMode) {
      print('[PACIENTE_PANEL] Iniciando _cargarNutricionistaConFuncionSQL() con authUid: $authUid');
    }
    
    try {
      final supabase = supabaseService.client;
      
      // Llamar a la función SQL que devuelve el nutricionista sin restricciones RLS
      if (kDebugMode) {
        print('[PACIENTE_PANEL] Llamando función RPC: obtener_nutricionista_del_paciente');
      }
      
      final response = await supabase.rpc(
        'obtener_nutricionista_del_paciente',
        params: {'p_auth_uid': authUid},
      );
      
      if (kDebugMode) {
        print('[PACIENTE_PANEL] Respuesta RPC: ${response != null ? "OK" : "NULL"}');
        if (response != null) {
          print('[PACIENTE_PANEL] Tamaño respuesta: ${response.length}');
        }
      }
      
      if (response != null && response.isNotEmpty) {
        final nutriData = (response as List).first as Map<String, dynamic>;
        
        if (kDebugMode) {
          print('[PACIENTE_PANEL] ✅ Nutricionista obtenido de función SQL: ${nutriData['nombre']} ${nutriData['apellidos']}');
        }
        
        setState(() {
          _nutricionista = Nutricionista(
            id: nutriData['id'] as String,
            authUid: nutriData['auth_uid'] as String,
            nombre: nutriData['nombre'] as String,
            apellidos: nutriData['apellidos'] as String,
            dni: nutriData['dni'] as String?,
            especialidad: nutriData['especialidad'] as String?,
            privilegio: nutriData['privilegio'] as String? ?? 'nutricionista',
            username: nutriData['username'] as String?,
            email: nutriData['email'] as String?,
            telefono: nutriData['telefono'] as String?,
            activo: nutriData['activo'] as bool? ?? true,
            createdAt: DateTime.parse(nutriData['created_at'] as String),
            updatedAt: DateTime.parse(nutriData['updated_at'] as String),
          );
          _isLoadingNutricionista = false;
        });
      } else {
        if (kDebugMode) {
          print('[PACIENTE_PANEL] ❌ Función SQL no devolvió datos');
        }
        setState(() {
          _isLoadingNutricionista = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[PACIENTE_PANEL] ❌ Error en _cargarNutricionistaConFuncionSQL: $e');
        print('[PACIENTE_PANEL] StackTrace: $stackTrace');
      }
      setState(() {
        _isLoadingNutricionista = false;
      });
    }
  }

  Future<void> _cargarNutricionista(String nutricionistaId) async {
    if (kDebugMode) {
      print('[PACIENTE_PANEL] Iniciando _cargarNutricionista() con ID: $nutricionistaId');
    }
    
    try {
      final supabase = supabaseService.client;
      
      if (kDebugMode) {
        print('[PACIENTE_PANEL] Haciendo query directa a nutricionistas con ID: $nutricionistaId');
      }
      
      final nutriResponse = await supabase
          .from('nutricionistas')
          .select()
          .eq('id', nutricionistaId)
          .maybeSingle();

      if (kDebugMode) {
        print('[PACIENTE_PANEL] Respuesta query directa: ${nutriResponse != null ? "OK" : "NULL"}');
        if (nutriResponse != null) {
          print('[PACIENTE_PANEL] Datos nutricionista: ${nutriResponse['nombre']} ${nutriResponse['apellidos']}');
        }
      }

      if (nutriResponse != null && nutriResponse.isNotEmpty) {
        final nutriData = nutriResponse as Map<String, dynamic>;
        
        if (kDebugMode) {
          print('[PACIENTE_PANEL] ✅ Nutricionista obtenido de query directa');
        }
        
        setState(() {
          _nutricionista = Nutricionista(
            id: nutriData['id'] as String,
            authUid: nutriData['auth_uid'] as String,
            nombre: nutriData['nombre'] as String,
            apellidos: nutriData['apellidos'] as String,
            dni: nutriData['dni'] as String?,
            especialidad: nutriData['especialidad'] as String?,
            privilegio: nutriData['privilegio'] as String? ?? 'nutricionista',
            username: nutriData['username'] as String?,
            email: nutriData['email'] as String?,
            telefono: nutriData['telefono'] as String?,
            activo: nutriData['activo'] as bool? ?? true,
            createdAt: DateTime.parse(nutriData['created_at'] as String),
            updatedAt: DateTime.parse(nutriData['updated_at'] as String),
          );
          _isLoadingNutricionista = false;
        });
      } else {
        if (kDebugMode) {
          print('[PACIENTE_PANEL] Query directa falló, intentando join como fallback');
        }
        try {
          final pacienteResponse = await supabase
              .from('pacientes')
              .select('nutricionista_id, nutricionistas(*)')
              .eq('auth_uid', supabase.auth.currentUser?.id ?? '')
              .maybeSingle();
          
          if (kDebugMode) {
            print('[PACIENTE_PANEL] Respuesta join fallback: ${pacienteResponse != null ? "OK" : "NULL"}');
            if (pacienteResponse != null) {
              print('[PACIENTE_PANEL] Keys en respuesta: ${pacienteResponse.keys.toList()}');
              print('[PACIENTE_PANEL] nutricionista_id: ${pacienteResponse['nutricionista_id']}');
              print('[PACIENTE_PANEL] nutricionistas (tipo): ${pacienteResponse['nutricionistas']?.runtimeType}');
              print('[PACIENTE_PANEL] nutricionistas (valor): ${pacienteResponse['nutricionistas']}');
            }
          }
          
          if (pacienteResponse != null && pacienteResponse['nutricionistas'] != null) {
            final nutriData = pacienteResponse['nutricionistas'] as Map<String, dynamic>;
            
            if (kDebugMode) {
              print('[PACIENTE_PANEL] ✅ Nutricionista obtenido de join fallback');
            }
            
            setState(() {
              _nutricionista = Nutricionista(
                id: nutriData['id'] as String,
                authUid: nutriData['auth_uid'] as String,
                nombre: nutriData['nombre'] as String,
                apellidos: nutriData['apellidos'] as String,
                dni: nutriData['dni'] as String?,
                especialidad: nutriData['especialidad'] as String?,
                privilegio: nutriData['privilegio'] as String? ?? 'nutricionista',
                username: nutriData['username'] as String?,
                email: nutriData['email'] as String?,
                telefono: nutriData['telefono'] as String?,
                activo: nutriData['activo'] as bool? ?? true,
                createdAt: DateTime.parse(nutriData['created_at'] as String),
                updatedAt: DateTime.parse(nutriData['updated_at'] as String),
              );
              _isLoadingNutricionista = false;
            });
          } else {
            if (kDebugMode) {
              print('[PACIENTE_PANEL] ❌ Join fallback también falló');
            }
            setState(() {
              _isLoadingNutricionista = false;
            });
          }
        } catch (joinError, stackTrace) {
          if (kDebugMode) {
            print('[PACIENTE_PANEL] ❌ Error en join fallback: $joinError');
            print('[PACIENTE_PANEL] StackTrace: $stackTrace');
          }
          setState(() {
            _isLoadingNutricionista = false;
          });
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[PACIENTE_PANEL] ❌ Error en _cargarNutricionista: $e');
        print('[PACIENTE_PANEL] StackTrace: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _isLoadingNutricionista = false;
        });
      }
    }
  }

  Future<void> _abrirChatConNutricionista(BuildContext context) async {
    if (_nutricionista == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes nutricionista asignado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar que el nutricionista tenga auth_uid
    String? nutricionistaAuthUid = _nutricionista!.authUid;
    
    // Si no está disponible en el objeto, intentar obtenerlo desde la BD
    if (nutricionistaAuthUid == null || nutricionistaAuthUid.isEmpty) {
      if (kDebugMode) {
        print('[PACIENTE_PANEL] authUid no disponible en objeto, consultando BD...');
      }
      
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        nutricionistaAuthUid = await chatService.getNutricionistaAuthUid(
          _nutricionista!.id,
        );

        if (!mounted) return;
        Navigator.pop(context); // Cerrar loading

        if (nutricionistaAuthUid == null || nutricionistaAuthUid.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener la información del nutricionista'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Cerrar loading si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener información del nutricionista: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      // Mostrar loading para crear el room
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      if (kDebugMode) {
        print('[PACIENTE_PANEL] Iniciando chat con nutricionista: $nutricionistaAuthUid');
      }

      // Crear o obtener el room de chat
      final room = await chatService.createOrGetDirectRoom(
        nutricionistaAuthUid!,
        roomName: _nutricionista!.nombreCompleto,
      );

      if (kDebugMode) {
        print('[PACIENTE_PANEL] ✅ Room obtenido/creado: ${room.id}');
      }

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Marcar room como leído antes de navegar
      await chatNotificationService.markRoomAsRead(room.id);

      // Navegar a la pantalla de chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(room: room),
        ),
      ).then((_) async {
        // Recargar contador al volver (usar método público si existe, o simplemente reinicializar)
        await chatNotificationService.reinit();
      });
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
        title: const Text('Panel del Paciente'),
        backgroundColor: const Color(0xFF2196F3),
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
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2196F3).withOpacity(0.1),
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
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu plan nutricional personalizado',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Información del Nutricionista
                  const Text(
                    'Mi Nutricionista',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingNutricionista
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _nutricionista == null
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.person_off_outlined,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'No tienes nutricionista asignado',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
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
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.medical_services,
                                      color: Color(0xFF4CAF50),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _nutricionista!.nombreCompleto,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_nutricionista!.especialidad != null &&
                                            _nutricionista!.especialidad!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _nutricionista!.especialidad!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Nutricionista',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                        if (_nutricionista!.email != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _nutricionista!.email!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  const SizedBox(height: 24),

                  // Botón Chat con Nutricionista (PRIMERO)
                  if (_nutricionista != null)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () => _abrirChatConNutricionista(context),
                              icon: const Icon(Icons.chat, size: 24),
                              label: const Text(
                                'Chat con Nutricionista',
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
                                minimumSize: const Size(double.infinity, 56),
                              ),
                            ),
                          ),
                          StreamBuilder<int>(
                            stream: chatNotificationService.unreadCountStream,
                            initialData: chatNotificationService.unreadCount,
                            builder: (context, snapshot) {
                              // Usar la misma lógica que el badge verde: snapshot.data ?? initialData
                              final unreadCount = snapshot.data ?? chatNotificationService.unreadCount;
                              // Solo mostrar si hay mensajes sin leer (igual que el badge verde)
                              if (unreadCount <= 0) return const SizedBox.shrink();
                              return Positioned(
                                right: 8,
                                top: 8,
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
                                      unreadCount > 99 ? '99+' : unreadCount.toString(),
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
                          ),
                        ],
                      ),
                    ),

                  if (_nutricionista != null) const SizedBox(height: 16),

                  // Botón Ver Mi Perfil (PRIMERO)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PerfilPacienteScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person, size: 24),
                      label: const Text(
                        'Ver Mi Perfil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón Ver Plan Nutricional (DESPUÉS)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Próximamente'),
                            backgroundColor: Color(0xFF2196F3),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu, size: 24),
                      label: const Text(
                        'Ver Plan Nutricional',
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
                  const SizedBox(height: 24),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

