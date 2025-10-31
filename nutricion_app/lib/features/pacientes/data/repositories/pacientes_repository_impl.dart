import 'package:flutter/foundation.dart';
import '../../domain/repositories/pacientes_repository.dart';
import '../../domain/entities/paciente.dart';
import '../models/paciente_model.dart';
import '../datasources/pacientes_remote_datasource.dart';

/// Implementación del repositorio de pacientes
/// 
/// Esta clase coordina las llamadas entre el dominio y las fuentes de datos
class PacientesRepositoryImpl implements PacientesRepository {
  final PacientesRemoteDataSource remoteDataSource;

  PacientesRepositoryImpl({
    PacientesRemoteDataSource? remoteDataSource,
  }) : remoteDataSource = remoteDataSource ?? PacientesRemoteDataSourceImpl();

  @override
  Future<PacientesResult<List<Paciente>>> obtenerPacientes() async {
    try {
      final pacientes = await remoteDataSource.obtenerPacientes();
      final entities = pacientes.map((model) => model.toEntity()).toList();
      return PacientesSuccess(entities);
    } on PacientesException catch (e) {
      if (kDebugMode) {
        print('Error al obtener pacientes: ${e.message}');
      }
      return PacientesFailure(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      return PacientesFailure(
        message: 'Error al obtener pacientes',
      );
    }
  }

  @override
  Future<PacientesResult<Paciente>> obtenerPacientePorId(String id) async {
    try {
      final paciente = await remoteDataSource.obtenerPacientePorId(id);
      return PacientesSuccess(paciente.toEntity());
    } on PacientesException catch (e) {
      if (kDebugMode) {
        print('Error al obtener paciente: ${e.message}');
      }
      return PacientesFailure(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      return PacientesFailure(
        message: 'Error al obtener paciente',
      );
    }
  }

  @override
  Future<PacientesResult<Paciente>> crearPaciente(Paciente paciente, {String? password}) async {
    try {
      // Convertir entidad a modelo para el datasource
      final model = PacienteModel(
        id: paciente.id,
        authUid: paciente.authUid,
        nutricionistaId: paciente.nutricionistaId,
        nombre: paciente.nombre,
        apellidos: paciente.apellidos,
        dni: paciente.dni,
        sexo: paciente.sexo,
        edad: paciente.edad,
        peso: paciente.peso,
        talla: paciente.talla,
        imc: paciente.imc,
        medidasAntropometricas: paciente.medidasAntropometricas,
        historialMedico: paciente.historialMedico,
        observaciones: paciente.observaciones,
        activo: paciente.activo,
        createdAt: paciente.createdAt,
        updatedAt: paciente.updatedAt,
      );

      final createdPaciente = await remoteDataSource.crearPaciente(model, password: password);
      return PacientesSuccess(createdPaciente.toEntity());
    } on PacientesException catch (e) {
      if (kDebugMode) {
        print('Error al crear paciente: ${e.message}');
      }
      return PacientesFailure(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      return PacientesFailure(
        message: 'Error al crear paciente',
      );
    }
  }

  @override
  Future<PacientesResult<Paciente>> actualizarPaciente(Paciente paciente) async {
    try {
      // Convertir entidad a modelo para el datasource
      final model = PacienteModel(
        id: paciente.id,
        authUid: paciente.authUid,
        nutricionistaId: paciente.nutricionistaId,
        nombre: paciente.nombre,
        apellidos: paciente.apellidos,
        dni: paciente.dni,
        sexo: paciente.sexo,
        edad: paciente.edad,
        peso: paciente.peso,
        talla: paciente.talla,
        imc: paciente.imc,
        medidasAntropometricas: paciente.medidasAntropometricas,
        historialMedico: paciente.historialMedico,
        observaciones: paciente.observaciones,
        activo: paciente.activo,
        createdAt: paciente.createdAt,
        updatedAt: paciente.updatedAt,
      );

      final updatedPaciente = await remoteDataSource.actualizarPaciente(model);
      return PacientesSuccess(updatedPaciente.toEntity());
    } on PacientesException catch (e) {
      if (kDebugMode) {
        print('Error al actualizar paciente: ${e.message}');
      }
      return PacientesFailure(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      return PacientesFailure(
        message: 'Error al actualizar paciente',
      );
    }
  }

  @override
  Future<PacientesResult<void>> eliminarPaciente(String id) async {
    try {
      await remoteDataSource.eliminarPaciente(id);
      return PacientesSuccess(null);
    } on PacientesException catch (e) {
      if (kDebugMode) {
        print('Error al eliminar paciente: ${e.message}');
      }
      return PacientesFailure(
        message: e.message,
        code: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado: $e');
      }
      return PacientesFailure(
        message: 'Error al eliminar paciente',
      );
    }
  }
}

