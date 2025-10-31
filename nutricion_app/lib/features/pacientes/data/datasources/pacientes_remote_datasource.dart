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
  /// [password] es la contraseña inicial para crear la cuenta en Supabase Auth
  Future<PacienteModel> crearPaciente(PacienteModel paciente, {String? password});

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
  Future<PacienteModel> crearPaciente(PacienteModel paciente, {String? password}) async {
    try {
      // Validar que se proporciona password al crear
      if (password == null || password.isEmpty) {
        throw PacientesException('La contraseña inicial es obligatoria');
      }

      // Validar que se proporciona DNI
      if (paciente.dni == null || paciente.dni!.isEmpty) {
        throw PacientesException('El DNI es obligatorio para crear un paciente');
      }

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

      // Paso 1: Crear cuenta en Supabase Auth
      // Usamos el DNI como email (formato: pacienteDNI@app.com)
      // Esto permite que el paciente inicie sesión con DNI y contraseña
      // Nota: Supabase requiere un email válido con formato estándar
      final email = 'paciente${paciente.dni}@app.com';
      
      // Crear usuario en Supabase Auth con auto-confirmación
      // Usamos emailRedirectTo para evitar el flujo de verificación de email
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // No necesitamos redirect
        data: {
          'dni': paciente.dni,
          'nombre': paciente.nombre,
          'apellidos': paciente.apellidos,
          'role': 'paciente',
        },
        // Importante: Esto auto-confirma el email si está habilitado en Supabase
      );

      if (authResponse.user == null) {
        throw PacientesException('Error al crear la cuenta de usuario');
      }

      final authUid = authResponse.user!.id;

      // Paso 2: Insertar paciente en la tabla con auth_uid
      final dataToInsert = {
        'auth_uid': authUid,
        'nutricionista_id': nutricionistaId,
        'nombre': paciente.nombre,
        'apellidos': paciente.apellidos,
        'dni': paciente.dni,
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

      // Insertar paciente y obtener los datos insertados
      final response = await supabase
          .from('pacientes')
          .insert(dataToInsert)
          .select();

      // Verificar que se insertó correctamente
      if (response == null || response.isEmpty) {
        throw PacientesException('Error al crear el paciente en la base de datos');
      }

      // Obtener el primer resultado (debería ser el único)
      final insertedData = response.first as Map<String, dynamic>;

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

