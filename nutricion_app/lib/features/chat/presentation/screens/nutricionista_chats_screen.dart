import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/services/chat_notification_service.dart';
import '../../../../shared/models/chat_room.dart';
import '../../../pacientes/domain/entities/paciente.dart';
import '../../../pacientes/domain/usecases/obtener_pacientes_usecase.dart';
import '../../../pacientes/data/repositories/pacientes_repository_impl.dart';
import '../../../pacientes/domain/repositories/pacientes_repository.dart';
import 'chat_screen.dart';

/// Pantalla que muestra la lista de chats del nutricionista con sus pacientes
class NutricionistaChatsScreen extends StatefulWidget {
  const NutricionistaChatsScreen({super.key});

  @override
  State<NutricionistaChatsScreen> createState() => _NutricionistaChatsScreenState();
}

class _NutricionistaChatsScreenState extends State<NutricionistaChatsScreen> {
  final supabase = supabaseService.client;
  final PacientesRepository _pacientesRepository = PacientesRepositoryImpl();
  List<ChatRoom> _rooms = [];
  List<Paciente> _pacientes = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _cargandoPacientes = false;

  @override
  void initState() {
    super.initState();
    _loadNutricionistaChats();
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    if (_cargandoPacientes) return;
    
    setState(() {
      _cargandoPacientes = true;
    });

    try {
      final useCase = ObtenerPacientesUseCase(_pacientesRepository);
      final result = await useCase();

      if (result is PacientesSuccess<List<Paciente>>) {
        setState(() {
          _pacientes = result.data.where((p) => p.authUid != null && p.authUid!.isNotEmpty).toList();
          _cargandoPacientes = false;
        });
      } else {
        setState(() {
          _cargandoPacientes = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NUTRICIONISTA_CHATS] Error al cargar pacientes: $e');
      }
      setState(() {
        _cargandoPacientes = false;
      });
    }
  }

  Future<void> _iniciarChatConPaciente(Paciente paciente) async {
    if (paciente.authUid == null || paciente.authUid!.isEmpty) {
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      if (kDebugMode) {
        print('[NUTRICIONISTA_CHATS] Iniciando chat con paciente: ${paciente.authUid}');
      }

      final room = await chatService.createOrGetDirectRoom(paciente.authUid!);

      if (kDebugMode) {
        print('[NUTRICIONISTA_CHATS] ✅ Room obtenido/creado: ${room.id}');
      }

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Marcar room como leído antes de navegar
      await chatNotificationService.markRoomAsRead(room.id);

      // Navegar a la pantalla de chat
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(room: room),
        ),
      );

      // Recargar chats al volver
      _loadNutricionistaChats();
      chatNotificationService.loadUnreadCount();
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

  Future<void> _loadNutricionistaChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtener el nutricionista actual
      final nutriResponse = await supabase
          .from('nutricionistas')
          .select('id, auth_uid')
          .eq('auth_uid', currentUser.id)
          .maybeSingle();

      if (nutriResponse == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se encontró el nutricionista.';
        });
        return;
      }

      final nutricionistaId = nutriResponse['id'] as String;
      final nutricionistaAuthUid = (nutriResponse['auth_uid'] as String?) ?? currentUser.id;

      // Obtener todos los pacientes del nutricionista
      final pacientesResponse = await supabase
          .from('pacientes')
          .select('id, auth_uid, nombre, apellidos')
          .eq('nutricionista_id', nutricionistaId)
          .eq('activo', true);

      if (pacientesResponse == null || (pacientesResponse as List).isEmpty) {
        setState(() {
          _rooms = [];
          _isLoading = false;
        });
        return;
      }

      final pacientes = pacientesResponse as List;
      final pacientesAuthUids = pacientes
          .where((p) => (p as Map<String, dynamic>)['auth_uid'] != null)
          .map((p) => (p as Map<String, dynamic>)['auth_uid'].toString())
          .toList();

      if (pacientesAuthUids.isEmpty) {
        setState(() {
          _rooms = [];
          _isLoading = false;
        });
        return;
      }

      // Buscar rooms que contengan el auth_uid del nutricionista y algún paciente
      // Usar el schema chats correctamente
      if (kDebugMode) {
        print('[NUTRICIONISTA_CHATS] Buscando rooms para nutricionista: $nutricionistaAuthUid');
        print('[NUTRICIONISTA_CHATS] Pacientes auth_uids: $pacientesAuthUids');
      }

      final roomsResponse = await supabase
          .schema('chats')
          .from('rooms')
          .select()
          .eq('type', 'direct');

      if (kDebugMode) {
        print('[NUTRICIONISTA_CHATS] Rooms encontrados: ${roomsResponse != null ? (roomsResponse as List).length : 0}');
      }

      if (roomsResponse == null) {
        setState(() {
          _rooms = [];
          _isLoading = false;
        });
        return;
      }

      final allRooms = roomsResponse as List;
      final filteredRooms = <Map<String, dynamic>>[];

      for (final roomData in allRooms) {
        final room = roomData as Map<String, dynamic>;
        final userIds = (room['userIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        // Verificar si el room contiene al nutricionista y algún paciente
        if (kDebugMode) {
          print('[NUTRICIONISTA_CHATS] Room ${room['id']} tiene userIds: $userIds');
        }

        if (userIds.contains(nutricionistaAuthUid)) {
          final tienePaciente = userIds.any((uid) => pacientesAuthUids.contains(uid));
          if (kDebugMode) {
            print('[NUTRICIONISTA_CHATS] Room ${room['id']} contiene nutricionista: true, contiene paciente: $tienePaciente');
          }
          if (tienePaciente) {
            // Obtener información del paciente para el nombre del room
            final pacienteIdEnRoom = userIds.firstWhere(
              (uid) => pacientesAuthUids.contains(uid),
              orElse: () => '',
            );

            if (pacienteIdEnRoom.isNotEmpty) {
              try {
                final pacienteInfo = pacientes.firstWhere(
                  (p) => (p as Map<String, dynamic>)['auth_uid'] == pacienteIdEnRoom,
                );

                final pacienteMap = pacienteInfo as Map<String, dynamic>;
                final nombreCompleto = '${pacienteMap['nombre'] ?? ''} ${pacienteMap['apellidos'] ?? ''}'.trim();
                if (nombreCompleto.isNotEmpty) {
                  room['name'] = nombreCompleto;
                }
              } catch (e) {
                if (kDebugMode) {
                  print('[NUTRICIONISTA_CHATS] Error al obtener nombre del paciente: $e');
                }
              }
            }

            filteredRooms.add(room);
          }
        }
      }

      // Ordenar por última actividad (updatedAt o last_message_at)
      filteredRooms.sort((a, b) {
        final aTime = a['updatedAt'] as int? ?? 0;
        final bTime = b['updatedAt'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      // Convertir los rooms filtrados a ChatRoom
      final roomsConvertidos = filteredRooms
          .map((roomData) => chatService.jsonToRoom(roomData))
          .toList();

      if (kDebugMode) {
        print('[NUTRICIONISTA_CHATS] ✅ Rooms finales: ${roomsConvertidos.length}');
      }

      setState(() {
        _rooms = roomsConvertidos;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar chats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _mostrarDialogoPacientes() async {
    // Filtrar pacientes que no tienen chat activo
    final pacientesSinChat = _pacientes
        .where((p) => !_rooms.any(
            (room) => room.userIds.contains(p.authUid)))
        .toList();

    if (pacientesSinChat.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tienes chats con todos tus pacientes'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar nuevo chat'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pacientesSinChat.length,
            itemBuilder: (context, index) {
              final paciente = pacientesSinChat[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF4CAF50),
                  child: Text(
                    paciente.nombreCompleto.isNotEmpty
                        ? paciente.nombreCompleto[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  paciente.nombreCompleto.isNotEmpty
                      ? paciente.nombreCompleto
                      : 'Paciente',
                ),
                subtitle: paciente.dni != null ? Text('DNI: ${paciente.dni}') : null,
                onTap: () {
                  Navigator.pop(context);
                  _iniciarChatConPaciente(paciente);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats con Pacientes'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNutricionistaChats,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: _pacientes.isNotEmpty
          ? FloatingActionButton(
              onPressed: _mostrarDialogoPacientes,
              backgroundColor: const Color(0xFF4CAF50),
              child: const Icon(Icons.add),
              tooltip: 'Nuevo chat',
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? RefreshIndicator(
                  onRefresh: () async {
                    await _loadNutricionistaChats();
                    await _cargarPacientes();
                  },
                  child: CustomScrollView(
                    slivers: [
                      // Header con mensaje
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes chats activos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selecciona un paciente para iniciar una conversación',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Lista de pacientes
                      if (_cargandoPacientes)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else if (_pacientes.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No tienes pacientes aún',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final paciente = _pacientes[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    child: Text(
                                      paciente.nombreCompleto.isNotEmpty
                                          ? paciente.nombreCompleto[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    paciente.nombreCompleto.isNotEmpty
                                        ? paciente.nombreCompleto
                                        : 'Paciente',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: paciente.dni != null
                                      ? Text('DNI: ${paciente.dni}')
                                      : null,
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => _iniciarChatConPaciente(paciente),
                                ),
                              );
                            },
                            childCount: _pacientes.length,
                          ),
                        ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNutricionistaChats,
                  child: ListView.builder(
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];

                      return _ChatListItem(
                        room: room,
                        onTap: () async {
                          // Marcar room como leído antes de abrir
                          await chatNotificationService.markRoomAsRead(room.id);
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(room: room),
                            ),
                          ).then((_) {
                            // Recargar al volver para ver mensajes actualizados
                            _loadNutricionistaChats();
                            chatNotificationService.loadUnreadCount();
                          });
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: chatNotificationService.getUnreadCountStream(room.id),
      initialData: chatNotificationService.getUnreadCount(room.id),
      builder: (context, snapshot) {
        final roomUnread = snapshot.data ?? 0;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF4CAF50),
            child: Text(
              room.name?.isNotEmpty == true ? room.name![0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            room.name ?? 'Sin nombre',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Toca para chatear'),
          trailing: roomUnread > 0
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    roomUnread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        );
      },
    );
  }

}

