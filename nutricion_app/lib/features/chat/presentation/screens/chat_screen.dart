import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/services/supabase_service.dart';

/// Pantalla principal de chat individual
class ChatScreen extends StatefulWidget {
  final types.Room room;

  const ChatScreen({
    super.key,
    required this.room,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isAttachmentUploading = false;
  types.User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final currentUser = await chatService.getCurrentChatUser();
      setState(() {
        _currentUser = currentUser;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    try {
      await chatService.sendTextMessage(widget.room.id, message.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      Icon(Icons.photo),
                      SizedBox(width: 16),
                      Text('Foto'),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      Icon(Icons.insert_drive_file),
                      SizedBox(width: 16),
                      Text('Archivo'),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      Icon(Icons.cancel),
                      SizedBox(width: 16),
                      Text('Cancelar'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    // TODO: Implementar selección de archivos
    // Requiere el paquete file_picker
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidad de archivos próximamente'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleImageSelection() async {
    // TODO: Implementar selección de imágenes
    // Requiere el paquete image_picker
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidad de imágenes próximamente'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      // TODO: Abrir o descargar archivo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descarga de archivos próximamente'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    // Actualizar mensaje con preview data si es necesario
    // Esta funcionalidad es opcional
  }

  String _getRoomName() {
    if (widget.room.name != null && widget.room.name!.isNotEmpty) {
      return widget.room.name!;
    }

    // Si es un chat directo, obtener el nombre del otro usuario
    if (widget.room.type == types.RoomType.direct && widget.room.users.length == 2) {
      final currentUserId = supabaseService.client.auth.currentUser?.id;
      final otherUser = widget.room.users.firstWhere(
        (user) => user.id != currentUserId,
        orElse: () => widget.room.users.first,
      );

      final name = '${otherUser.firstName ?? ''} ${otherUser.lastName ?? ''}'.trim();
      return name.isEmpty ? 'Usuario' : name;
    }

    return 'Conversación';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getRoomName()),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<types.Message>>(
        stream: chatService.getMessagesStream(widget.room.id),
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
                    'Error al cargar mensajes:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final messages = snapshot.data!;

          return Chat(
            messages: messages,
            onAttachmentPressed: _handleAttachmentPressed,
            onMessageTap: _handleMessageTap,
            onPreviewDataFetched: _handlePreviewDataFetched,
            onSendPressed: _handleSendPressed,
            showUserAvatars: true,
            showUserNames: true,
            user: _currentUser!,
            theme: DefaultChatTheme(
              backgroundColor: Colors.grey.shade100,
              primaryColor: const Color(0xFF4CAF50),
              secondaryColor: Colors.grey.shade200,
              inputBackgroundColor: Colors.white,
              inputTextColor: Colors.black87,
              inputBorderRadius: BorderRadius.circular(24),
              messageBorderRadius: 20,
              inputMargin: const EdgeInsets.all(8),
              inputPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            inputOptions: const InputOptions(
              enabled: true,
              sendButtonVisibilityMode: SendButtonVisibilityMode.always,
            ),
            l10n: const ChatL10nEs(
              inputPlaceholder: 'Escribe un mensaje...',
              emptyChatPlaceholder: 'Aún no hay mensajes',
              fileButtonAccessibilityLabel: 'Archivo',
              attachmentButtonAccessibilityLabel: 'Adjuntar',
              sendButtonAccessibilityLabel: 'Enviar',
            ),
          );
        },
      ),
    );
  }
}

/// Localización en español para el chat
class ChatL10nEs extends ChatL10n {
  const ChatL10nEs({
    required super.inputPlaceholder,
    required super.emptyChatPlaceholder,
    required super.fileButtonAccessibilityLabel,
    required super.attachmentButtonAccessibilityLabel,
    required super.sendButtonAccessibilityLabel,
  });
}

