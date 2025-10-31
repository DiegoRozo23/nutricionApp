import 'package:flutter/material.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../../../../shared/services/chat_service.dart';
import 'chat_screen.dart';
import 'create_chat_screen.dart';

/// Pantalla que muestra la lista de conversaciones (rooms)
class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      if (!chatService.isInitialized) {
        await chatService.init();
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al inicializar el chat: $e';
      });
    }
  }

  void _navigateToChat(types.Room room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(room: room),
      ),
    );
  }

  void _navigateToCreateChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversaciones'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                              _isLoading = true;
                            });
                            _initializeChat();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : StreamBuilder<List<types.Room>>(
                  stream: chatService.getRoomsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar conversaciones:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rooms = snapshot.data!;

                    if (rooms.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes conversaciones',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Inicia una nueva conversación',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return _buildRoomCard(room);
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateChat,
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add_comment),
        label: const Text('Nueva conversación'),
      ),
    );
  }

  Widget _buildRoomCard(types.Room room) {
    // Obtener el otro usuario en el chat directo
    String roomName = room.name ?? 'Conversación';
    String? roomImageUrl = room.imageUrl;
    
    // Si es un chat directo, obtener datos del otro usuario
    if (room.type == types.RoomType.direct && room.users.length == 2) {
      final otherUser = room.users.firstWhere(
        (user) => user.id != chatService.getCurrentChatUser(),
        orElse: () => room.users.first,
      );
      
      roomName = '${otherUser.firstName ?? ''} ${otherUser.lastName ?? ''}'.trim();
      if (roomName.isEmpty) roomName = 'Usuario';
      roomImageUrl = otherUser.imageUrl;
    }

    // Obtener el último mensaje si existe
    String? lastMessageText;
    if (room.lastMessages != null && room.lastMessages!.isNotEmpty) {
      final lastMessage = room.lastMessages!.first;
      if (lastMessage is types.TextMessage) {
        lastMessageText = lastMessage.text;
      } else if (lastMessage is types.ImageMessage) {
        lastMessageText = '📷 Imagen';
      } else if (lastMessage is types.FileMessage) {
        lastMessageText = '📎 Archivo';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4CAF50),
          backgroundImage: roomImageUrl != null ? NetworkImage(roomImageUrl) : null,
          child: roomImageUrl == null
              ? Text(
                  roomName.isNotEmpty ? roomName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          roomName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: lastMessageText != null
            ? Text(
                lastMessageText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToChat(room),
      ),
    );
  }
}

