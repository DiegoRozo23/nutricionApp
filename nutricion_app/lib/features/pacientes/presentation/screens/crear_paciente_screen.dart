import 'package:flutter/material.dart';
import '../../domain/usecases/crear_paciente_usecase.dart';
import '../../data/repositories/pacientes_repository_impl.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../../../auth/domain/entities/paciente.dart';
import '../widgets/formulario_paciente.dart';
import 'editar_paciente_screen.dart';

/// Pantalla para crear un nuevo paciente
class CrearPacienteScreen extends StatefulWidget {
  const CrearPacienteScreen({super.key});

  @override
  State<CrearPacienteScreen> createState() => _CrearPacienteScreenState();
}

class _CrearPacienteScreenState extends State<CrearPacienteScreen> {
  final PacientesRepository _repository = PacientesRepositoryImpl();
  late final CrearPacienteUseCase _crearPacienteUseCase;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _crearPacienteUseCase = CrearPacienteUseCase(_repository);
  }

  Future<void> _crearPaciente({
    required String dni,
    required String nombre,
    required String apellidos,
  }) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Generar contraseña automáticamente: DNI + primera letra nombre + primera letra apellido
    final passwordGenerada = _generarPassword(dni, nombre, apellidos);

    final result = await _crearPacienteUseCase(
      dni: dni,
      password: passwordGenerada, // Contraseña generada automáticamente
      nombre: nombre,
      apellidos: apellidos,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result is PacientesSuccess<Paciente>) {
      final pacienteCreado = result.data;
      
      // Esperar un momento antes de navegar para evitar transiciones bruscas
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Navegar inmediatamente a la pantalla de edición para completar los datos
      if (mounted) {
        final editResult = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditarPacienteScreen(
              paciente: pacienteCreado,
            ),
          ),
        );
        
        // Después de editar, esperar un momento y cerrar esta pantalla
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (editResult == true) {
            // Cerrar esta pantalla (crear) y volver al dashboard
            Navigator.of(context).pop(true);
          } else {
            // Si no hubo edición exitosa, solo cerrar esta pantalla
            Navigator.of(context).pop();
          }
        }
      }
    } else if (result is PacientesFailure) {
      // Si el error menciona sesión, es un caso especial donde el paciente se creó
      final isSessionError = result.message.contains('sesión') || 
                            result.message.contains('Sesión');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSessionError 
              ? 'Paciente creado. Por favor, sal y vuelve a entrar para ver los cambios.'
              : result.message
          ),
          backgroundColor: isSessionError ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Si es error de sesión, aún así volver para que intente recargar
      if (isSessionError) {
        Navigator.of(context).pop(true);
      }
    }
  }

  /// Genera la contraseña automáticamente: DNI + primera letra nombre + primera letra apellido
  String _generarPassword(String dni, String nombre, String apellidos) {
    final primeraLetraNombre = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    final primeraLetraApellido = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$dni$primeraLetraNombre$primeraLetraApellido';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Paciente'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _FormularioSimplePaciente(
                onSubmit: _crearPaciente,
              ),
      ),
    );
  }
}

/// Formulario simple que solo pide Nombre, Apellidos y DNI
/// La contraseña se genera automáticamente
class _FormularioSimplePaciente extends StatefulWidget {
  final Function({
    required String dni,
    required String nombre,
    required String apellidos,
  }) onSubmit;

  const _FormularioSimplePaciente({
    required this.onSubmit,
  });

  @override
  State<_FormularioSimplePaciente> createState() => _FormularioSimplePacienteState();
}

class _FormularioSimplePacienteState extends State<_FormularioSimplePaciente> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generarPassword() {
    final dni = _dniController.text.trim();
    final nombre = _nombreController.text.trim();
    final apellidos = _apellidosController.text.trim();
    
    setState(() {
      if (dni.isNotEmpty && nombre.isNotEmpty && apellidos.isNotEmpty) {
        final primeraLetraNombre = nombre[0].toUpperCase();
        final primeraLetraApellido = apellidos[0].toUpperCase();
        final passwordGenerada = '$dni$primeraLetraNombre$primeraLetraApellido';
        _passwordController.text = passwordGenerada;
      } else {
        _passwordController.clear();
      }
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        dni: _dniController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellidos: _apellidosController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).padding.bottom + 16.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Crear nuevo paciente',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Campo Nombre
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej: Juan',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _generarPassword(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Campo Apellidos
            TextFormField(
              controller: _apellidosController,
              decoration: const InputDecoration(
                labelText: 'Apellidos *',
                hintText: 'Ej: Pérez',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _generarPassword(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Los apellidos son obligatorios';
                }
                if (value.trim().length < 2) {
                  return 'Los apellidos deben tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Campo DNI
            TextFormField(
              controller: _dniController,
              decoration: const InputDecoration(
                labelText: 'DNI *',
                hintText: 'Ej: 12345678',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _generarPassword(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El DNI es obligatorio';
                }
                if (value.trim().length < 8) {
                  return 'El DNI debe tener al menos 8 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Campo Contraseña (solo lectura, generada automáticamente)
            TextFormField(
              controller: _passwordController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Contraseña (generada automáticamente)',
                hintText: 'Se generará al completar los campos',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: _passwordController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              obscureText: _passwordController.text.isNotEmpty && _obscurePassword,
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La contraseña se genera automáticamente: DNI + primera letra del nombre + primera letra del apellido',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Botón crear
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Crear cuenta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

