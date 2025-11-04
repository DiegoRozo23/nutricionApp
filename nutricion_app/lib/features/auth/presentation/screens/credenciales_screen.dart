import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/utils/constants.dart';
import '../../../../shared/services/storage_service.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../../../shared/services/chat_notification_service.dart';
import '../../../../shared/services/supabase_service.dart';
import '../../../../shared/services/fcm_service.dart';
import 'nutricionista_panel.dart';
import 'paciente_panel.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart' as auth_domain;

/// Pantalla de login con credenciales
class CredencialesScreen extends StatefulWidget {
  final String role;

  const CredencialesScreen({
    super.key,
    required this.role,
  });

  @override
  State<CredencialesScreen> createState() => _CredencialesScreenState();
}

class _CredencialesScreenState extends State<CredencialesScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  
  // Controladores para los campos de texto
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Instanciar repository y use case
  late final auth_domain.AuthRepository _repository;
  late final LoginUseCase _loginUseCase;

  @override
  void initState() {
    super.initState();
    _repository = AuthRepositoryImpl();
    _loginUseCase = LoginUseCase(_repository);
    _loadRememberedCredentials();
  }

  /// Cargar credenciales guardadas si existe "Recordarme"
  Future<void> _loadRememberedCredentials() async {
    final rememberMe = storageService.getRememberMe();
    if (rememberMe) {
      setState(() {
        _rememberMe = true;
      });
      
      // Cargar credencial (username/DNI)
      final savedCredential = storageService.getString('saved_credential_${widget.role}');
      if (savedCredential != null) {
        _credentialController.text = savedCredential;
      }
      
      // Cargar contraseña de forma segura
      final savedPassword = await secureStorageService.getPassword(widget.role);
      if (savedPassword != null) {
        _passwordController.text = savedPassword;
      }
    }
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = _credentialController.text.trim();
      final password = _passwordController.text.trim();

      // Ejecutar login use case
      final result = await _loginUseCase(
        role: widget.role,
        credential: credential,
        password: password,
      );

      if (!mounted) return;

      if (result is auth_domain.AuthSuccess) {
        // Login exitoso - Guardar datos si "Recordarme" está activado
        if (_rememberMe) {
          await storageService.saveRememberMe(true);
          await storageService.saveString('saved_credential_${widget.role}', credential);
          // Guardar contraseña de forma segura
          await secureStorageService.savePassword(widget.role, password);
          // Guardar información del usuario y rol
          await storageService.saveString('current_role', widget.role);
          await storageService.saveString('current_user_id', result.token);
        } else {
          // Si no se marcó "Recordarme", limpiar datos previos
          await storageService.saveRememberMe(false);
          await storageService.remove('saved_credential_${widget.role}');
          await secureStorageService.removePassword(widget.role);
        }

        if (!mounted) return;

        // Inicializar servicio de notificaciones después del login
        try {
          await chatNotificationService.reinit();
        } catch (e) {
          // Ignorar error, el servicio se inicializará automáticamente
        }

        // Registrar token FCM para notificaciones push cuando la app está cerrada
        // Esto solicitará permisos de notificaciones si aún no se han otorgado
        try {
          final userId = supabaseService.client.auth.currentUser?.id;
          if (userId != null) {
            final permissionsGranted = await fcmService.registerUserToken(userId);
            if (!permissionsGranted && mounted) {
              // Si el usuario denegó permisos, mostrar mensaje informativo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Las notificaciones fueron denegadas. Puedes activarlas en la configuración del dispositivo.',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (e) {
          // Ignorar error, no es crítico para el login
          if (kDebugMode) {
            print('[LOGIN] Error al registrar token FCM: $e');
          }
        }

        // Login exitoso
        if (widget.role == 'nutricionista') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const NutricionistaPanel()),
            (route) => false,
          );
        } else if (widget.role == 'paciente') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PacientePanel()),
            (route) => false,
          );
        }
      } else if (result is auth_domain.AuthFailure) {
        // Login fallido - Mostrar mensaje mejorado
        String errorMessage = result.message;
        
        // Mejorar mensajes de error genéricos
        if (result.message.contains('Invalid login credentials') || 
            result.message.contains('Credenciales inválidas')) {
          errorMessage = 'Usuario o contraseña incorrectos';
        } else if (result.message.contains('User not found') ||
                   result.message.contains('no encontrado')) {
          errorMessage = 'Usuario no encontrado';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLabelText() {
    return widget.role == 'nutricionista' ? 'Usuario o Correo' : 'DNI';
  }

  String _getHintText() {
    return widget.role == 'nutricionista' 
        ? 'Ingresa tu usuario o correo' 
        : 'Ingresa tu DNI';
  }

  String _getTitleText() {
    return widget.role == 'nutricionista' 
        ? 'Iniciar Sesión como Nutricionista' 
        : 'Iniciar Sesión como Paciente';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // Icono del rol
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: widget.role == 'nutricionista' 
                            ? const Color(0xFF4CAF50) 
                            : const Color(0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.role == 'nutricionista' 
                            ? Icons.medical_services_outlined 
                            : Icons.person_outline,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Título
                    Text(
                      _getTitleText(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Label de Usuario/DNI (fuera del campo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            widget.role == 'nutricionista' 
                                ? Icons.person_outline 
                                : Icons.badge_outlined,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getLabelText(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Campo de Usuario/DNI
                    TextFormField(
                      controller: _credentialController,
                      decoration: InputDecoration(
                        hintText: _getHintText(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        prefixIcon: Icon(
                          widget.role == 'nutricionista' 
                              ? Icons.person_outline 
                              : Icons.badge_outlined,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa ${_getLabelText().toLowerCase()}';
                        }
                        if (widget.role == 'paciente') {
                          return Validators.dni(value);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Label de Contraseña (fuera del campo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contraseña',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Campo de Contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Ingresa tu contraseña',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => Validators.password(value),
                    ),
                    const SizedBox(height: 8),

                    // Recordarme
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        const Text('Recordarme'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botón de ingreso
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.role == 'nutricionista' 
                              ? const Color(0xFF4CAF50) 
                              : const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ), // Column
              ), // Form
            ), // SingleChildScrollView
              ), // Scrollbar
            ), // Center
          ), // SafeArea
        ), // Container
    ); // Scaffold
  }
}

