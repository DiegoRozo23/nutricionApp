import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paciente_model.dart';
import '../../../../shared/services/supabase_service.dart';

/// Excepción personalizada para errores de pacientes
class PacientesException implements Exception {
  final String message;
  final String? code;

  PacientesException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Datasource remoto para pacientes
/// 
/// Este datasource maneja toda la comunicación con Supabase
/// para operaciones CRUD de pacientes
abstract class PacientesRemoteDataSource {
  /// Obtener todos los pacientes del nutricionista actual
  Future<List<PacienteModel>> obtenerPacientes();

  /// Obtener un paciente por ID
  Future<PacienteModel> obtenerPacientePorId(String id);

  /// Crear un nuevo paciente
  Future<PacienteModel> crearPaciente(PacienteModel paciente);

  /// Actualizar un paciente existente
  Future<PacienteModel> actualizarPaciente(PacienteModel paciente);

  /// Eliminar un paciente
  Future<void> eliminarPaciente(String id);
}

/// Implementación del datasource remoto
class PacientesRemoteDataSourceImpl implements PacientesRemoteDataSource {
  final SupabaseClient supabase;

  PacientesRemoteDataSourceImpl({
    SupabaseClient? supabase,
  }) : supabase = supabase ?? supabaseService.client;

  @override
  Future<List<PacienteModel>> obtenerPacientes() async {
    try {
      // Obtener el nutricionista actual
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw PacientesException('No hay usuario autenticado');
      }

      // Buscar el nutricionista por auth_uid
      final nutriData = await supabase
          .from('nutricionistas')
          .select('id')
          .eq('auth_uid', user.id)
          .single();

      final nutricionistaId = nutriData['id'] as String;

      // Obtener pacientes del nutricionista
      final pacientesData = await supabase
          .from('pacientes')
          .select()
          .eq('nutricionista_id', nutricionistaId)
          .order('created_at', ascending: false);

      return (pacientesData as List)
          .map((data) => PacienteModel.fromSupabaseRow(data as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      throw PacientesException(
        'Error al obtener pacientes: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      throw PacientesException('Error al obtener pacientes: ${e.toString()}');
    }
  }

  @override
  Future<PacienteModel> obtenerPacientePorId(String id) async {
    try {
      final pacienteData = await supabase
          .from('pacientes')
          .select()
          .eq('id', id)
          .single();

      return PacienteModel.fromSupabaseRow(pacienteData);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      
      if (e.code == 'PGRST116' || e.message.contains('No rows')) {
        throw PacientesException('Paciente no encontrado', code: e.code);
      }
      
      throw PacientesException(
        'Error al obtener paciente: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      throw PacientesException('Error al obtener paciente: ${e.toString()}');
    }
  }

  @override
  Future<PacienteModel> crearPaciente(PacienteModel paciente) async {
    try {
      // Obtener el nutricionista actual
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw PacientesException('No hay usuario autenticado');
      }

      // Buscar el nutricionista por auth_uid
      final nutriData = await supabase
          .from('nutricionistas')
          .select('id')
          .eq('auth_uid', user.id)
          .single();

      final nutricionistaId = nutriData['id'] as String;

      // Preparar datos para insertar (sin id, fechas se generan automáticamente)
      final dataToInsert = {
        'nutricionista_id': nutricionistaId,
        'nombre': paciente.nombre,
        'apellidos': paciente.apellidos,
        if (paciente.dni != null) 'dni': paciente.dni,
        if (paciente.sexo != null) 'sexo': paciente.sexo,
        if (paciente.edad != null) 'edad': paciente.edad,
        if (paciente.peso != null) 'peso': paciente.peso,
        if (paciente.talla != null) 'talla': paciente.talla,
        if (paciente.imc != null) 'imc': paciente.imc,
        if (paciente.medidasAntropometricas != null)
          'medidas_antropometricas': paciente.medidasAntropometricas,
        if (paciente.historialMedico != null)
          'historial_medico': paciente.historialMedico,
        if (paciente.observaciones != null) 'observaciones': paciente.observaciones,
        'activo': paciente.activo,
      };

      final insertedData = await supabase
          .from('pacientes')
          .insert(dataToInsert)
          .select()
          .single();

      return PacienteModel.fromSupabaseRow(insertedData);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      
      // Manejar errores de validación únicos (DNI duplicado, etc.)
      if (e.message.contains('duplicate key') || e.message.contains('unique')) {
        throw PacientesException('El DNI ya está registrado', code: e.code);
      }
      
      throw PacientesException(
        'Error al crear paciente: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      throw PacientesException('Error al crear paciente: ${e.toString()}');
    }
  }

  @override
  Future<PacienteModel> actualizarPaciente(PacienteModel paciente) async {
    try {
      // Preparar datos para actualizar (solo campos que se pueden modificar)
      final dataToUpdate = <String, dynamic>{
        'nombre': paciente.nombre,
        'apellidos': paciente.apellidos,
        if (paciente.dni != null) 'dni': paciente.dni,
        if (paciente.sexo != null) 'sexo': paciente.sexo,
        if (paciente.edad != null) 'edad': paciente.edad,
        if (paciente.peso != null) 'peso': paciente.peso,
        if (paciente.talla != null) 'talla': paciente.talla,
        if (paciente.imc != null) 'imc': paciente.imc,
        if (paciente.medidasAntropometricas != null)
          'medidas_antropometricas': paciente.medidasAntropometricas,
        if (paciente.historialMedico != null)
          'historial_medico': paciente.historialMedico,
        if (paciente.observaciones != null) 'observaciones': paciente.observaciones,
        'activo': paciente.activo,
        // updated_at se actualiza automáticamente por el trigger
      };

      final updatedData = await supabase
          .from('pacientes')
          .update(dataToUpdate)
          .eq('id', paciente.id)
          .select()
          .single();

      return PacienteModel.fromSupabaseRow(updatedData);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      
      if (e.code == 'PGRST116' || e.message.contains('No rows')) {
        throw PacientesException('Paciente no encontrado', code: e.code);
      }
      
      throw PacientesException(
        'Error al actualizar paciente: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      throw PacientesException('Error al actualizar paciente: ${e.toString()}');
    }
  }

  @override
  Future<void> eliminarPaciente(String id) async {
    try {
      await supabase.from('pacientes').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Error de Postgrest: ${e.message}');
      }
      throw PacientesException(
        'Error al eliminar paciente: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      throw PacientesException('Error al eliminar paciente: ${e.toString()}');
    }
  }
}

