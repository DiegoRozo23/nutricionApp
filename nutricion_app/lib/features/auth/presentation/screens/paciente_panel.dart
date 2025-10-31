import 'package:flutter/material.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../domain/entities/nutricionista.dart';
import '../../domain/entities/paciente.dart';
import '../../../chat/presentation/screens/rooms_screen.dart';
import 'role_selection_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PacientePanel extends StatefulWidget {
  const PacientePanel({super.key});

  @override
  State<PacientePanel> createState() => _PacientePanelState();
}

class _PacientePanelState extends State<PacientePanel> {
  late final LogoutUseCase _logoutUseCase;
  final AuthRepository _authRepository = AuthRepositoryImpl();
  
  Nutricionista? _nutricionista;
  Paciente? _paciente;
  bool _isLoadingNutricionista = true;

  @override
  void initState() {
    super.initState();
    _logoutUseCase = LogoutUseCase(_authRepository);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    // Obtener el paciente actual
    final paciente = await _authRepository.getCurrentPaciente();
    
    if (!mounted) return;
    
    setState(() {
      _paciente = paciente;
    });

    if (paciente?.nutricionistaId != null && paciente!.nutricionistaId!.isNotEmpty) {
      await _cargarNutricionista(paciente.nutricionistaId!);
    } else {
      setState(() {
        _isLoadingNutricionista = false;
      });
    }
  }

  Future<void> _cargarNutricionista(String nutricionistaId) async {
    try {
      final supabase = supabaseService.client;
      
      final nutriResponse = await supabase
          .from('nutricionistas')
          .select()
          .eq('id', nutricionistaId)
          .maybeSingle();

      if (nutriResponse != null && nutriResponse.isNotEmpty) {
        final nutriData = nutriResponse as Map<String, dynamic>;
        
        setState(() {
          _nutricionista = Nutricionista(
            id: nutriData['id'] as String,
            authUid: nutriData['auth_uid'] as String,
            nombre: nutriData['nombre'] as String,
            apellidos: nutriData['apellidos'] as String,
            dni: nutriData['dni'] as String?,
            especialidad: nutriData['especialidad'] as String?,
            privilegio: nutriData['privilegio'] as String? ?? 'nutricionista',
            username: nutriData['username'] as String?,
            email: nutriData['email'] as String?,
            telefono: nutriData['telefono'] as String?,
            activo: nutriData['activo'] as bool? ?? true,
            createdAt: DateTime.parse(nutriData['created_at'] as String),
            updatedAt: DateTime.parse(nutriData['updated_at'] as String),
          );
          _isLoadingNutricionista = false;
        });
      } else {
        try {
          final pacienteResponse = await supabase
              .from('pacientes')
              .select('nutricionista_id, nutricionistas(*)')
              .eq('auth_uid', supabase.auth.currentUser?.id ?? '')
              .maybeSingle();
          
          if (pacienteResponse != null && pacienteResponse['nutricionistas'] != null) {
            final nutriData = pacienteResponse['nutricionistas'] as Map<String, dynamic>;
            
            setState(() {
              _nutricionista = Nutricionista(
                id: nutriData['id'] as String,
                authUid: nutriData['auth_uid'] as String,
                nombre: nutriData['nombre'] as String,
                apellidos: nutriData['apellidos'] as String,
                dni: nutriData['dni'] as String?,
                especialidad: nutriData['especialidad'] as String?,
                privilegio: nutriData['privilegio'] as String? ?? 'nutricionista',
                username: nutriData['username'] as String?,
                email: nutriData['email'] as String?,
                telefono: nutriData['telefono'] as String?,
                activo: nutriData['activo'] as bool? ?? true,
                createdAt: DateTime.parse(nutriData['created_at'] as String),
                updatedAt: DateTime.parse(nutriData['updated_at'] as String),
              );
              _isLoadingNutricionista = false;
            });
          } else {
            setState(() {
              _isLoadingNutricionista = false;
            });
          }
        } catch (joinError) {
          setState(() {
            _isLoadingNutricionista = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNutricionista = false;
        });
      }
    }
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
        title: const Text('Panel del Paciente'),
        backgroundColor: const Color(0xFF2196F3),
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
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2196F3).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Scrollbar(
            thumbVisibility: true,
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
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu plan nutricional personalizado',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Información del Nutricionista
                  const Text(
                    'Mi Nutricionista',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingNutricionista
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _nutricionista == null
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.person_off_outlined,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'No tienes nutricionista asignado',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
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
                                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.medical_services,
                                      color: Color(0xFF4CAF50),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _nutricionista!.nombreCompleto,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_nutricionista!.especialidad != null &&
                                            _nutricionista!.especialidad!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _nutricionista!.especialidad!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Nutricionista',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                        if (_nutricionista!.email != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _nutricionista!.email!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  const SizedBox(height: 24),

                  // Botón Ver Plan Nutricional
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Próximamente'),
                            backgroundColor: Color(0xFF2196F3),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu, size: 24),
                      label: const Text(
                        'Ver Plan Nutricional',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Acciones
                  const Text(
                    'Acciones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _ActionCard(
                    title: 'Chat con Nutricionista',
                    subtitle: 'Envía mensajes a tu nutricionista',
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RoomsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
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

