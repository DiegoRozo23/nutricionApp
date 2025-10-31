import 'dart:async';
import 'package:flutter/material.dart';

/// Clase auxiliar para representar una medida antropométrica
class _MedidaAntropometrica {
  final TextEditingController nombreController;
  final TextEditingController valorController;

  _MedidaAntropometrica({
    required String nombre,
    required String valor,
  })  : nombreController = TextEditingController(text: nombre),
        valorController = TextEditingController(text: valor);

  String get nombre => nombreController.text.trim();
  String get valor => valorController.text.trim();

  void dispose() {
    nombreController.dispose();
    valorController.dispose();
  }
}

/// Widget independiente para cada tarjeta de medida antropométrica
/// Evita rebuilds innecesarios del formulario completo
class _MedidaCard extends StatefulWidget {
  final _MedidaAntropometrica medida;
  final VoidCallback onDelete;
  
  const _MedidaCard({
    super.key,
    required this.medida,
    required this.onDelete,
  });

  @override
  State<_MedidaCard> createState() => _MedidaCardState();
}

class _MedidaCardState extends State<_MedidaCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Importante para AutomaticKeepAliveClientMixin
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: widget.medida.nombreController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Medida',
                        hintText: 'Ej: Perímetro Cintura, Pliegue Tríceps',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: widget.onDelete,
                    tooltip: 'Eliminar medida',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.medida.valorController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  hintText: 'Ej: 85, 95.5, 32',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  final Map<String, dynamic>? medidasAntropometricasInicial;
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
    Map<String, dynamic>? medidasAntropometricas,
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
    this.medidasAntropometricasInicial,
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
  
  // Lista de medidas antropométricas
  final List<_MedidaAntropometrica> _medidasAntropometricas = [];
  
  String? _sexoSeleccionado;
  bool _obscurePassword = true;
  bool _expandedMedidas = false;
  Timer? _debounceTimer;

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
    
    // Inicializar medidas antropométricas desde el Map
    final medidasInicial = widget.medidasAntropometricasInicial ?? {};
    if (medidasInicial.isNotEmpty) {
      medidasInicial.forEach((key, value) {
        _medidasAntropometricas.add(_MedidaAntropometrica(
          nombre: key,
          valor: value.toString(),
        ));
      });
      _expandedMedidas = true;
    }
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
    // Dispose de controllers de medidas antropométricas
    for (final medida in _medidasAntropometricas) {
      medida.dispose();
    }
    // Cancelar timer de debounce
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _calcularIMC() {
    if (!mounted) return;
    final peso = double.tryParse(_pesoController.text);
    final talla = double.tryParse(_tallaController.text);
    
    if (peso != null && talla != null && talla > 0) {
      final imc = peso / (talla * talla);
      final nuevoImc = imc.toStringAsFixed(2);
      // Actualizar controller sin setState para evitar rebuilds innecesarios
      if (_imcController.text != nuevoImc) {
        _imcController.text = nuevoImc;
      }
    }
  }

  /// Calcular IMC con debounce real
  void _calcularIMCConDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _calcularIMC);
  }

  /// Agregar una nueva medida antropométrica
  void _agregarMedida() {
    setState(() {
      _medidasAntropometricas.add(_MedidaAntropometrica(
        nombre: '',
        valor: '',
      ));
    });
  }

  /// Eliminar una medida antropométrica
  void _eliminarMedida(int index) {
    setState(() {
      _medidasAntropometricas[index].dispose();
      _medidasAntropometricas.removeAt(index);
    });
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

    // Construir Map de medidas antropométricas desde la lista
    Map<String, dynamic>? medidasAntropometricas;
    final medidasMap = <String, dynamic>{};
    
    for (final medida in _medidasAntropometricas) {
      final nombreTexto = medida.nombre;
      final valorTexto = medida.valor;
      if (nombreTexto.isNotEmpty && valorTexto.isNotEmpty) {
        // Intentar parsear como número
        final valorNum = double.tryParse(valorTexto);
        if (valorNum != null) {
          medidasMap[nombreTexto] = valorNum;
        } else {
          medidasMap[nombreTexto] = valorTexto;
        }
      }
    }
    
    medidasAntropometricas = medidasMap.isNotEmpty ? medidasMap : null;

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
      medidasAntropometricas: medidasAntropometricas,
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
    // Obtener el padding inferior para el teclado
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardHeight = viewInsets.bottom;
    final extraBottomPadding = keyboardHeight > 0 ? keyboardHeight + 16.0 : 32.0;
    
    return Form(
      key: _formKey,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: widget.isEditing ? 'DNI' : 'DNI *',
                prefixIcon: const Icon(Icons.badge),
                hintText: widget.isEditing ? null : 'Obligatorio para crear cuenta',
              ),
              keyboardType: TextInputType.number,
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
                  if (!widget.isEditing && value != null && value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Sexo
            DropdownButtonFormField<String>(
              value: _sexoSeleccionado,
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
                if (_sexoSeleccionado != value) {
                  setState(() {
                    _sexoSeleccionado = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Edad
            TextFormField(
              controller: _edadController,
              textInputAction: TextInputAction.next,
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _calcularIMCConDebounce(),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _calcularIMCConDebounce(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // IMC (calculado automáticamente)
            TextFormField(
              controller: _imcController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'IMC (calculado automáticamente)',
                prefixIcon: Icon(Icons.calculate),
              ),
              enabled: false,
              readOnly: true,
            ),
            const SizedBox(height: 16),

            // Medidas Antropométricas (Expandible)
            // Solo renderizar el contenido cuando está expandido para mejor rendimiento
            Card(
              elevation: 2,
              child: ExpansionTile(
                key: const ValueKey('medidas_antropometricas'),
                leading: const Icon(Icons.straighten),
                title: const Text('Medidas Antropométricas'),
                subtitle: Text(
                  '${_medidasAntropometricas.length} medida(s) agregada(s)',
                  style: const TextStyle(fontSize: 12),
                ),
                initiallyExpanded: _expandedMedidas,
                maintainState: true,
                onExpansionChanged: (expanded) {
                  if (_expandedMedidas != expanded) {
                    setState(() {
                      _expandedMedidas = expanded;
                    });
                  }
                },
                children: _expandedMedidas || _medidasAntropometricas.isNotEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Ejemplo
                              Builder(
                                builder: (context) {
                                  final blue50 = Colors.blue.shade50;
                                  final blue200 = Colors.blue.shade200;
                                  final blue700 = Colors.blue.shade700;
                                  final blue900 = Colors.blue.shade900;
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: blue50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: blue200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, 
                                             size: 20, 
                                             color: blue700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Ejemplo: Escribe "Perímetro Cintura" y el valor "85"',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: blue900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              // Lista de medidas agregadas (usando Column en lugar de ListView.builder para evitar ListView anidado)
                              if (_medidasAntropometricas.isNotEmpty)
                                Column(
                                  children: List.generate(_medidasAntropometricas.length, (index) {
                                    final medida = _medidasAntropometricas[index];
                                    return _MedidaCard(
                                      key: ValueKey(medida), // key estable (el objeto)
                                      medida: medida,
                                      onDelete: () => _eliminarMedida(index),
                                    );
                                  }),
                                ),
                              // Botón para añadir medida
                              ElevatedButton.icon(
                                onPressed: _agregarMedida,
                                icon: const Icon(Icons.add),
                                label: const Text('Añadir Medida'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.green.shade100,
                                  foregroundColor: Colors.green.shade900,
                                ),
                              ),
                              if (_medidasAntropometricas.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    'Presiona "Añadir Medida" para comenzar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(height: 16),

            // Historial Médico
            TextFormField(
              controller: _historialMedicoController,
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),

            // Botón de envío
            const SizedBox(height: 32),
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
             const SizedBox(height: 32), // Espacio al final
           ],
          ),
        ),
      ),
    );
  }
}

