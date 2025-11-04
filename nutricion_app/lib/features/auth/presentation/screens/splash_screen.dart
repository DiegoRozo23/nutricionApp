import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/chat_notification_service.dart';
import '../../../../shared/services/chat_service.dart';
import 'role_selection_screen.dart';
import 'nutricionista_panel.dart';
import 'paciente_panel.dart';

/// Splash screen con verificación de sesión
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthRepository _repository = AuthRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Esperar un poco para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Verificar si Supabase está inicializado
    if (!supabaseService.isConnected) {
      // Si no está conectado, ir directamente a selección de rol
      // (la app funcionará pero sin backend)
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RoleSelectionScreen(),
        ),
      );
      return;
    }

    // Verificar sesión
    final result = await _repository.checkSession();

    if (!mounted) return;

    if (result is AuthSuccess) {
      // Inicializar servicio de notificaciones si hay sesión activa
      try {
        await chatNotificationService.reinit();
        // Actualizar estado online del usuario al abrir la app
        await chatService.updateUserOnlineStatus(true);
      } catch (e) {
        // Ignorar error, el servicio se inicializará más tarde
      }
      
      // Hay sesión activa, navegar al panel correspondiente
      if (result.isNutricionista) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const NutricionistaPanel(),
          ),
        );
      } else if (result.isPaciente) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PacientePanel(),
          ),
        );
      } else {
        // No hay sesión o no se pudo determinar el tipo
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const RoleSelectionScreen(),
          ),
        );
      }
    } else {
      // No hay sesión activa
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RoleSelectionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  size: 60,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'NutricionApp',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nutrición Personalizada',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

