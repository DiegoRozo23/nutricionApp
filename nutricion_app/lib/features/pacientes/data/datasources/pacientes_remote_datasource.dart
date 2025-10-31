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
      final nutriResponse = await supabase
          .from('nutricionistas')
          .select('id')
          .eq('auth_uid', user.id);

      if (nutriResponse == null || nutriResponse.isEmpty) {
        throw PacientesException('Nutricionista no encontrado en la base de datos');
      }

      final nutriData = nutriResponse.first as Map<String, dynamic>;
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
      final pacienteResponse = await supabase
          .from('pacientes')
          .select()
          .eq('id', id);

      if (pacienteResponse == null || pacienteResponse.isEmpty) {
        throw PacientesException('Paciente no encontrado', code: 'PGRST116');
      }

      final pacienteData = pacienteResponse.first as Map<String, dynamic>;
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

      // 🔍 DEBUG: Verificar el auth.uid() real desde Flutter
      if (kDebugMode) {
        print('🧠 Usuario actual en Supabase Auth: ${user.id}');
      }

      // Buscar el nutricionista por auth_uid
      final nutriResponse = await supabase
          .from('nutricionistas')
          .select('id, auth_uid, email')
          .eq('auth_uid', user.id);

      if (nutriResponse == null || nutriResponse.isEmpty) {
        // 🔍 DEBUG: Mostrar información adicional si no se encuentra
        if (kDebugMode) {
          print('❌ ERROR: Nutricionista no encontrado con auth_uid: ${user.id}');
          print('💡 Verifica que el auth_uid en la tabla nutricionistas coincida con este UUID');
          print('💡 Ejecuta en Supabase SQL Editor:');
          print('   SELECT id, auth_uid, email FROM nutricionistas;');
          print('   UPDATE nutricionistas SET auth_uid = \'${user.id}\' WHERE email = \'TU_EMAIL_AQUI\';');
        }
        throw PacientesException(
          'Nutricionista no encontrado. Verifica que el auth_uid en la tabla nutricionistas coincida con tu usuario autenticado.'
        );
      }

      final nutriData = nutriResponse.first as Map<String, dynamic>;
      final nutricionistaId = nutriData['id'] as String;
      
      // 🔍 DEBUG: Confirmar que se encontró el nutricionista
      if (kDebugMode) {
        print('✅ Nutricionista encontrado: id=${nutriData['id']}, email=${nutriData['email']}');
      }

      // Paso 1: Crear cuenta en Supabase Auth (solo DNI y contraseña)
      // Usamos el DNI como email (formato: pacienteDNI@app.com)
      final email = 'paciente${paciente.dni}@app.com';
      
      if (kDebugMode) {
        print('📝 Creando usuario en Supabase Auth con DNI: ${paciente.dni}');
      }
      
      // Crear usuario en Supabase Auth (mínimo necesario)
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
        data: {
          'dni': paciente.dni,
          'role': 'paciente',
        },
      );

      if (authResponse.user == null) {
        throw PacientesException('Error al crear la cuenta de usuario');
      }

      final authUid = authResponse.user!.id;

      if (kDebugMode) {
        print('✅ Usuario creado en Auth con UUID: $authUid');
      }

      // Paso 2: Insertar paciente con solo datos mínimos (DNI, nutricionista_id, auth_uid)
      // Esto evita problemas con RLS al tener demasiados campos a la vez
      if (kDebugMode) {
        print('📝 Insertando paciente con datos mínimos en tabla...');
      }

      final dataMinimo = {
        'auth_uid': authUid,
        'nutricionista_id': nutricionistaId,
        'dni': paciente.dni,
        'activo': true, // Por defecto activo
      };

      // Insertar paciente con solo datos mínimos
      final response = await supabase
          .from('pacientes')
          .insert(dataMinimo)
          .select();

      // Verificar que se insertó correctamente
      if (response == null || response.isEmpty) {
        throw PacientesException('Error al crear el paciente en la base de datos');
      }

      // Obtener el primer resultado (debería ser el único)
      final insertedData = response.first as Map<String, dynamic>;
      final pacienteId = insertedData['id'] as String;

      if (kDebugMode) {
        print('✅ Paciente creado con ID: $pacienteId');
      }

      // Paso 3: Actualizar el paciente con el resto de los datos
      // Esto se hace en un UPDATE separado para evitar problemas con RLS
      if (kDebugMode) {
        print('📝 Actualizando paciente con datos completos...');
      }

      final dataCompleto = <String, dynamic>{
        'nombre': paciente.nombre,
        'apellidos': paciente.apellidos,
      };

      // Agregar campos opcionales solo si tienen valor
      if (paciente.sexo != null) dataCompleto['sexo'] = paciente.sexo;
      if (paciente.edad != null) dataCompleto['edad'] = paciente.edad;
      if (paciente.peso != null) dataCompleto['peso'] = paciente.peso;
      if (paciente.talla != null) dataCompleto['talla'] = paciente.talla;
      if (paciente.imc != null) dataCompleto['imc'] = paciente.imc;
      if (paciente.medidasAntropometricas != null) {
        dataCompleto['medidas_antropometricas'] = paciente.medidasAntropometricas;
      }
      if (paciente.historialMedico != null) {
        dataCompleto['historial_medico'] = paciente.historialMedico;
      }
      if (paciente.observaciones != null) {
        dataCompleto['observaciones'] = paciente.observaciones;
      }
      dataCompleto['activo'] = paciente.activo;

      // Actualizar con todos los datos
      final updateResponse = await supabase
          .from('pacientes')
          .update(dataCompleto)
          .eq('id', pacienteId)
          .select();

      if (updateResponse == null || updateResponse.isEmpty) {
        // Si falla la actualización, al menos el paciente básico ya está creado
        if (kDebugMode) {
          print('⚠️ Paciente creado pero no se pudieron actualizar todos los datos');
        }
        // Retornar el paciente con los datos mínimos
        return PacienteModel.fromSupabaseRow(insertedData);
      }

      final updatedData = updateResponse.first as Map<String, dynamic>;
      
      if (kDebugMode) {
        print('✅ Paciente actualizado completamente');
      }

      return PacienteModel.fromSupabaseRow(updatedData);
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

      final updatedResponse = await supabase
          .from('pacientes')
          .update(dataToUpdate)
          .eq('id', paciente.id)
          .select();

      if (updatedResponse == null || updatedResponse.isEmpty) {
        throw PacientesException('Paciente no encontrado');
      }

      final updatedData = updatedResponse.first as Map<String, dynamic>;
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

