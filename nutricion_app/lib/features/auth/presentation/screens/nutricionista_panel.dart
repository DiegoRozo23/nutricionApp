import 'package:flutter/material.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../shared/services/storage_service.dart';
import 'role_selection_screen.dart';

class NutricionistaPanel extends StatefulWidget {
  const NutricionistaPanel({super.key});

  @override
  State<NutricionistaPanel> createState() => _NutricionistaPanelState();
}

class _NutricionistaPanelState extends State<NutricionistaPanel> {
  late final LogoutUseCase _logoutUseCase;

  @override
  void initState() {
    super.initState();
    _logoutUseCase = LogoutUseCase(AuthRepositoryImpl());
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
      await _logoutUseCase();
      
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
        title: const Text('Panel del Nutricionista'),
        backgroundColor: const Color(0xFF4CAF50),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
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
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestión de pacientes y planes nutricionales',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Estadísticas
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Pacientes',
                        value: '0',
                        icon: Icons.people_outline,
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Planes',
                        value: '0',
                        icon: Icons.restaurant_menu,
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Acciones rápidas
                const Text(
                  'Acciones rápidas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _ActionCard(
                  title: 'Crear Paciente',
                  subtitle: 'Registrar nuevo paciente',
                  icon: Icons.person_add,
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Crear paciente (Próximamente)')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Ver Pacientes',
                  subtitle: 'Lista de pacientes registrados',
                  icon: Icons.list,
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ver pacientes (Próximamente)')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Generar Plan',
                  subtitle: 'Crear plan nutricional',
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generar plan (Próximamente)')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  title: 'Chats',
                  subtitle: 'Mensajes con pacientes',
                  icon: Icons.chat_bubble_outline,
                  color: const Color(0xFF9C27B0),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chats (Próximamente)')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

