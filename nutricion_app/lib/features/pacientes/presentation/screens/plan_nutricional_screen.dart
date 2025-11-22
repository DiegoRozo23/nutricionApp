import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../../shared/models/plan_nutricional.dart';
import '../../../../shared/services/plan_nutricional_service.dart';
import '../../../../shared/services/planes_nutricionales_service.dart';
import '../../../../shared/services/supabase_service.dart';
import 'editar_plan_nutricional_screen.dart';
import 'metricas_evaluaciones_screen.dart';
import '../../../auth/presentation/screens/nutricionista_panel.dart';
import '../../../auth/presentation/screens/paciente_panel.dart';

/// Pantalla para mostrar el plan nutricional y exportarlo como PDF
class PlanNutricionalScreen extends StatefulWidget {
  final String? pacienteId; // ID del paciente para mostrar su plan asignado
  final String? planId; // ID del plan específico a mostrar

  const PlanNutricionalScreen({
    super.key,
    this.pacienteId,
    this.planId,
  });

  @override
  State<PlanNutricionalScreen> createState() => _PlanNutricionalScreenState();
}

class _PlanNutricionalScreenState extends State<PlanNutricionalScreen> {
  final PlanNutricionalService _planService = PlanNutricionalService();
  final PlanesNutricionalesService _planesService = PlanesNutricionalesService();
  PlanNutricional? _plan;
  bool _isLoading = true;
  String? _errorMessage;
  bool _esPlanAsignado = false; // Indica si es un plan asignado o una plantilla
  bool _esNutricionista = false; // Indica si el usuario es nutricionista
  String? _nombrePaciente;
  String? _nombreNutricionista;
  DateTime? _fechaCreacionPlan;

  @override
  void initState() {
    super.initState();
    _verificarRol();
    _cargarPlan();
  }

