import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/paciente.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../shared/services/supabase_service.dart';

/// Pantalla de perfil del paciente donde puede ver todos sus datos
class PerfilPacienteScreen extends StatefulWidget {
  const PerfilPacienteScreen({super.key});

  @override
  State<PerfilPacienteScreen> createState() => _PerfilPacienteScreenState();
}

class _PerfilPacienteScreenState extends State<PerfilPacienteScreen> {
  final AuthRepository _authRepository = AuthRepositoryImpl();
  Paciente? _paciente;
  String? _password;
  bool _isLoading = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el paciente actual
      final paciente = await _authRepository.getCurrentPaciente();
      
      if (paciente == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar la información del paciente'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Intentar obtener la contraseña desde la tabla pacientes
      String? passwordObtenida;
      try {
        final supabase = supabaseService.client;
        final user = supabase.auth.currentUser;
        
        if (user != null) {
          final pacienteData = await supabase
              .from('pacientes')
              .select('password_visible, dni')
              .eq('auth_uid', user.id)
              .maybeSingle();
          
          if (pacienteData != null) {
            final passwordValue = pacienteData['password_visible'];
            if (passwordValue != null && passwordValue.toString().trim().isNotEmpty) {
              passwordObtenida = passwordValue.toString();
              if (kDebugMode) {
                print('[PERFIL_PACIENTE] ✅ Contraseña obtenida correctamente');
              }
            } else {
              if (kDebugMode) {
                print('[PERFIL_PACIENTE] ⚠️ Campo password_visible está vacío o null');
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('[PERFIL_PACIENTE] Error al obtener contraseña: $e');
        }
      }

      if (mounted) {
        setState(() {
          _paciente = paciente;
          _password = passwordObtenida;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PERFIL_PACIENTE] Error al cargar datos: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paciente == null
              ? const Center(child: Text('No se pudo cargar la información'))
              : GestureDetector(
                  onTap: () {
                    // Deseleccionar texto al tocar fuera de los SelectableText
                    FocusScope.of(context).unfocus();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de información básica
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2196F3).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Color(0xFF2196F3),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SelectableText(
                                            _paciente!.nombreCompleto,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (_paciente!.dni != null) ...[
                                            const SizedBox(height: 4),
                                            SelectableText(
                                              'DNI: ${_paciente!.dni}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Información de cuenta
                        const Text(
                          'Información de Cuenta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                if (_paciente!.dni != null)
                                  _InfoRow(
                                    label: 'DNI',
                                    value: _paciente!.dni!,
                                  ),
                                _InfoRow(
                                  label: 'Contraseña',
                                  value: _password != null && _password!.isNotEmpty
                                      ? _password!
                                      : 'No disponible',
                                  obscureValue: _password != null && _password!.isNotEmpty
                                      ? _obscurePassword
                                      : false,
                                  showToggle: _password != null && _password!.isNotEmpty,
                                  onToggle: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                if (_password == null || _password!.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.orange.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'La contraseña no está almacenada. Contacta a tu nutricionista si la olvidaste.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Información personal
                        const Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _InfoRow(
                                  label: 'Sexo',
                                  value: _paciente!.sexo ?? 'No especificado',
                                ),
                                _InfoRow(
                                  label: 'Edad',
                                  value: _paciente!.edad?.toString() ?? 'No especificada',
                                ),
                                _InfoRow(
                                  label: 'Peso',
                                  value: _paciente!.peso != null
                                      ? '${_paciente!.peso} kg'
                                      : 'No especificado',
                                ),
                                _InfoRow(
                                  label: 'Talla',
                                  value: _paciente!.talla != null
                                      ? '${_paciente!.talla} m'
                                      : 'No especificada',
                                ),
                                _InfoRow(
                                  label: 'IMC',
                                  value: _paciente!.imc != null
                                      ? _paciente!.imc!.toStringAsFixed(2)
                                      : 'No calculado',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Medidas Antropométricas
                        if (_paciente!.medidasAntropometricas != null &&
                            _paciente!.medidasAntropometricas!.isNotEmpty) ...[
                          const Text(
                            'Medidas Antropométricas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ..._paciente!.medidasAntropometricas!.entries.map((entry) {
                                    return _InfoRow(
                                      label: entry.key,
                                      value: _formatMedidaValue(entry.value),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Historial médico
                        if (_paciente!.historialMedico != null &&
                            _paciente!.historialMedico!.isNotEmpty) ...[
                          const Text(
                            'Historial Médico',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                _paciente!.historialMedico!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Observaciones
                        if (_paciente!.observaciones != null &&
                            _paciente!.observaciones!.isNotEmpty) ...[
                          const Text(
                            'Observaciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                _paciente!.observaciones!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  /// Formatear el valor de una medida antropométrica
  String _formatMedidaValue(dynamic value) {
    if (value is num) {
      if (value is int) {
        return value.toString();
      } else if (value is double) {
        return value == value.roundToDouble()
            ? value.round().toString()
            : value.toStringAsFixed(2);
      }
    }
    return value.toString();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool obscureValue;
  final bool showToggle;
  final VoidCallback? onToggle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.obscureValue = false,
    this.showToggle = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: SelectableText(
                    obscureValue ? '•' * value.length : value,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
                if (showToggle && onToggle != null) ...[
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          obscureValue ? Icons.visibility : Icons.visibility_off,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

