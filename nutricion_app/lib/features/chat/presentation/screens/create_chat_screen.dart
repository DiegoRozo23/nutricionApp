import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/services/supabase_service.dart';
import 'chat_screen.dart';

/// Pantalla para crear una nueva conversación
class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<types.User> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final users = await chatService.searchUsers('');
      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _loadAllUsers();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final users = await chatService.searchUsers(query);
      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la búsqueda: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createChatWithUser(types.User user) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Crear o obtener el room directo
      final room = await chatService.getOrCreateDirectRoom(user.id);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navegar a la pantalla de chat
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(room: room),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear conversación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabaseService.client.auth.currentUser?.id;

    // Filtrar el usuario actual de los resultados
    final filteredResults = _searchResults
        .where((user) => user.id != currentUserId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Conversación'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar usuarios...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadAllUsers();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    _searchUsers(value);
                  },
                ),
              ),

              // Resultados de búsqueda
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : filteredResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No hay usuarios disponibles'
                                      : 'No se encontraron usuarios',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredResults.length,
                            itemBuilder: (context, index) {
                              final user = filteredResults[index];
                              return _buildUserCard(user);
                            },
                          ),
              ),
            ],
          ),

          // Overlay de carga
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCard(types.User user) {
    final userName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final displayName = userName.isEmpty ? 'Usuario' : userName;
    final role = user.metadata?['role'] as String?;
    final roleDisplay = role == 'nutricionista' ? 'Nutricionista' : 'Paciente';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: role == 'nutricionista' 
              ? const Color(0xFF4CAF50)
              : const Color(0xFF2196F3),
          backgroundImage: user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
          child: user.imageUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          roleDisplay,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4CAF50)),
        onTap: () => _createChatWithUser(user),
      ),
    );
  }
}

