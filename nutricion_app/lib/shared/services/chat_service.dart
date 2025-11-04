import 'package:flutter/foundation.dart';
import '../models/chat_room.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import 'supabase_service.dart';

/// Servicio para manejar la lógica del chat
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final AuthRepository _authRepository = AuthRepositoryImpl();
  bool _initialized = false;

  /// Inicializar el servicio de chat
  Future<void> init() async {
    if (_initialized) {
      if (kDebugMode) {
        print('ChatService ya está inicializado');
      }
      return;
    }

    try {
      // SupabaseChatCore usa automáticamente el cliente de Supabase
      // Solo necesitamos asegurarnos de que Supabase esté inicializado
      if (!supabaseService.isConnected) {
        throw Exception('Supabase no está inicializado');
      }

      // Actualizar información del usuario en el chat si es necesario
      await _updateCurrentUserInChat();

      _initialized = true;
      if (kDebugMode) {
        print('✅ ChatService inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al inicializar ChatService: $e');
      }
      _initialized = false;
    }
  }

  /// Actualizar información del usuario actual en el sistema de chat
  Future<void> _updateCurrentUserInChat() async {
    try {
      final supabase = supabaseService.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Intentar obtener datos del usuario desde nuestra BD
      final paciente = await _authRepository.getCurrentPaciente();
      final nutricionista = await _authRepository.getCurrentNutricionista();

      String? firstName;
      String? lastName;

      if (paciente != null) {
        firstName = paciente.nombre;
        lastName = paciente.apellidos;
      } else if (nutricionista != null) {
        firstName = nutricionista.nombre;
        lastName = nutricionista.apellidos;
      }

      if (firstName != null || lastName != null) {
        // Actualizar usuario en chats.users
        final supabase = supabaseService.client;
        await supabase.schema('chats').from('users').upsert({
          'id': currentUser.id,
          'firstName': firstName ?? '',
          'lastName': lastName ?? '',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar usuario en chat: $e');
      }
    }
  }

  /// Actualizar estado online del usuario actual
  /// Debe llamarse cuando el usuario abre la app o está activo
  Future<void> updateUserOnlineStatus(bool isOnline) async {
    try {
      final supabase = supabaseService.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      await supabase.schema('chats').from('user_status').upsert({
        'user_id': currentUser.id,
        'is_online': isOnline,
        'last_seen_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('[CHAT_SERVICE] Estado de usuario actualizado: isOnline=$isOnline');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CHAT_SERVICE] Error al actualizar estado del usuario: $e');
      }
    }
  }

  /// Asegurar que un usuario existe en chats.users
  Future<void> _ensureUserInChat(String userId, {String? firstName, String? lastName}) async {
    try {
      final supabase = supabaseService.client;
      
      // Verificar si el usuario ya existe
      final existingUser = await supabase
          .schema('chats')
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingUser == null) {
        // Crear usuario en chats.users
        final now = DateTime.now();
        await supabase.schema('chats').from('users').insert({
          'id': userId,
          'firstName': firstName ?? '',
          'lastName': lastName ?? '',
          'createdAt': now.millisecondsSinceEpoch,
          'updatedAt': now.millisecondsSinceEpoch,
          'lastSeen': now.millisecondsSinceEpoch,
        });
      } else if (firstName != null || lastName != null) {
        // Actualizar nombres si se proporcionaron
        await supabase
            .schema('chats')
            .from('users')
            .update({
              'firstName': firstName ?? '',
              'lastName': lastName ?? '',
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            })
            .eq('id', userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al asegurar usuario en chat: $e');
      }
      // No lanzar error, solo loguear
    }
  }

  /// Crear o obtener un room de chat entre el usuario actual y otro usuario
  Future<ChatRoom> createOrGetDirectRoom(String otherUserId, {String? roomName}) async {
    try {
      final supabase = supabaseService.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Asegurar que ambos usuarios existen en chats.users
      await _ensureUserInChat(currentUserId);
      await _ensureUserInChat(otherUserId);

      if (kDebugMode) {
        print('[CHAT_SERVICE] Buscando room entre $currentUserId y $otherUserId');
      }

      // Buscar room existente usando Supabase directamente
      // Buscar rooms directos que contengan ambos userIds
      final roomsResponse = await supabase
          .schema('chats')
          .from('rooms')
          .select()
          .eq('type', 'direct');

      if (kDebugMode) {
        print('[CHAT_SERVICE] Rooms encontrados: ${roomsResponse != null ? (roomsResponse as List).length : 0}');
      }

      if (roomsResponse != null && (roomsResponse as List).isNotEmpty) {
        for (final roomData in roomsResponse) {
          final room = roomData as Map<String, dynamic>;
          final userIds = (room['userIds'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          
          if (kDebugMode) {
            print('[CHAT_SERVICE] Room ${room['id']} tiene userIds: $userIds');
          }
          
          if (userIds.contains(currentUserId) && userIds.contains(otherUserId)) {
            // Room existente encontrado
            if (kDebugMode) {
              print('[CHAT_SERVICE] ✅ Room existente encontrado: ${room['id']}');
            }
            // Actualizar nombre si se proporciona
            if (roomName != null && roomName.isNotEmpty) {
              try {
                await supabase
                    .schema('chats')
                    .from('rooms')
                    .update({'name': roomName})
                    .eq('id', room['id']);
                room['name'] = roomName;
              } catch (e) {
                if (kDebugMode) {
                  print('[CHAT_SERVICE] Error al actualizar nombre del room: $e');
                }
              }
            }
            return jsonToRoom(room);
          }
        }
      }

      // Crear nuevo room
      if (kDebugMode) {
        print('[CHAT_SERVICE] No se encontró room existente, creando uno nuevo');
      }

      final now = DateTime.now();
      final roomDataToInsert = {
        'type': 'direct',
        'userIds': [currentUserId, otherUserId],
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
        'lastMessages': [],
        'userRoles': {},
      };

      // Obtener nombres de usuarios para el nombre del room si no se proporciona
      String finalRoomName = roomName ?? 'Chat';
      if ((roomName == null || roomName.isEmpty)) {
        try {
          final otherUserResponse = await supabase
              .schema('chats')
              .from('users')
              .select('firstName, lastName')
              .eq('id', otherUserId)
              .maybeSingle();
          
          if (otherUserResponse != null) {
            final firstName = otherUserResponse['firstName'] as String? ?? '';
            final lastName = otherUserResponse['lastName'] as String? ?? '';
            finalRoomName = '$firstName $lastName'.trim();
          }
        } catch (e) {
          // Ignorar error, usar nombre por defecto
        }
      }

      roomDataToInsert['name'] = finalRoomName;

      final insertResponse = await supabase
          .schema('chats')
          .from('rooms')
          .insert(roomDataToInsert)
          .select()
          .single();

      if (kDebugMode) {
        print('[CHAT_SERVICE] ✅ Room creado: ${insertResponse['id']}');
      }

      // Agregar miembros al room
      try {
        await supabase.schema('chats').from('room_members').insert([
          {'room_id': insertResponse['id'], 'user_id': currentUserId, 'role': 'member'},
          {'room_id': insertResponse['id'], 'user_id': otherUserId, 'role': 'member'},
        ]);
        if (kDebugMode) {
          print('[CHAT_SERVICE] ✅ Miembros agregados al room');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[CHAT_SERVICE] ⚠️ Error al agregar miembros (puede que ya existan): $e');
        }
        // Continuar aunque falle, el room ya está creado
      }

      return jsonToRoom(insertResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        print('Error al crear/obtener room: $e');
      }
      rethrow;
    }
  }

  /// Convertir JSON a types.Room (público para uso en otras pantallas)
  ChatRoom jsonToRoom(Map<String, dynamic> json) {
    final userIds = (json['userIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Chat',
      userIds: userIds,
      type: json['type'] as String? ?? 'direct',
    );
  }

  /// Obtener el auth_uid de un nutricionista desde su ID de nutricionista
  Future<String?> getNutricionistaAuthUid(String nutricionistaId) async {
    try {
      final supabase = supabaseService.client;
      final response = await supabase
          .from('nutricionistas')
          .select('auth_uid')
          .eq('id', nutricionistaId)
          .maybeSingle();

      return response?['auth_uid'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener auth_uid del nutricionista: $e');
      }
      return null;
    }
  }

  /// Obtener el auth_uid de un paciente desde su ID de paciente
  Future<String?> getPacienteAuthUid(String pacienteId) async {
    try {
      final supabase = supabaseService.client;
      final response = await supabase
          .from('pacientes')
          .select('auth_uid')
          .eq('id', pacienteId)
          .maybeSingle();

      return response?['auth_uid'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener auth_uid del paciente: $e');
      }
      return null;
    }
  }
}

/// Singleton instance
final chatService = ChatService();

