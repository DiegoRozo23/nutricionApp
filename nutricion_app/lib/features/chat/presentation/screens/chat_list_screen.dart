import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'chat_screen.dart';

/// Pantalla que muestra la lista de chats (rooms) del usuario
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<types.Room>>(
        future: SupabaseChatCore.instance.rooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error al cargar chats: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Recargar
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes chats aún',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _ChatListItem(
                room: room,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(room: room),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final types.Room room;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = room.lastMessages?.isNotEmpty == true
        ? room.lastMessages!.first
        : null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        backgroundImage: room.imageUrl != null
            ? NetworkImage(room.imageUrl!)
            : null,
        child: room.imageUrl == null
            ? Text(
                room.name?.isNotEmpty == true
                    ? room.name![0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text(
        room.name ?? 'Sin nombre',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: lastMessage != null
          ? Text(
              _getMessagePreview(lastMessage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const Text('Sin mensajes'),
      trailing: lastMessage != null
          ? Text(
              _formatTime(lastMessage.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  String _getMessagePreview(types.Message message) {
    switch (message.type) {
      case types.MessageType.text:
        return (message as types.TextMessage).text;
      case types.MessageType.image:
        return '📷 Imagen';
      case types.MessageType.file:
        return '📄 Archivo';
      case types.MessageType.audio:
        return '🎵 Audio';
      default:
        return 'Mensaje';
    }
  }

    String _formatTime(int? timestamp) {
      if (timestamp == null) return '';
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

