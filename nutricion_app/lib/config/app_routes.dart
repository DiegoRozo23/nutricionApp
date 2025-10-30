import 'package:flutter/material.dart';

/// Clase para gestionar las rutas de la aplicación
class AppRoutes {
  // Rutas con nombre
  static const String login = '/login';
  static const String nutricionistaPanel = '/nutricionista';
  static const String pacientePanel = '/paciente';
  
  // Rutas de pacientes
  static const String pacientesList = '/pacientes/list';
  static const String pacienteDetail = '/pacientes/detail';
  static const String pacienteCreate = '/pacientes/create';
  
  // Rutas de planes
  static const String planesList = '/planes/list';
  static const String planCreate = '/planes/create';
  static const String planEdit = '/planes/edit';
  
  // Rutas de chat
  static const String chatList = '/chat/list';
  static const String chatDetail = '/chat/detail';
  
  /// Navegación helper para login
  static Future<void> goToLogin(BuildContext context) {
    return Navigator.of(context).pushReplacementNamed(login);
  }
  
  /// Navegación helper para panel de nutricionista
  static Future<void> goToNutricionistaPanel(BuildContext context) {
    return Navigator.of(context).pushReplacementNamed(nutricionistaPanel);
  }
  
  /// Navegación helper para panel de paciente
  static Future<void> goToPacientePanel(BuildContext context) {
    return Navigator.of(context).pushReplacementNamed(pacientePanel);
  }
}

