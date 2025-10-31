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
    String? password, // No se usa al editar, pero necesario para la firma
    String? sexo,
    int? edad,
    double? peso,
    double? talla,
    double? imc,
    Map<String, dynamic>? medidasAntropometricas,
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
      medidasAntropometricas: medidasAntropometricas ?? widget.paciente.medidasAntropometricas,
      historialMedico: historialMedico,
      observaciones: observaciones,
      activo: widget.paciente.activo,
      createdAt: widget.paciente.createdAt,
      updatedAt: DateTime.now(),
    );

    final result = await _actualizarPacienteUseCase(pacienteActualizado);

    if (!mounted) return;

    if (result is PacientesSuccess) {
      // Mantener el overlay visible durante todo el proceso
      // Actualizar mensaje
      setState(() {
        // El overlay ya está visible con _isLoading = true
      });
      
      // Esperar un momento para que se guarde en la BD
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Cerrar esta pantalla (editar) y volver
      // El contexto que recibió el resultado manejará el resto de la navegación
      if (mounted) {
        // Cerrar solo esta pantalla y retornar true para indicar éxito
        // El overlay desaparecerá automáticamente cuando se cierre la pantalla
        Navigator.of(context).pop(true);
      }
    } else if (result is PacientesFailure) {
      // Solo ocultar el overlay si hay un error
      setState(() {
        _isLoading = false;
      });
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
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: FormularioPaciente(
              isEditing: true,
              nombreInicial: widget.paciente.nombre,
              apellidosInicial: widget.paciente.apellidos,
              dniInicial: widget.paciente.dni,
              sexoInicial: widget.paciente.sexo,
              edadInicial: widget.paciente.edad,
              pesoInicial: widget.paciente.peso,
              tallaInicial: widget.paciente.talla,
              imcInicial: widget.paciente.imc,
              medidasAntropometricasInicial: widget.paciente.medidasAntropometricas,
              historialMedicoInicial: widget.paciente.historialMedico,
              observacionesInicial: widget.paciente.observaciones,
              onSubmit: _actualizarPaciente,
            ),
          ),
          // Overlay de carga
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Guardando cambios...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Paciente actualizado correctamente',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

