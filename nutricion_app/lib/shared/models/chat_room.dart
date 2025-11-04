/// Modelo simple de Room para el chat
class ChatRoom {
  final String id;
  final String? name;
  final List<String> userIds;
  final String type;

  ChatRoom({
    required this.id,
    this.name,
    required this.userIds,
    this.type = 'direct',
  });
}

