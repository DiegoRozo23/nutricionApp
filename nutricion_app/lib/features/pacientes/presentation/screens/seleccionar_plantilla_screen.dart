import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/paciente.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../../domain/usecases/obtener_paciente_por_id_usecase.dart';
import '../../data/repositories/pacientes_repository_impl.dart';
import '../../../../shared/services/prediccion_plan_service.dart';
import 'plan_sugerido_screen.dart';
import 'editar_paciente_screen.dart';

/// Pantalla para generar un plan nutricional usando IA
class SeleccionarPlantillaScreen extends StatefulWidget {
  final Paciente paciente;

  const SeleccionarPlantillaScreen({
    super.key,
    required this.paciente,
  });

  @override
  State<SeleccionarPlantillaScreen> createState() => _SeleccionarPlantillaScreenState();
}

class _SeleccionarPlantillaScreenState extends State<SeleccionarPlantillaScreen> {
  final PrediccionPlanService _prediccionService = PrediccionPlanService();
  late Paciente _paciente; // Mantener el paciente actualizado
  bool _obteniendoPrediccion = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _paciente = widget.paciente;
  }

  /// Recarga el paciente desde la base de datos
  Future<void> _recargarPaciente() async {
    try {
      final repository = PacientesRepositoryImpl();
      final useCase = ObtenerPacientePorIdUseCase(repository);
      final result = await useCase(_paciente.id);

      if (result is PacientesSuccess<Paciente>) {
        setState(() {
          _paciente = result.data;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al recargar paciente: $e');
      }
    }
  }

  /// Valida que el paciente tenga todos los datos necesarios para la predicción
  /// Retorna una lista con los nombres de los datos que faltan
  List<String> _validarDatosPaciente() {
    final datosFaltantes = <String>[];

    // 1. Edad
    if (_paciente.edad == null) {
      datosFaltantes.add('Edad');
    }

    // 2. Sexo
    if (_paciente.sexo == null || _paciente.sexo!.isEmpty) {
      datosFaltantes.add('Sexo');
    }

    // 3. Peso
    if (_paciente.peso == null) {
      datosFaltantes.add('Peso');
    }

    // 4. Talla
    if (_paciente.talla == null) {
      datosFaltantes.add('Talla');
    }

    // 5. IMC
    if (_paciente.imc == null) {
      datosFaltantes.add('IMC');
    }

    // 6. Circunferencia de cintura (de medidas antropométricas)
    bool tieneCintura = false;
    if (_paciente.medidasAntropometricas != null) {
      final medidas = _paciente.medidasAntropometricas!;
      for (final clave in medidas.keys) {
        if (clave.toString().toLowerCase() == 'cintura') {
          tieneCintura = true;
          break;
        }
      }
    }
    if (!tieneCintura) {
      datosFaltantes.add('Circunferencia de cintura (en Medidas Antropométricas)');
    }

    // 7. Nivel de actividad física
    if (_paciente.actividadFisica == null || 
        _paciente.actividadFisica!.isEmpty) {
      datosFaltantes.add('Nivel de actividad física');
    }

    return datosFaltantes;
  }

  /// Muestra un diálogo con los datos faltantes y opción para editar el paciente
  Future<void> _mostrarDatosFaltantes(List<String> datosFaltantes) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Datos Faltantes'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para generar un plan nutricional con IA, se requieren los siguientes datos del paciente:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Datos requeridos:'),
              const SizedBox(height: 8),
              ...['Edad', 'Sexo', 'Peso', 'Talla', 'IMC', 'Circunferencia de cintura (en Medidas Antropométricas)', 'Nivel de actividad física']
                  .map((dato) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              datosFaltantes.contains(dato)
                                  ? Icons.close
                                  : Icons.check_circle,
                              size: 20,
                              color: datosFaltantes.contains(dato)
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dato,
                                style: TextStyle(
                                  color: datosFaltantes.contains(dato)
                                      ? Colors.red.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              if (datosFaltantes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faltan ${datosFaltantes.length} dato(s):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...datosFaltantes.map((dato) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $dato',
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop(); // Cerrar diálogo
              // Navegar a editar paciente
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditarPacienteScreen(
                    paciente: _paciente,
                  ),
                ),
              );
              // Si se actualizó el paciente, recargar y validar de nuevo
              if (resultado == true && mounted) {
                await _recargarPaciente();
                // Validar de nuevo después de recargar
                final datosFaltantesNuevos = _validarDatosPaciente();
                if (datosFaltantesNuevos.isEmpty) {
                  // Si ya no faltan datos, intentar generar el plan
                  _obtenerPrediccionIA();
                } else {
                  // Si aún faltan datos, mostrar el diálogo de nuevo
                  await _mostrarDatosFaltantes(datosFaltantesNuevos);
                }
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Editar Paciente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _obtenerPrediccionIA() async {
    // Validar que el paciente tenga todos los datos necesarios
    final datosFaltantes = _validarDatosPaciente();
    
    if (datosFaltantes.isNotEmpty) {
      await _mostrarDatosFaltantes(datosFaltantes);
      return;
    }

    setState(() {
      _obteniendoPrediccion = true;
      _errorMessage = null;
    });

    try {
      // Obtener circunferencia de cintura de medidas antropométricas
      // Buscar sin importar mayúsculas/minúsculas
      double circunferenciaCintura = 0.0;
      if (_paciente.medidasAntropometricas != null) {
        final medidas = _paciente.medidasAntropometricas!;
        // Buscar el valor con clave "cintura" (sin importar mayúsculas/minúsculas)
        String? claveCintura;
        for (final clave in medidas.keys) {
          if (clave.toString().toLowerCase() == 'cintura') {
            claveCintura = clave.toString();
            break;
          }
        }
        
        if (claveCintura != null) {
          final valor = medidas[claveCintura];
          if (valor is num) {
            circunferenciaCintura = valor.toDouble();
          } else if (valor is String) {
            circunferenciaCintura = double.tryParse(valor) ?? 0.0;
          }
        }
        
        if (kDebugMode) {
          print('[PREDICCION] Circunferencia de cintura encontrada: $circunferenciaCintura (clave: $claveCintura)');
        }
      }

      // Obtener nivel de actividad física de la columna actividadFisica
      String nivelActividadFisica = _paciente.actividadFisica ?? 'Baja';

      // Convertir sexo a formato esperado por la API (M o F)
      String sexo = _paciente.sexo!;
      if (sexo == 'M' || sexo == 'Masculino' || sexo.toLowerCase() == 'masculino') {
        sexo = 'M';
      } else if (sexo == 'F' || sexo == 'Femenino' || sexo.toLowerCase() == 'femenino') {
        sexo = 'F';
      } else {
        // Si no coincide, usar M por defecto
        sexo = 'M';
      }

      // Iniciar medición de tiempo JUSTO ANTES de la llamada a la API
      final tiempoInicio = DateTime.now();

      // Llamar a la API para obtener la predicción
      final respuesta = await _prediccionService.obtenerPrediccionPlan(
        edad: _paciente.edad!,
        sexo: sexo,
        pesoActual: _paciente.peso!,
        talla: _paciente.talla!,
        imc: _paciente.imc!,
        circunferenciaCintura: circunferenciaCintura,
        nivelActividadFisica: nivelActividadFisica,
      );

      // Calcular tiempo de generación (solo el tiempo de la llamada a la API)
      final tiempoFin = DateTime.now();
      final tiempoGeneracion = tiempoFin.difference(tiempoInicio).inMilliseconds / 1000.0;

      if (kDebugMode) {
        print('[PREDICCION] Tiempo de generación del modelo: ${tiempoGeneracion.toStringAsFixed(2)} segundos');
      }

      setState(() {
        _obteniendoPrediccion = false;
      });

      // Extraer el nombre del plan recomendado
      final planRecomendado = respuesta['plan_recomendado'] as String? ??
          respuesta['plan'] as String? ??
          '';

      if (planRecomendado.isEmpty) {
        throw Exception('La API no devolvió un plan recomendado');
      }

      // Navegar a la pantalla del plan sugerido
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanSugeridoScreen(
              paciente: _paciente,
              planRecomendadoNombre: planRecomendado,
              tiempoGeneracionSegundos: tiempoGeneracion,
            ),
          ),
        );

        // Si result es null o false, significa que se volvió sin guardar
        // En ese caso, retornar true para que el dashboard se actualice
        // Si result == true, significa que se guardó el plan y la navegación
        // ya se hizo desde PlanSugeridoScreen, así que no hacer nada aquí
        if (result != true && mounted) {
          // Si solo se volvió (sin guardar), retornar true para actualizar
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener predicción: $e');
      }
      setState(() {
        _obteniendoPrediccion = false;
        _errorMessage = 'Error al obtener predicción: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al obtener predicción de IA.\n${e.toString()}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generar Plan para ${_paciente.nombreCompleto}'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: const Color(0xFFFF9800).withOpacity(0.7),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Generar Plan Nutricional con IA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nuestra inteligencia artificial analizará los datos del paciente para sugerir el plan nutricional más adecuado.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _obteniendoPrediccion ? null : _obtenerPrediccionIA,
                        icon: _obteniendoPrediccion
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 28),
                        label: Text(
                          _obteniendoPrediccion
                              ? 'Obteniendo predicción...'
                              : 'Generar Plan con IA',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

