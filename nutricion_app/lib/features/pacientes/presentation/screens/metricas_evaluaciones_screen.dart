import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/services/evaluaciones_modelo_service.dart';
import '../../../../shared/services/supabase_service.dart';

/// Pantalla para mostrar métricas y evaluaciones de modelos de planes nutricionales
class MetricasEvaluacionesScreen extends StatefulWidget {
  const MetricasEvaluacionesScreen({super.key});

  @override
  State<MetricasEvaluacionesScreen> createState() => _MetricasEvaluacionesScreenState();
}

class _MetricasEvaluacionesScreenState extends State<MetricasEvaluacionesScreen> {
  final EvaluacionesModeloService _evaluacionesService = EvaluacionesModeloService();
  List<Map<String, dynamic>> _evaluaciones = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarEvaluaciones();
  }

  Future<void> _cargarEvaluaciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final evaluaciones = await _evaluacionesService.obtenerTodasLasEvaluaciones();
      setState(() {
        _evaluaciones = evaluaciones;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar evaluaciones: $e');
      }
      setState(() {
        _errorMessage = 'Error al cargar evaluaciones: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatearFecha(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatearTiempo(double segundos) {
    if (segundos < 60) {
      return '${segundos.toStringAsFixed(2)}s';
    } else {
      final minutos = (segundos / 60).floor();
      final segs = (segundos % 60).toStringAsFixed(2);
      return '${minutos}m ${segs}s';
    }
  }

  String _obtenerNombrePaciente(Map<String, dynamic> evaluacion) {
    try {
      final paciente = evaluacion['pacientes'] as Map<String, dynamic>?;
      if (paciente != null) {
        final nombre = paciente['nombre'] as String? ?? '';
        final apellidos = paciente['apellidos'] as String? ?? '';
        return '$nombre $apellidos'.trim();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener nombre del paciente: $e');
      }
    }
    return 'N/A';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas y Reportes'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEvaluaciones,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarEvaluaciones,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _evaluaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assessment_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay evaluaciones registradas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarEvaluaciones,
                      child: Column(
                        children: [
                          // Resumen estadístico
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            color: Colors.blue.shade50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resumen',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ResumenCard(
                                        titulo: 'Total',
                                        valor: '${_evaluaciones.length}',
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ResumenCard(
                                        titulo: 'Correctos',
                                        valor: '${_evaluaciones.where((e) => e['calificacion_nutricionista'] == 'Correcto').length}',
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ResumenCard(
                                        titulo: 'Incorrectos',
                                        valor: '${_evaluaciones.where((e) => e['calificacion_nutricionista'] == 'Incorrecto').length}',
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ResumenCard(
                                        titulo: 'Tiempo Promedio',
                                        valor: _evaluaciones.isNotEmpty
                                            ? _formatearTiempo(
                                                _evaluaciones
                                                    .map((e) => (e['tiempo_generacion_segundos'] as num?)?.toDouble() ?? 0.0)
                                                    .reduce((a, b) => a + b) /
                                                    _evaluaciones.length,
                                              )
                                            : '0s',
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Tabla de evaluaciones
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowHeight: 60,
                                  dataRowMinHeight: 50,
                                  dataRowMaxHeight: 100,
                                  columnSpacing: 20,
                                  headingRowColor: MaterialStateProperty.all(
                                    const Color(0xFF2196F3).withOpacity(0.1),
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Código\nPlan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Tipo de Plan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Tiempo\nGeneración',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Calificación',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Paciente',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Fecha',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: _evaluaciones.map((evaluacion) {
                                    final calificacion = evaluacion['calificacion_nutricionista'] as String? ?? 'N/A';
                                    final esCorrecto = calificacion == 'Correcto';
                                    final fechaStr = evaluacion['fecha_evaluacion'] as String?;
                                    DateTime? fecha;
                                    if (fechaStr != null) {
                                      try {
                                        fecha = DateTime.parse(fechaStr);
                                      } catch (e) {
                                        // Ignorar error de parsing
                                      }
                                    }

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            evaluacion['codigo_plan'] as String? ?? 'N/A',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 200,
                                            child: Text(
                                              evaluacion['tipo_plan_nutricional'] as String? ?? 'N/A',
                                              style: const TextStyle(fontSize: 11),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            _formatearTiempo(
                                              (evaluacion['tiempo_generacion_segundos'] as num?)?.toDouble() ?? 0.0,
                                            ),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: esCorrecto
                                                  ? Colors.green.shade100
                                                  : Colors.red.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: esCorrecto
                                                    ? Colors.green.shade300
                                                    : Colors.red.shade300,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              calificacion,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: esCorrecto
                                                    ? Colors.green.shade800
                                                    : Colors.red.shade800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: 150,
                                            child: Text(
                                              _obtenerNombrePaciente(evaluacion),
                                              style: const TextStyle(fontSize: 11),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            fecha != null
                                                ? _formatearFecha(fecha)
                                                : 'N/A',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
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

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