  Future<void> _verificarRol() async {
    try {
      final user = supabaseService.client.auth.currentUser;
      if (user != null) {
        final nutriResponse = await supabaseService.client
            .from('nutricionistas')
            .select('id')
            .eq('auth_uid', user.id)
            .maybeSingle();
        
        final esNutri = nutriResponse != null;
        if (kDebugMode) {
          print('[PLAN_NUTRICIONAL] Verificando rol. Es nutricionista: $esNutri');
        }
        
        setState(() {
          _esNutricionista = esNutri;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PLAN_NUTRICIONAL] Error al verificar rol: $e');
      }
    }
  }

  Future<String?> _obtenerPacienteIdDelPlan(String planId) async {
    try {
      final plan = await _planesService.obtenerPlanPorId(planId);
      return plan?['paciente_id'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener pacienteId del plan: $e');
      }
      return null;
    }
  }

  /// Carga los datos del paciente y nutricionista para el PDF
  Future<void> _cargarDatosPacienteYNutricionista(
    String? pacienteId,
    String? nutricionistaId,
    String? fechaCreacionStr,
  ) async {
    try {
      // Cargar nombre del paciente
      if (pacienteId != null && pacienteId.isNotEmpty) {
        final pacienteResponse = await supabaseService.client
            .from('pacientes')
            .select('nombre, apellidos')
            .eq('id', pacienteId)
            .maybeSingle();
        
        if (pacienteResponse != null) {
          final nombre = pacienteResponse['nombre'] as String? ?? '';
          final apellidos = pacienteResponse['apellidos'] as String? ?? '';
          _nombrePaciente = '$nombre $apellidos'.trim();
        }
      }

      // Cargar nombre del nutricionista
      if (nutricionistaId != null && nutricionistaId.isNotEmpty) {
        final nutriResponse = await supabaseService.client
            .from('nutricionistas')
            .select('nombre, apellidos')
            .eq('id', nutricionistaId)
            .maybeSingle();
        
        if (nutriResponse != null) {
          final nombre = nutriResponse['nombre'] as String? ?? '';
          final apellidos = nutriResponse['apellidos'] as String? ?? '';
          _nombreNutricionista = '$nombre $apellidos'.trim();
        }
      }

      // Parsear fecha de creación
      if (fechaCreacionStr != null && fechaCreacionStr.isNotEmpty) {
        try {
          _fechaCreacionPlan = DateTime.parse(fechaCreacionStr);
        } catch (e) {
          if (kDebugMode) {
            print('Error al parsear fecha de creación: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar datos del paciente y nutricionista: $e');
      }
    }
  }

  Future<void> _cargarPlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Si hay planId específico, cargar ese plan
      if (widget.planId != null && widget.planId!.isNotEmpty) {
        final planAsignado = await _planesService.obtenerPlanPorId(widget.planId!);

        if (planAsignado != null) {
          final planData = planAsignado['plan_editado'] ?? planAsignado['plan_generado'];

          if (planData != null) {
            Map<String, dynamic> planMap;
            if (planData is String) {
              planMap = jsonDecode(planData) as Map<String, dynamic>;
            } else {
              planMap = planData as Map<String, dynamic>;
            }

            final plan = PlanNutricional.fromSupabaseRow(planMap);
            
            // Obtener datos del paciente y nutricionista
            await _cargarDatosPacienteYNutricionista(
              planAsignado['paciente_id'] as String?,
              planAsignado['nutricionista_id'] as String?,
              planAsignado['created_at'] as String?,
            );
            
            setState(() {
              _plan = plan;
              _esPlanAsignado = true;
              _isLoading = false;
            });
            return;
          }
        }

        setState(() {
          _errorMessage = 'No se encontró el plan nutricional solicitado.';
          _isLoading = false;
        });
        return;
      }

      // Si hay pacienteId, intentar obtener el plan más reciente asignado
      if (widget.pacienteId != null && widget.pacienteId!.isNotEmpty) {
        final planAsignado = await _planesService.obtenerPlanPorPaciente(widget.pacienteId!);

        if (planAsignado != null) {
          final planData = planAsignado['plan_editado'] ?? planAsignado['plan_generado'];

          if (planData != null) {
            Map<String, dynamic> planMap;
            if (planData is String) {
              planMap = jsonDecode(planData) as Map<String, dynamic>;
            } else {
              planMap = planData as Map<String, dynamic>;
            }

            final plan = PlanNutricional.fromSupabaseRow(planMap);
            
            // Obtener datos del paciente y nutricionista
            await _cargarDatosPacienteYNutricionista(
              planAsignado['paciente_id'] as String?,
              planAsignado['nutricionista_id'] as String?,
              planAsignado['created_at'] as String?,
            );
            
            setState(() {
              _plan = plan;
              _esPlanAsignado = true;
              _isLoading = false;
            });
            return;
          }
        }

        setState(() {
          _errorMessage = 'Este paciente no tiene un plan nutricional asignado.';
          _isLoading = false;
        });
        return;
      }

      // Si no hay pacienteId ni planId, mostrar el primer plan de plantillas
      const planId = '143ac8c1-63c2-470d-a515-65ad7ab73034';
      PlanNutricional? plan = await _planService.obtenerPlanPorId(planId);

      if (plan == null) {
        final planes = await _planService.obtenerPlanesActivos();
        if (planes.isNotEmpty) {
          plan = planes.first;
        }
      }

      if (plan != null) {
        setState(() {
          _plan = plan;
          _esPlanAsignado = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se encontraron planes nutricionales activos';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar plan: $e');
      }
      setState(() {
        _errorMessage = 'Error al cargar el plan nutricional: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportarPDF() async {
    if (_plan == null) return;

    try {
      // Mostrar diálogo de carga más informativo
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Generando PDF...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _plan!.nombre,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Generar el PDF
      final pdf = await _generarPDF(_plan!);
      final pdfBytes = await pdf.save();

      // Obtener directorio más accesible (Descargas en Android, Documents en iOS)
      Directory? directory;
      String locationName;
      
      if (Platform.isAndroid) {
        // Intentar obtener el directorio de Descargas
        try {
          directory = await getExternalStorageDirectory();
          if (directory != null) {
            // Navegar a la carpeta Download
            final List<String> paths = directory.path.split('/');
            // Remover las últimas carpetas para llegar a /storage/emulated/0
            while (paths.length > 4 && !paths.contains('Android')) {
              paths.removeLast();
            }
            // Construir ruta a Download
            final downloadPath = '/storage/emulated/0/Download';
            directory = Directory(downloadPath);
            if (!await directory.exists()) {
              // Si no existe, usar el directorio externo
              directory = await getExternalStorageDirectory();
            }
            locationName = 'Descargas';
          } else {
            directory = await getApplicationDocumentsDirectory();
            locationName = 'Documentos de la app';
          }
        } catch (e) {
          // Si falla, usar documentos de la app
          directory = await getApplicationDocumentsDirectory();
          locationName = 'Documentos de la app';
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
        locationName = 'Documentos';
      }
      
      // Crear nombre de archivo más descriptivo con fecha
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      var cleanName = _plan!.nombre
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^\w\-_]'), '');
      if (cleanName.length > 30) {
        cleanName = cleanName.substring(0, 30);
      }
      final fileName = 'Plan_Nutricional_${cleanName}_$dateStr.pdf';
      final filePath = '${directory!.path}/$fileName';
      
      // Guardar el archivo PDF
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Guardar referencias para abrir el PDF
      final savedPdfBytes = pdfBytes;
      final savedFilePath = filePath; // Guardar la ruta del archivo

      // Mostrar diálogo de éxito con opciones
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text('PDF Guardado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El PDF se ha guardado exitosamente en:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubicación: $locationName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Abrir el PDF directamente en el visor usando el archivo guardado
                  try {
                    final result = await OpenFile.open(savedFilePath, type: 'application/pdf');
                    if (result.type != ResultType.done) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No se pudo abrir el PDF: ${result.message ?? "Error desconocido"}'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al abrir el PDF: ${e.toString()}'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, size: 20),
                label: const Text('Abrir PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Función para sanitizar texto y evitar caracteres problemáticos en PDF
  String _sanitizeTextForPDF(String text) {
    // Reemplazar caracteres problemáticos comunes
    return text
        .replaceAll('•', '-') // Reemplazar bullet por guion
        .replaceAll('–', '-') // En dash por guion
        .replaceAll('—', '-') // Em dash por guion
        .replaceAll('"', '"') // Comillas tipográficas por normales
        .replaceAll('"', '"')
        .replaceAll(''', "'") // Apostrofes tipográficos por normales
        .replaceAll(''', "'")
        .replaceAll('…', '...') // Elipsis por tres puntos
        .replaceAll('°', ' grados') // Símbolo de grados
        .replaceAll('½', '1/2') // Fracciones
        .replaceAll('¼', '1/4')
        .replaceAll('¾', '3/4')
        .replaceAll('⅓', '1/3')
        .replaceAll('⅔', '2/3');
  }

  Future<pw.Document> _generarPDF(PlanNutricional plan) async {
    final pdf = pw.Document();

    // Cargar el logo de la app (con manejo de errores)
    pw.ImageProvider? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/images/nuevo_icono.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar el logo: $e');
      }
      // Continuar sin logo si hay error
    }

    // Parsear grupos de alimentos
    final grupos = _parsearGruposAlimentos(plan.gruposAlimentos);

    // Formatear fecha de creación
    String fechaFormateada = '';
    if (_fechaCreacionPlan != null) {
      fechaFormateada = '${_fechaCreacionPlan!.day.toString().padLeft(2, '0')}/${_fechaCreacionPlan!.month.toString().padLeft(2, '0')}/${_fechaCreacionPlan!.year}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Encabezado con logo y datos
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo (solo si se cargó correctamente)
                if (logoImage != null) ...[
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(logoImage!, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 16),
                ],
                // Información del plan
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _sanitizeTextForPDF(plan.nombre),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _sanitizeTextForPDF(plan.descripcion),
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            
            // Información del paciente y nutricionista
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (_nombrePaciente != null && _nombrePaciente!.isNotEmpty)
                    pw.Row(
                      children: [
                        pw.Text(
                          'Paciente: ',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _sanitizeTextForPDF(_nombrePaciente!),
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  if (_nombrePaciente != null && _nombrePaciente!.isNotEmpty)
                    pw.SizedBox(height: 4),
                  if (_nombreNutricionista != null && _nombreNutricionista!.isNotEmpty)
                    pw.Row(
                      children: [
                        pw.Text(
                          'Nutricionista: ',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _sanitizeTextForPDF(_nombreNutricionista!),
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  if (_nombreNutricionista != null && _nombreNutricionista!.isNotEmpty)
                    pw.SizedBox(height: 4),
                  if (fechaFormateada.isNotEmpty)
                    pw.Row(
                      children: [
                        pw.Text(
                          'Fecha de creación: ',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          fechaFormateada,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Objetivo Principal
            pw.Text(
              'Objetivo Principal',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              _sanitizeTextForPDF(plan.objetivoPrincipal),
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 20),

            // Grupos de Alimentos - Tabla
            pw.Text(
              'Grupos de Alimentos',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),

            // Tabla de grupos de alimentos
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey700,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Encabezado de la tabla
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'GRUPOS DE ALIMENTOS',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'CANTIDAD DIARIA',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'ALIMENTOS PERMITIDOS',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'FORMAS DE PREPARACIÓN',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Filas de datos
                ...grupos.map((grupo) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          _sanitizeTextForPDF(grupo.grupo),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          _sanitizeTextForPDF(grupo.cantidadDiaria),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: grupo.alimentosPermitidos
                              .map((alimento) => pw.Padding(
                                    padding: const pw.EdgeInsets.only(bottom: 2),
                                    child: pw.Text(
                                      '- ${_sanitizeTextForPDF(alimento)}',
                                      style: const pw.TextStyle(fontSize: 8),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          _sanitizeTextForPDF(grupo.formasPreparacion),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  List<GrupoAlimento> _parsearGruposAlimentos(Map<String, dynamic> gruposData) {
    final List<GrupoAlimento> grupos = [];

    if (gruposData.containsKey('grupos') && gruposData['grupos'] is List) {
      final gruposList = gruposData['grupos'] as List;
      for (final grupoData in gruposList) {
        if (grupoData is Map<String, dynamic>) {
          grupos.add(GrupoAlimento.fromJson(grupoData));
        }
      }
    }

    return grupos;
  }

  Future<void> _editarPlan() async {
    try {
      final pacienteId = widget.pacienteId ?? 
          (widget.planId != null 
              ? await _obtenerPacienteIdDelPlan(widget.planId!)
              : null);
      
      if (pacienteId != null && _plan != null) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditarPlanNutricionalScreen(
              pacienteId: pacienteId,
              planId: widget.planId,
              planActual: _plan!,
            ),
          ),
        );
        if (result == true && mounted) {
          // Recargar el plan después de editar
          _cargarPlan();
        }
      } else {
        if (kDebugMode) {
          print('[PLAN_NUTRICIONAL] No se pudo obtener pacienteId o plan es null');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PLAN_NUTRICIONAL] Error al editar plan: $e');
      }
    }
  }

  Future<void> _handleBackButton() async {
    if (kDebugMode) {
      print('[PLAN_NUTRICIONAL] Botón de retroceso presionado. canPop: ${Navigator.of(context).canPop()}');
    }
    // Si hay rutas en el stack, hacer pop normal y retornar true para indicar actualización
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true); // Retornar true para indicar que se debe actualizar
      return;
    }
    // Si no hay rutas, navegar a la pantalla principal según el rol
    final user = supabaseService.client.auth.currentUser;
    if (user != null) {
      try {
        final nutriResponse = await supabaseService.client
            .from('nutricionistas')
            .select('id')
            .eq('auth_uid', user.id)
            .maybeSingle();
        
        if (nutriResponse != null) {
          // Es nutricionista
          if (mounted) {
            // Usar pushReplacement y luego forzar recarga después de un pequeño delay
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const NutricionistaPanel(),
                settings: const RouteSettings(name: '/nutricionista'),
              ),
            ).then((_) {
              // Forzar recarga después de que la navegación se complete
              // Usar un delay para asegurar que el widget esté completamente construido
              Future.delayed(const Duration(milliseconds: 100), () {
                if (kDebugMode) {
                  print('[PLAN_NUTRICIONAL] Navegación al dashboard completada - debería recargarse automáticamente');
                }
              });
            });
          }
        } else {
          // Es paciente
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const PacientePanel()),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('[PLAN_NUTRICIONAL] Error al verificar rol: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvoked: (didPop) async {
        if (didPop) {
          // Si se hizo pop, retornar true para indicar que se debe actualizar
          // Esto se capturará en la pantalla anterior
          if (kDebugMode) {
            print('[PLAN_NUTRICIONAL] Pop completado - se debe actualizar dashboard');
          }
        } else {
          // Si no se hizo pop, navegar a la pantalla principal
          await _handleBackButton();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plan Nutricional'),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          actions: [
            // Botón de Reportes (solo para nutricionistas)
            if (_esNutricionista)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.assessment),
                  onPressed: () {
                    if (kDebugMode) {
                      print('[PLAN_NUTRICIONAL] Botón de métricas presionado. Es nutricionista: $_esNutricionista');
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MetricasEvaluacionesScreen(),
                      ),
                    );
                  },
                  tooltip: 'Reportes',
                ),
              ),
            // Solo mostrar botón de editar si es nutricionista y es un plan asignado
            if (_esNutricionista && _plan != null && _esPlanAsignado && (widget.pacienteId != null || widget.planId != null))
              Builder(
                builder: (context) {
                  if (kDebugMode) {
                    print('[PLAN_NUTRICIONAL] Mostrando botón de editar. Plan: ${_plan != null}, Asignado: $_esPlanAsignado, PacienteId: ${widget.pacienteId}, PlanId: ${widget.planId}');
                  }
                  return IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      if (kDebugMode) {
                        print('[PLAN_NUTRICIONAL] Botón de editar presionado');
                      }
                      _editarPlan();
                    },
                    tooltip: 'Editar Plan',
                  );
                },
              ),
            if (_plan != null)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: _exportarPDF,
                  tooltip: 'Exportar PDF',
                ),
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
                        onPressed: _cargarPlan,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
                  : _plan == null
                  ? const Center(
                      child: Text('No se encontró el plan nutricional'),
                    )
                  : _buildPlanContent(),
      ),
    );
  }

  Widget _buildPlanContent() {
    final grupos = _parsearGruposAlimentos(_plan!.gruposAlimentos);

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16, // Margen para botones de navegación
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Card(
              color: Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plan!.nombre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _plan!.descripcion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Objetivo Principal
            const Text(
              'Objetivo Principal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _plan!.objetivoPrincipal,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grupos de Alimentos - Tabla
            const Text(
              'Grupos de Alimentos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Tabla de grupos de alimentos
            Card(
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 60,
                  dataRowMinHeight: 50,
                  dataRowMaxHeight: double.infinity,
                  columnSpacing: 20,
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFF4CAF50).withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'GRUPOS DE\nALIMENTOS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'CANTIDAD\nDIARIA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'ALIMENTOS\nPERMITIDOS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Text(
                          'FORMAS DE\nPREPARACIÓN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  rows: grupos.map((grupo) {
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(
                              grupo.grupo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Text(
                              grupo.cantidadDiaria,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 250,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: grupo.alimentosPermitidos
                                  .map((alimento) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '• $alimento',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 200,
                            child: Text(
                              grupo.formasPreparacion,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botón de exportar PDF
            Center(
              child: ElevatedButton.icon(
                onPressed: _exportarPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exportar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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


