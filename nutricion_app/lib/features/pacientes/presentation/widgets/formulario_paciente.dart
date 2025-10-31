import 'package:flutter/material.dart';

/// Widget reutilizable para formulario de paciente
class FormularioPaciente extends StatefulWidget {
  final String? nombreInicial;
  final String? apellidosInicial;
  final String? dniInicial;
  final String? sexoInicial;
  final int? edadInicial;
  final double? pesoInicial;
  final double? tallaInicial;
  final double? imcInicial;
  final String? historialMedicoInicial;
  final String? observacionesInicial;
  final bool isEditing;
  final Function({
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
  }) onSubmit;

  const FormularioPaciente({
    super.key,
    this.nombreInicial,
    this.apellidosInicial,
    this.dniInicial,
    this.sexoInicial,
    this.edadInicial,
    this.pesoInicial,
    this.tallaInicial,
    this.imcInicial,
    this.historialMedicoInicial,
    this.observacionesInicial,
    this.isEditing = false,
    required this.onSubmit,
  });

  @override
  State<FormularioPaciente> createState() => _FormularioPacienteState();
}

class _FormularioPacienteState extends State<FormularioPaciente> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidosController;
  late final TextEditingController _dniController;
  late final TextEditingController _edadController;
  late final TextEditingController _pesoController;
  late final TextEditingController _tallaController;
  late final TextEditingController _imcController;
  late final TextEditingController _historialMedicoController;
  late final TextEditingController _observacionesController;
  
  String? _sexoSeleccionado;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreInicial);
    _apellidosController = TextEditingController(text: widget.apellidosInicial);
    _dniController = TextEditingController(text: widget.dniInicial);
    _edadController = TextEditingController(
      text: widget.edadInicial?.toString(),
    );
    _pesoController = TextEditingController(
      text: widget.pesoInicial?.toString(),
    );
    _tallaController = TextEditingController(
      text: widget.tallaInicial?.toString(),
    );
    _imcController = TextEditingController(
      text: widget.imcInicial?.toString(),
    );
    _historialMedicoController = TextEditingController(
      text: widget.historialMedicoInicial,
    );
    _observacionesController = TextEditingController(
      text: widget.observacionesInicial,
    );
    _sexoSeleccionado = widget.sexoInicial;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _edadController.dispose();
    _pesoController.dispose();
    _tallaController.dispose();
    _imcController.dispose();
    _historialMedicoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _calcularIMC() {
    final peso = double.tryParse(_pesoController.text);
    final talla = double.tryParse(_tallaController.text);
    
    if (peso != null && talla != null && talla > 0) {
      final imc = peso / (talla * talla);
      _imcController.text = imc.toStringAsFixed(2);
      setState(() {});
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSubmit(
      nombre: _nombreController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      dni: _dniController.text.trim().isEmpty ? null : _dniController.text.trim(),
      sexo: _sexoSeleccionado,
      edad: int.tryParse(_edadController.text.trim()),
      peso: double.tryParse(_pesoController.text.trim()),
      talla: double.tryParse(_tallaController.text.trim()),
      imc: double.tryParse(_imcController.text.trim()),
      historialMedico: _historialMedicoController.text.trim().isEmpty
          ? null
          : _historialMedicoController.text.trim(),
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nombre
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Apellidos
            TextFormField(
              controller: _apellidosController,
              decoration: const InputDecoration(
                labelText: 'Apellidos *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Los apellidos son obligatorios';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // DNI
            TextFormField(
              controller: _dniController,
              decoration: const InputDecoration(
                labelText: 'DNI',
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Sexo
            DropdownButtonFormField<String>(
              initialValue: _sexoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Sexo',
                prefixIcon: Icon(Icons.wc),
              ),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Masculino')),
                DropdownMenuItem(value: 'F', child: Text('Femenino')),
                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
              ],
              onChanged: (value) {
                setState(() {
                  _sexoSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Edad
            TextFormField(
              controller: _edadController,
              decoration: const InputDecoration(
                labelText: 'Edad',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Peso y Talla
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pesoController,
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _calcularIMC(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _tallaController,
                    decoration: const InputDecoration(
                      labelText: 'Talla (m)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _calcularIMC(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // IMC (calculado automáticamente)
            TextFormField(
              controller: _imcController,
              decoration: const InputDecoration(
                labelText: 'IMC (calculado automáticamente)',
                prefixIcon: Icon(Icons.calculate),
              ),
              enabled: false,
              readOnly: true,
            ),
            const SizedBox(height: 16),

            // Historial Médico
            TextFormField(
              controller: _historialMedicoController,
              decoration: const InputDecoration(
                labelText: 'Historial Médico',
                prefixIcon: Icon(Icons.medical_information),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),

            // Observaciones
            TextFormField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 32),

            // Botón de envío
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  widget.isEditing ? 'Actualizar Paciente' : 'Crear Paciente',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

