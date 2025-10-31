import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Servicio para gestionar el chat usando SupabaseChatCore
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  bool _initialized = false;
  
  /// Verificar si el servicio está inicializado
  bool get isInitialized => _initialized;

  /// Inicializar el servicio de chat
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      final supabaseClient = supabaseService.client;
      
      // Configurar SupabaseChatCore con el cliente de Supabase
      await SupabaseChatCore.instance.initialize(
        supabaseClient: supabaseClient,
      );
      
      _initialized = true;
    } catch (e) {
      _initialized = false;
      rethrow;
    }
  }

  /// Obtener el usuario actual como User de flutter_chat_types
  Future<types.User?> getCurrentChatUser() async {
    if (!_initialized) await init();
    
    final authUser = supabaseService.client.auth.currentUser;
    if (authUser == null) return null;

    try {
      final chatUser = await SupabaseChatCore.instance.getUser(authUser.id);
      return chatUser;
    } catch (e) {
      return null;
    }
  }

  /// Crear o actualizar usuario de chat con metadatos personalizados
  Future<void> upsertChatUser({
    required String userId,
    required String firstName,
    required String lastName,
    String? imageUrl,
    required String role, // 'nutricionista' o 'paciente'
    Map<String, dynamic>? additionalMetadata,
  }) async {
    if (!_initialized) await init();

    final metadata = {
      'role': role,
      ...?additionalMetadata,
    };

    await SupabaseChatCore.instance.createUser(
      types.User(
        id: userId,
        firstName: firstName,
        lastName: lastName,
        imageUrl: imageUrl,
        role: types.Role.user,
        metadata: metadata,
      ),
    );
  }

  /// Obtener o crear una sala directa entre dos usuarios
  Future<types.Room> getOrCreateDirectRoom(String otherUserId) async {
    if (!_initialized) await init();

    final currentUser = supabaseService.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    // Llamar a la función de Supabase para obtener o crear room
    final response = await supabaseService.client.rpc(
      'get_or_create_direct_room',
      params: {
        'user_id_1': currentUser.id,
        'user_id_2': otherUserId,
      },
    );

    final roomId = response as String;

    // Obtener el room desde SupabaseChatCore
    final room = await SupabaseChatCore.instance.room(roomId);
    return room;
  }

  /// Stream de salas de chat del usuario actual
  Stream<List<types.Room>> getRoomsStream() {
    if (!_initialized) throw Exception('ChatService no inicializado');
    return SupabaseChatCore.instance.rooms();
  }

  /// Stream de mensajes de una sala
  Stream<List<types.Message>> getMessagesStream(String roomId) {
    if (!_initialized) throw Exception('ChatService no inicializado');
    return SupabaseChatCore.instance.messages(
      types.Room(id: roomId),
    );
  }

  /// Enviar un mensaje de texto
  Future<void> sendTextMessage(String roomId, String text) async {
    if (!_initialized) await init();

    final currentUser = supabaseService.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    final message = types.PartialText(
      text: text,
    );

    await SupabaseChatCore.instance.sendMessage(
      message,
      roomId,
    );
  }

  /// Enviar un mensaje con imagen
  Future<void> sendImageMessage({
    required String roomId,
    required String imagePath,
    required String imageName,
    required int imageSize,
  }) async {
    if (!_initialized) await init();

    final currentUser = supabaseService.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    // Subir imagen a Storage
    final fileName = '$roomId/${DateTime.now().millisecondsSinceEpoch}_$imageName';
    final response = await supabaseService.client.storage
        .from('chats_assets')
        .upload(fileName, imagePath as Object);

    if (response == null) {
      throw Exception('Error al subir imagen');
    }

    // Obtener URL pública
    final imageUrl = supabaseService.client.storage
        .from('chats_assets')
        .getPublicUrl(fileName);

    final message = types.PartialImage(
      name: imageName,
      size: imageSize,
      uri: imageUrl,
    );

    await SupabaseChatCore.instance.sendMessage(
      message,
      roomId,
    );
  }

  /// Enviar un mensaje con archivo
  Future<void> sendFileMessage({
    required String roomId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) async {
    if (!_initialized) await init();

    final currentUser = supabaseService.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    // Subir archivo a Storage
    final storageFileName = '$roomId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final response = await supabaseService.client.storage
        .from('chats_assets')
        .upload(storageFileName, filePath as Object);

    if (response == null) {
      throw Exception('Error al subir archivo');
    }

    // Obtener URL pública
    final fileUrl = supabaseService.client.storage
        .from('chats_assets')
        .getPublicUrl(storageFileName);

    final message = types.PartialFile(
      name: fileName,
      size: fileSize,
      uri: fileUrl,
      mimeType: mimeType,
    );

    await SupabaseChatCore.instance.sendMessage(
      message,
      roomId,
    );
  }

  /// Actualizar el estado de escritura (typing)
  Future<void> updateTypingStatus({
    required String roomId,
    required bool isTyping,
  }) async {
    if (!_initialized) await init();

    final currentUser = supabaseService.client.auth.currentUser;
    if (currentUser == null) return;

    await supabaseService.client.from('chats.typing_status').upsert({
      'user_id': currentUser.id,
      'room_id': roomId,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Stream del estado de escritura de otros usuarios en una sala
  Stream<List<String>> getTypingUsersStream(String roomId) {
    final currentUser = supabaseService.client.auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return supabaseService.client
        .from('chats.typing_status')
        .stream(primaryKey: ['user_id', 'room_id'])
        .eq('room_id', roomId)
        .eq('is_typing', true)
        .map((data) {
          return data
              .where((item) => item['user_id'] != currentUser.id)
              .map((item) => item['user_id'] as String)
              .toList();
        });
  }

  /// Buscar usuarios para crear chat
  Future<List<types.User>> searchUsers(String query) async {
    if (!_initialized) await init();

    final response = await supabaseService.client
        .from('chats.users')
        .select()
        .or('first_name.ilike.%$query%,last_name.ilike.%$query%')
        .limit(20);

    return response.map<types.User>((userData) {
      return types.User(
        id: userData['id'] as String,
        firstName: userData['first_name'] as String?,
        lastName: userData['last_name'] as String?,
        imageUrl: userData['image_url'] as String?,
        role: types.Role.user,
        metadata: userData['metadata'] as Map<String, dynamic>?,
      );
    }).toList();
  }

  /// Cerrar servicio
  void dispose() {
    _initialized = false;
  }
}

final chatService = ChatService();

