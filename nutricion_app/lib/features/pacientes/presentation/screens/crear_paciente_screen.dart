import 'package:flutter/material.dart';
import '../../domain/usecases/crear_paciente_usecase.dart';
import '../../data/repositories/pacientes_repository_impl.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../widgets/formulario_paciente.dart';

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
    required String nombre,
    required String apellidos,
    String? dni,
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
      nombre: nombre,
      apellidos: apellidos,
      dni: dni,
      sexo: sexo,
      edad: edad,
      peso: peso,
      talla: talla,
      imc: imc,
      medidasAntropometricas: null, // Se puede agregar después
      historialMedico: historialMedico,
      observaciones: observaciones,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result is PacientesSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente creado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Volver a la lista
    } else if (result is PacientesFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FormularioPaciente(
              isEditing: false,
              onSubmit: _crearPaciente,
            ),
    );
  }
}

