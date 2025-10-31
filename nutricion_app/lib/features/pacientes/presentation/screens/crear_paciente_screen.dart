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
    required String password,
    String? nombre,
    String? apellidos,
    String? sexo,
    int? edad,
    double? peso,
    double? talla,
    double? imc,
    String? historialMedico,
    String? observaciones,
  }) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _crearPacienteUseCase(
      dni: dni,
      password: password, // Contraseña inicial
      nombre: nombre ?? '',
      apellidos: apellidos ?? '',
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

/// Formulario simple que solo pide DNI y contraseña
class _FormularioSimplePaciente extends StatefulWidget {
  final Function({
    required String dni,
    required String password,
  }) onSubmit;

  const _FormularioSimplePaciente({
    required this.onSubmit,
  });

  @override
  State<_FormularioSimplePaciente> createState() => _FormularioSimplePacienteState();
}

class _FormularioSimplePacienteState extends State<_FormularioSimplePaciente> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        dni: _dniController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Crear cuenta de paciente',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El DNI es obligatorio';
                }
                if (value.trim().length < 5) {
                  return 'El DNI debe tener al menos 5 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Campo Contraseña
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña inicial *',
                hintText: 'Mínimo 6 caracteres',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSubmit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es obligatoria';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
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

