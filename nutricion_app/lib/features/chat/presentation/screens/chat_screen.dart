import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/chat_notification_service.dart';
import '../../../../shared/models/chat_room.dart';

/// Pantalla de chat individual entre dos usuarios usando flutter_chat_ui 2.9.1
class ChatScreen extends StatefulWidget {
  final ChatRoom room;

  const ChatScreen({
    super.key,
    required this.room,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final InMemoryChatController _chatController;
  final supabase = supabaseService.client;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _userStatusSubscription;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _typingChannel;
  RealtimeChannel? _userStatusChannel;
  String? _currentUserId;
  String? _otherUserId;
  bool _otherUserIsTyping = false;
  bool _otherUserIsOnline = false;
  DateTime? _otherUserLastSeen;
  Timer? _typingTimer;
  Timer? _statusUpdateTimer;
  Timer? _typingDebounceTimer;
  bool _userIsTyping = false;
  // Mapa para almacenar estados de mensajes (id -> {read: bool, readBy: List})
  final Map<String, Map<String, dynamic>> _messageStates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    // Marcar room como leído cuando se abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatNotificationService.markRoomAsRead(widget.room.id);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_currentUserId == null) return;
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App vuelve a primer plano - marcar como online
        _updateUserOnlineStatus(true);
        _startStatusUpdateTimer();
        if (kDebugMode) {
          print('[CHAT] App resumed - marcando usuario como online');
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App va a background - marcar como offline
        _updateUserOnlineStatus(false);
        _statusUpdateTimer?.cancel();
        if (kDebugMode) {
          print('[CHAT] App paused/inactive - marcando usuario como offline');
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _updateUserOnlineStatus(false);
        break;
    }
  }

  Future<void> _initializeChat() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      _currentUserId = user.id;

      // Obtener el ID del otro usuario del room
      _otherUserId = widget.room.userIds.firstWhere(
        (id) => id != _currentUserId,
        orElse: () => '',
      );

      // Crear controlador en memoria
      _chatController = InMemoryChatController();

      // Cargar mensajes iniciales
      await _loadInitialMessages();

      // Marcar mensajes como leídos
      await _markMessagesAsRead();

      if (kDebugMode) {
        print('[CHAT_SCREEN] ✅ initState completado para room ${widget.room.id}');
      }

      // Suscribirse a mensajes nuevos
      _subscribeToMessages();

      // Suscribirse a estado de escritura
      _subscribeToTypingStatus();

      // Suscribirse a estado del usuario
      _subscribeToUserStatus();

      // Actualizar estado online del usuario actual
      await _updateUserOnlineStatus(true);

      // Actualizar estado periódicamente mientras el chat está abierto
      _startStatusUpdateTimer();

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadInitialMessages() async {
    try {
      final response = await supabase
          .schema('chats')
          .from('messages')
          .select()
          .eq('roomId', widget.room.id)
          .order('createdAt', ascending: false);

      if (response != null) {
        final messages = <TextMessage>[];
        for (final json in response as List) {
          final message = _jsonToMessage(json as Map<String, dynamic>);
          if (message != null) {
            messages.add(message);
          }
        }
        // Insertar en orden inverso para que los más antiguos estén arriba y los recientes abajo
        for (final message in messages.reversed) {
          _chatController.insertMessage(message);
        }
      }
    } catch (e) {
      // Ignorar error
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      if (_currentUserId == null) return;

      if (kDebugMode) {
        print('[CHAT_SCREEN] Marcando mensajes como leídos para room ${widget.room.id}');
      }

      // Obtener mensajes no leídos del otro usuario
      final messages = await supabase
          .schema('chats')
          .from('messages')
          .select('id, authorId, read_by')
          .eq('roomId', widget.room.id)
          .neq('authorId', _currentUserId!);

      if (messages != null && (messages as List).isNotEmpty) {
        // Filtrar solo los que no están leídos
        final unreadMessages = (messages as List).where((msg) {
          final msgMap = msg as Map<String, dynamic>;
          final read = msgMap['read'] as bool? ?? false;
          final readBy = (msgMap['read_by'] as List?) ?? [];
          return !read || !readBy.contains(_currentUserId);
        }).toList();

        if (unreadMessages.isNotEmpty) {
          if (kDebugMode) {
            print('[CHAT_SCREEN] Encontrados ${unreadMessages.length} mensajes sin leer');
          }
          
          int updatedCount = 0;
          for (final msg in unreadMessages) {
            final msgId = msg['id'] as String?;
            if (msgId != null) {
              try {
                final readBy = (msg['read_by'] as List?) ?? [];
                final updatedReadBy = readBy.contains(_currentUserId) 
                    ? readBy 
                    : [...readBy, _currentUserId!];
                
                await supabase
                    .schema('chats')
                    .from('messages')
                    .update({
                      'read': true,
                      'read_by': updatedReadBy,
                    })
                    .eq('id', msgId);
                
                updatedCount++;
                
                if (kDebugMode) {
                  print('[CHAT_SCREEN] ✅ Mensaje $msgId marcado como leído');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('[CHAT_SCREEN] ❌ Error marcando mensaje $msgId: $e');
                }
              }
            }
          }

          if (kDebugMode) {
            print('[CHAT_SCREEN] ✅ $updatedCount mensajes marcados como leídos');
          }

          // Notificar al servicio de notificaciones para actualizar el contador
          await chatNotificationService.markRoomAsRead(widget.room.id);
        } else {
          if (kDebugMode) {
            print('[CHAT_SCREEN] No hay mensajes sin leer');
          }
        }
      } else {
        if (kDebugMode) {
          print('[CHAT_SCREEN] No hay mensajes sin leer');
        }
        // Aun así, actualizar el contador por si acaso
        await chatNotificationService.markRoomAsRead(widget.room.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_SCREEN] ❌ Error en _markMessagesAsRead: $e');
      }
      // Intentar actualizar el contador de todos modos
      try {
        await chatNotificationService.markRoomAsRead(widget.room.id);
      } catch (_) {}
    }
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();
    
    // Suscribirse a cambios de mensajes usando RealtimeChannel para mejor control
    final channel = supabase
        .channel('messages_${widget.room.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'chats',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'roomId',
            value: widget.room.id,
          ),
          callback: (payload) {
            if (!mounted) return;
            
            if (kDebugMode) {
              print('[CHAT] Payload recibido - Event: ${payload.eventType}, NewRecord: ${payload.newRecord != null}, OldRecord: ${payload.oldRecord != null}');
            }
            
            // Para INSERT y UPDATE, usar newRecord. Para DELETE, usar oldRecord
            Map<String, dynamic>? jsonMap;
            if (payload.newRecord != null) {
              jsonMap = payload.newRecord as Map<String, dynamic>;
            } else if (payload.oldRecord != null && payload.eventType == PostgresChangeEvent.delete) {
              // Solo procesar DELETE si es necesario (eliminar mensaje de la UI)
              jsonMap = payload.oldRecord as Map<String, dynamic>;
              final messageId = jsonMap['id'] as String? ?? '';
              if (messageId.isNotEmpty) {
                final existingIndex = _chatController.messages.indexWhere((m) => m.id == messageId);
                if (existingIndex >= 0) {
                  final msgToRemove = _chatController.messages[existingIndex];
                  _chatController.removeMessage(msgToRemove);
                  _messageStates.remove(messageId);
                  if (mounted) setState(() {});
                }
              }
              return;
            } else {
              if (kDebugMode) print('[CHAT] Payload sin newRecord ni oldRecord válido');
              return;
            }
            
            if (jsonMap == null) return;
            
            final messageId = jsonMap['id'] as String? ?? '';
            final read = jsonMap['read'] as bool? ?? false;
            final readBy = (jsonMap['read_by'] as List?) ?? [];
            final authorId = jsonMap['authorId'] as String? ?? '';
            
            if (messageId.isEmpty) {
              if (kDebugMode) print('[CHAT] Mensaje sin ID, ignorando');
              return;
            }
            
            if (kDebugMode) {
              print('[CHAT] Procesando mensaje: $messageId, autor: $authorId, texto: ${jsonMap['text']}');
            }
            
            // Verificar si ya existe un mensaje con este ID
            final existingMessageIndex = _chatController.messages.indexWhere((m) => m.id == messageId);
            
            if (existingMessageIndex >= 0) {
              // Mensaje YA EXISTE - verificar si cambió el estado de lectura
              
              final currentState = _messageStates[messageId];
              final oldRead = currentState?['read'] as bool? ?? false;
              
              // Solo actualizar el estado si cambió
              if (oldRead != read) {
                if (kDebugMode) {
                  print('[CHAT] Estado de lectura cambió para mensaje existente $messageId: $oldRead → $read');
                }
                
                // Actualizar _messageStates - el customMessageBuilder leerá de aquí
                _messageStates[messageId] = {
                  'read': read,
                  'readBy': readBy,
                  'authorId': authorId,
                };
                
                // Solo refrescar la UI, NO tocar el controlador
                if (mounted) setState(() {});
                
                if (kDebugMode) {
                  print('[CHAT] ✅ Estado actualizado en _messageStates');
                }
              }
              
            } else {
              // Mensaje NUEVO - crear y agregar al controlador
              if (kDebugMode) print('[CHAT] Mensaje nuevo detectado, agregando al chat');
              
              // Crear mensaje (que también actualiza _messageStates)
              final message = _jsonToMessage(jsonMap);
              if (message == null) {
                if (kDebugMode) print('[CHAT] No se pudo convertir mensaje a TextMessage');
                return;
              }
              
              _chatController.insertMessage(message);
              
              // Si es un mensaje del otro usuario, marcarlo como leído
              if (authorId != _currentUserId && authorId.isNotEmpty) {
                _markMessageAsRead(message.id);
                if (kDebugMode) print('[CHAT] Mensaje del otro usuario marcado como leído');
              } else {
                if (kDebugMode) print('[CHAT] Mensaje propio agregado');
              }
              
              if (mounted) setState(() {});
            }
          },
        )
        .subscribe((status, [error]) {
          if (kDebugMode) {
            print('[CHAT] Estado de suscripción: $status');
            if (error != null) {
              print('[CHAT] Error en suscripción: $error');
            }
          }
          
          if (status == RealtimeSubscribeStatus.subscribed && mounted) {
            if (kDebugMode) {
              print('[CHAT] ✅ Suscrito exitosamente a mensajes en tiempo real para room: ${widget.room.id}');
            }
          } else if (status == RealtimeSubscribeStatus.timedOut || 
                     status == RealtimeSubscribeStatus.channelError ||
                     (error != null)) {
            if (kDebugMode) {
              print('[CHAT] ❌ Error en suscripción (status: $status), reintentando...');
            }
            // Reintentar suscripción después de un breve delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _subscribeToMessages();
              }
            });
          }
        });
    
    // Guardar referencia del channel para poder cancelarlo después
    _messagesChannel = channel;
  }

  // REMOVIDO: La actualización de estado ahora se maneja en _subscribeToMessages()
  // para evitar duplicación y problemas de orden

  Future<void> _markMessageAsRead(String messageId) async {
    try {
      if (_currentUserId == null) return;

      final message = await supabase
          .schema('chats')
          .from('messages')
          .select('read_by, authorId, read, roomId')
          .eq('id', messageId)
          .maybeSingle();

      if (message != null && message['authorId'] != _currentUserId) {
        final read = message['read'] as bool? ?? false;
        final readBy = (message['read_by'] as List?) ?? [];
        
        if (!read || !readBy.contains(_currentUserId)) {
          final updatedReadBy = readBy.contains(_currentUserId) 
              ? readBy 
              : [...readBy, _currentUserId!];
          
          await supabase
              .schema('chats')
              .from('messages')
              .update({
                'read': true,
                'read_by': updatedReadBy,
              })
              .eq('id', messageId);
          
          // Actualizar estado local
          final state = _messageStates[messageId];
          if (state != null) {
            _messageStates[messageId] = {
              ...state,
              'read': true,
              'readBy': updatedReadBy,
            };
            if (mounted) {
              setState(() {});
            }
          }

          // El contador se actualizará automáticamente cuando se recargue periódicamente
          // o cuando se llame a markRoomAsRead desde _markMessagesAsRead
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_SCREEN] ❌ Error en _markMessageAsRead: $e');
      }
    }
  }

  void _subscribeToTypingStatus() {
    _typingSubscription?.cancel();

    if (_currentUserId == null || _otherUserId == null || _otherUserId!.isEmpty) return;

    final channel = supabase
        .channel('typing_${widget.room.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'chats',
          table: 'typing_status',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: widget.room.id,
          ),
          callback: (payload) {
            if (!mounted) return;
            
            final jsonMap = (payload.newRecord ?? payload.oldRecord) as Map<String, dynamic>?;
            if (jsonMap == null) return;
            
            final userId = jsonMap['user_id'] as String? ?? '';
            if (userId != _otherUserId) return;
            
            final isTyping = jsonMap['is_typing'] as bool? ?? false;
            setState(() {
              _otherUserIsTyping = isTyping;
            });
          },
        )
        .subscribe();
    
    // Guardar channel
    _typingChannel = channel;
    _typingSubscription = StreamController<void>().stream.listen((_) {});
    if (kDebugMode) {
      print('[CHAT] Suscrito a typing status para room: ${widget.room.id}');
    }
  }

  void _subscribeToUserStatus() {
    _userStatusSubscription?.cancel();

    if (_otherUserId == null || _otherUserId!.isEmpty) return;

    final otherUserId = _otherUserId!; // Guardar en variable local para evitar problemas de null safety

    // Cargar estado inicial
    supabase
        .schema('chats')
        .from('user_status')
        .select()
        .eq('user_id', otherUserId)
        .maybeSingle()
        .then((status) async {
          if (status != null && mounted) {
            if (kDebugMode) {
              print('[CHAT_SCREEN] Estado inicial del usuario: $status');
            }
            setState(() {
              _otherUserIsOnline = status['is_online'] as bool? ?? false;
              // Intentar obtener last_seen_at de diferentes formas posibles
              dynamic lastSeenValue = status['last_seen_at'];
              if (lastSeenValue != null) {
                try {
                  if (lastSeenValue is String) {
                    _otherUserLastSeen = DateTime.parse(lastSeenValue).toLocal();
                  } else if (lastSeenValue is DateTime) {
                    _otherUserLastSeen = lastSeenValue.toLocal();
                  }
                  if (kDebugMode) {
                    print('[CHAT_SCREEN] Última vez activo: $_otherUserLastSeen');
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('[CHAT_SCREEN] Error al parsear last_seen_at: $e, valor: $lastSeenValue');
                  }
                  _otherUserLastSeen = null;
                }
              } else {
                if (kDebugMode) {
                  print('[CHAT_SCREEN] last_seen_at es null');
                }
                _otherUserLastSeen = null;
              }
            });
          } else {
            // Si no hay registro en user_status, intentar obtener del último mensaje
            if (mounted && kDebugMode) {
              print('[CHAT_SCREEN] No hay registro en user_status, intentando obtener del último mensaje');
            }
            try {
              final lastMessage = await supabase
                  .schema('chats')
                  .from('messages')
                  .select('createdAt')
                  .eq('roomId', widget.room.id)
                  .eq('authorId', otherUserId)
                  .order('createdAt', ascending: false)
                  .limit(1)
                  .maybeSingle();
              
              if (lastMessage != null && mounted) {
                final createdAt = lastMessage['createdAt'] as int?;
                if (createdAt != null) {
                  setState(() {
                    _otherUserLastSeen = DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true).toLocal();
                    _otherUserIsOnline = false;
                    if (kDebugMode) {
                      print('[CHAT_SCREEN] Última vez desde último mensaje: $_otherUserLastSeen');
                    }
                  });
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('[CHAT_SCREEN] Error al obtener último mensaje: $e');
              }
            }
          }
        }).catchError((e) {
          if (kDebugMode) {
            print('[CHAT_SCREEN] Error al cargar estado inicial: $e');
          }
        });

    // Suscribirse a cambios de estado del usuario usando RealtimeChannel
    final channel = supabase
        .channel('user_status_$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'chats',
          table: 'user_status',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: otherUserId,
          ),
          callback: (payload) {
            if (!mounted) return;
            
            final jsonMap = (payload.newRecord ?? payload.oldRecord) as Map<String, dynamic>?;
            if (jsonMap == null) return;
            
            if (kDebugMode) {
              print('[CHAT_SCREEN] Actualización estado usuario: $jsonMap');
            }
            setState(() {
              _otherUserIsOnline = jsonMap['is_online'] as bool? ?? false;
              // Intentar obtener last_seen_at de diferentes formas posibles
              dynamic lastSeenValue = jsonMap['last_seen_at'];
              if (lastSeenValue != null) {
                try {
                  if (lastSeenValue is String) {
                    _otherUserLastSeen = DateTime.parse(lastSeenValue).toLocal();
                  } else if (lastSeenValue is DateTime) {
                    _otherUserLastSeen = lastSeenValue.toLocal();
                  }
                  if (kDebugMode) {
                    print('[CHAT_SCREEN] Última vez actualizada: $_otherUserLastSeen');
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('[CHAT_SCREEN] Error al parsear last_seen_at: $e, valor: $lastSeenValue');
                  }
                  _otherUserLastSeen = null;
                }
              } else {
                _otherUserLastSeen = null;
              }
            });
          },
        )
        .subscribe();
    
    // Guardar channel
    _userStatusChannel = channel;
    _userStatusSubscription = StreamController<void>().stream.listen((_) {});
    if (kDebugMode) {
      print('[CHAT] Suscrito a user status para usuario: $otherUserId');
    }
  }

  Future<void> _updateUserOnlineStatus(bool isOnline) async {
    try {
      if (_currentUserId == null) return;

      final now = DateTime.now().toUtc().toIso8601String();
      
      await supabase.schema('chats').from('user_status').upsert({
        'user_id': _currentUserId!,
        'is_online': isOnline,
        'last_seen_at': now,
      });

      if (kDebugMode) {
        print('[CHAT] Estado actualizado: ${isOnline ? "online" : "offline"} at $now');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT] Error actualizando estado: $e');
      }
    }
  }

  /// Iniciar timer para actualizar estado periódicamente
  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    // Actualizar estado cada 10 segundos mientras el chat está abierto (más frecuente)
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_currentUserId != null && mounted) {
        _updateUserOnlineStatus(true);
      }
    });
  }

  /// Notificar que el usuario está escribiendo (con debounce)
  /// Esta función puede ser llamada cuando detectamos actividad de escritura
  void _notifyTyping() {
    if (_currentUserId == null) return;
    
    // Si ya está escribiendo, reiniciar el timer
    if (_userIsTyping) {
      _typingTimer?.cancel();
      // Reiniciar timer de 3 segundos
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _stopTyping();
      });
    } else {
      // Si no está escribiendo, iniciar el estado
      _handleTyping();
    }
  }

  void _handleTyping() {
    try {
      if (_currentUserId == null || _userIsTyping) return;

      _typingTimer?.cancel();
      _userIsTyping = true;

      // Actualizar estado de escritura
      supabase.schema('chats').from('typing_status').upsert({
        'room_id': widget.room.id,
        'user_id': _currentUserId!,
        'is_typing': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).then((_) {}).catchError((_) {});

      // Auto-detener después de 3 segundos sin escribir
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _stopTyping();
      });
    } catch (e) {
      // Ignorar error
    }
  }

  void _stopTyping() {
    try {
      if (_currentUserId == null) return;

      _userIsTyping = false;
      _typingTimer?.cancel();
      _typingDebounceTimer?.cancel();

      supabase.schema('chats').from('typing_status').upsert({
        'room_id': widget.room.id,
        'user_id': _currentUserId!,
        'is_typing': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).then((_) {}).catchError((_) {});
    } catch (e) {
      // Ignorar error
    }
  }

  TextMessage? _jsonToMessage(Map<String, dynamic> json, {bool? forceRead}) {
    try {
      final authorId = json['authorId'] as String? ?? '';
      final text = json['text'] as String? ?? '';
      final createdAt = json['createdAt'] as int?;
      final id = json['id'] as String? ?? '';

      if (text.isEmpty || id.isEmpty || authorId.isEmpty) return null;

      // Almacenar estado del mensaje (SIN agregarlo al texto)
      final read = forceRead ?? (json['read'] as bool? ?? false);
      final readBy = (json['read_by'] as List?) ?? [];
      
      _messageStates[id] = {
        'read': read,
        'readBy': readBy,
        'authorId': authorId,
      };
      
      if (kDebugMode) {
        print('[CHAT] _jsonToMessage - id:$id, author:$authorId, current:$_currentUserId, isMine:${authorId == _currentUserId}, read:$read, text:$text');
      }
      
      // Retornar el mensaje SIN checkmarks - se agregarán en el builder personalizado
      return TextMessage(
        id: id,
        authorId: authorId,
        createdAt: createdAt != null
            ? DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true)
            : DateTime.now().toUtc(),
        text: text, // Texto PURO sin ✓
      );
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT] Error en _jsonToMessage: $e');
      }
      return null;
    }
  }

  String _getMessageStatus(String messageId) {
    final state = _messageStates[messageId];
    if (state == null) return 'Enviado';
    
    final authorId = state['authorId'] as String?;
    final read = state['read'] as bool? ?? false;
    
    // Solo mostrar estado para mensajes enviados por el usuario actual
    if (authorId != _currentUserId) return '';
    
    // Si read es true, significa que fue leído por el otro usuario
    return read ? 'Leído' : 'Enviado';
  }
  
  // Obtener el último mensaje enviado por el usuario actual
  TextMessage? _getLastSentMessage() {
    final userMessages = _chatController.messages
        .whereType<TextMessage>()
        .where((msg) => msg.authorId == _currentUserId)
        .toList();
    return userMessages.isNotEmpty ? userMessages.last : null;
  }

  Future<void> _handleMessageSend(String text) async {
    if (text.trim().isEmpty || _currentUserId == null) return;

    // Detener indicador de escritura
    _stopTyping();
    
    try {
      final now = DateTime.now().toUtc();

      // Insertar mensaje en Supabase directamente (sin mensaje optimista)
      await supabase.schema('chats').from('messages').insert({
        'roomId': widget.room.id,
        'authorId': _currentUserId!,
        'text': text,
        'message': {
          'text': text,
          'type': 'text',
        },
        'type': 'text',
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
        'status': 'sent',
        'read': false, // Nuevo mensaje no leído inicialmente
        'read_by': [],
      });

      // El mensaje aparecerá automáticamente cuando llegue por el stream INSERT

      // Actualizar last_message_at del room
      await supabase.schema('chats').from('rooms').update({
        'last_message_at': now.toIso8601String(),
        'updatedAt': now.millisecondsSinceEpoch,
      }).eq('id', widget.room.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) {
      if (kDebugMode) {
        print('[CHAT_SCREEN] _formatLastSeen: lastSeen es null');
      }
      return 'Inactivo';
    }
    
    if (kDebugMode) {
      print('[CHAT_SCREEN] _formatLastSeen: lastSeen = $lastSeen');
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Activo hace unos momentos';
    } else if (difference.inMinutes < 60) {
      return 'Activo hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Activo hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      return 'Activo hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else {
      // Mostrar fecha formateada
      final day = lastSeen.day;
      final month = lastSeen.month;
      final year = lastSeen.year;
      
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      
      if (year == now.year) {
        return 'Última vez: $day ${months[month - 1]}';
      } else {
        return 'Última vez: $day ${months[month - 1]} $year';
      }
    }
  }

  Future<User> _resolveUser(UserID id) async {
    try {
      // Intentar obtener usuario desde chats.users
      final userResponse = await supabase
          .schema('chats')
          .from('users')
          .select('firstName, lastName')
          .eq('id', id)
          .maybeSingle();

      if (userResponse != null) {
        final firstName = userResponse['firstName'] as String? ?? '';
        final lastName = userResponse['lastName'] as String? ?? '';
        return User(
          id: id,
          name: '$firstName $lastName'.trim().isNotEmpty 
              ? '$firstName $lastName'.trim() 
              : 'Usuario',
        );
      }
    } catch (e) {
      // Ignorar error
    }

    // Fallback: usar ID como nombre
    return User(id: id, name: 'Usuario');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messagesSubscription?.cancel();
    _messagesChannel?.unsubscribe();
    _typingSubscription?.cancel();
    _typingChannel?.unsubscribe();
    _userStatusSubscription?.cancel();
    _userStatusChannel?.unsubscribe();
    _typingTimer?.cancel();
    _typingDebounceTimer?.cancel();
    _statusUpdateTimer?.cancel();
    // Marcar usuario como offline
    _updateUserOnlineStatus(false);
    _stopTyping();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    widget.room.name?.isNotEmpty == true
                        ? widget.room.name![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Indicador de estado online
                if (_otherUserIsOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name ?? 'Chat',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Builder(
                    builder: (context) {
                      String statusText;
                      if (_otherUserIsTyping) {
                        statusText = 'Escribiendo...';
                      } else if (_otherUserIsOnline) {
                        statusText = 'Activo ahora';
                      } else {
                        statusText = _formatLastSeen(_otherUserLastSeen);
                        if (kDebugMode) {
                          print('[CHAT_SCREEN] Mostrando estado: $statusText (isOnline: $_otherUserIsOnline, lastSeen: $_otherUserLastSeen)');
                        }
                      }
                      return Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.white70,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: Stream.periodic(const Duration(milliseconds: 500), (_) => _messageStates),
              builder: (context, snapshot) {
                return Chat(
                  chatController: _chatController,
                  currentUserId: _currentUserId ?? '',
                  resolveUser: _resolveUser,
                  onMessageSend: (text) {
                    _stopTyping();
                    _handleMessageSend(text);
                  },
                  builders: Builders(
                    composerBuilder: (context) {
                      return Composer(
                        hintText: 'Escribe tu mensaje',
                        backgroundColor: Colors.white,
                      );
                    },
                    emptyChatListBuilder: (context) {
                      return EmptyChatList(
                        text: 'No hay mensajes aún',
                        textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                        padding: const EdgeInsets.only(bottom: 120),
                      );
                    },
                    textMessageBuilder: (context, textMessage, messageWidth, {groupStatus, isSentByMe = false}) {
                      // Builder personalizado para agregar checkmarks dinámicamente
                      final state = _messageStates[textMessage.id];
                      final read = state?['read'] as bool? ?? false;
                      
                      // Solo agregar checkmarks a mensajes propios
                      String displayText = textMessage.text;
                      if (textMessage.authorId == _currentUserId) {
                        final statusIcon = read ? ' ✓✓' : ' ✓';
                        displayText = '${textMessage.text}$statusIcon';
                      }
                      
                      final isMyMessage = textMessage.authorId == _currentUserId;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isMyMessage ? const Color(0xFF4CAF50) : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  displayText,
                                  style: TextStyle(
                                    color: isMyMessage ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Indicador de "escribiendo" del otro usuario
          if (_otherUserIsTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.room.name ?? "Usuario"} está escribiendo...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom Composer sin placeholder
class CustomComposer extends StatefulWidget {
  final void Function(String) onMessageSend;
  final String Function()? getText;
  final void Function(String)? setText;

  const CustomComposer({
    super.key,
    required this.onMessageSend,
    this.getText,
    this.setText,
  });

  @override
  State<CustomComposer> createState() => _CustomComposerState();
}

class _CustomComposerState extends State<CustomComposer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  widget.onMessageSend(text);
                  _controller.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final text = _controller.text;
              if (text.trim().isNotEmpty) {
                widget.onMessageSend(text);
                _controller.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
