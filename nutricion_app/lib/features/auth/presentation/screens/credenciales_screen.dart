import 'package:flutter/material.dart';
import '../../../../shared/utils/constants.dart';
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
        // Login fallido
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
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
    return widget.role == 'nutricionista' ? 'Usuario' : 'DNI';
  }

  String _getHintText() {
    return widget.role == 'nutricionista' 
        ? 'Ingresa tu usuario' 
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

                    // Campo de Usuario/DNI
                    TextFormField(
                      controller: _credentialController,
                      decoration: InputDecoration(
                        labelText: _getLabelText(),
                        hintText: _getHintText(),
                        prefixIcon: Icon(
                          widget.role == 'nutricionista' 
                              ? Icons.person_outline 
                              : Icons.badge_outlined,
                        ),
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
                    const SizedBox(height: 16),

                    // Campo de Contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: 'Ingresa tu contraseña',
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

