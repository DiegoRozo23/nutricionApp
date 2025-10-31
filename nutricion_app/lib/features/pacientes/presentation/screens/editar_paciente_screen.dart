import 'package:flutter/material.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/usecases/actualizar_paciente_usecase.dart';
import '../../data/repositories/pacientes_repository_impl.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../widgets/formulario_paciente.dart';

/// Pantalla para editar un paciente existente
class EditarPacienteScreen extends StatefulWidget {
  final Paciente paciente;

  const EditarPacienteScreen({
    super.key,
    required this.paciente,
  });

  @override
  State<EditarPacienteScreen> createState() => _EditarPacienteScreenState();
}

class _EditarPacienteScreenState extends State<EditarPacienteScreen> {
  final PacientesRepository _repository = PacientesRepositoryImpl();
  late final ActualizarPacienteUseCase _actualizarPacienteUseCase;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _actualizarPacienteUseCase = ActualizarPacienteUseCase(_repository);
  }

  Future<void> _actualizarPaciente({
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

    // Crear paciente actualizado manteniendo los campos que no cambian
    final pacienteActualizado = Paciente(
      id: widget.paciente.id,
      authUid: widget.paciente.authUid,
      nutricionistaId: widget.paciente.nutricionistaId,
      nombre: nombre,
      apellidos: apellidos,
      dni: dni,
      sexo: sexo,
      edad: edad,
      peso: peso,
      talla: talla,
      imc: imc,
      medidasAntropometricas: widget.paciente.medidasAntropometricas,
      historialMedico: historialMedico,
      observaciones: observaciones,
      activo: widget.paciente.activo,
      createdAt: widget.paciente.createdAt,
      updatedAt: DateTime.now(),
    );

    final result = await _actualizarPacienteUseCase(pacienteActualizado);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result is PacientesSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Volver al detalle
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
        title: Text('Editar ${widget.paciente.nombreCompleto}'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FormularioPaciente(
              isEditing: true,
              nombreInicial: widget.paciente.nombre,
              apellidosInicial: widget.paciente.apellidos,
              dniInicial: widget.paciente.dni,
              sexoInicial: widget.paciente.sexo,
              edadInicial: widget.paciente.edad,
              pesoInicial: widget.paciente.peso,
              tallaInicial: widget.paciente.talla,
              imcInicial: widget.paciente.imc,
              historialMedicoInicial: widget.paciente.historialMedico,
              observacionesInicial: widget.paciente.observaciones,
              onSubmit: _actualizarPaciente,
            ),
    );
  }
}

