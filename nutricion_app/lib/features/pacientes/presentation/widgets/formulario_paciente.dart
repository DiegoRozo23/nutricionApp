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
    String? password, // Contraseña inicial (solo para crear)
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
  late final TextEditingController _passwordController; // Solo para crear
  
  String? _sexoSeleccionado;
  bool _obscurePassword = true;

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
    _passwordController = TextEditingController(); // Solo para crear
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
    _passwordController.dispose();
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

    // Validar que si se está creando (no editando), se requiere DNI y contraseña
    if (!widget.isEditing) {
      if (_dniController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El DNI es obligatorio para crear un paciente'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (_passwordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La contraseña inicial es obligatoria'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    widget.onSubmit(
      nombre: _nombreController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      dni: _dniController.text.trim().isEmpty ? null : _dniController.text.trim(),
      password: !widget.isEditing ? _passwordController.text.trim() : null,
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
    // Obtener el padding inferior del viewport (teclado/navegación)
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final extraBottomPadding = (bottomPadding > 0 
        ? bottomPadding 
        : (safeAreaBottom > 0 ? safeAreaBottom + 24.0 : 32.0)).toDouble();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: extraBottomPadding,
        ),
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
              decoration: InputDecoration(
                labelText: widget.isEditing ? 'DNI' : 'DNI *',
                prefixIcon: const Icon(Icons.badge),
                hintText: widget.isEditing ? null : 'Obligatorio para crear cuenta',
              ),
              keyboardType: TextInputType.number,
              enabled: !widget.isEditing, // No se puede editar DNI
            ),
            const SizedBox(height: 16),

            // Contraseña inicial (solo al crear)
            if (!widget.isEditing) ...[
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña inicial *',
                  hintText: 'Contraseña para que el paciente inicie sesión',
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
                validator: (value) {
                  if (!widget.isEditing && (value == null || value.isEmpty)) {
                    return 'La contraseña inicial es obligatoria';
                  }
                  if (!widget.isEditing && value != null && value.length < 4) {
                    return 'La contraseña debe tener al menos 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

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
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 16
                    : 16,
              ),
              child: SizedBox(
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
            ),
          ],
        ),
      ),
    );
  }
}

