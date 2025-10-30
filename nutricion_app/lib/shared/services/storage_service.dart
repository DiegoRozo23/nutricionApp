import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para almacenamiento local (SharedPreferences)
class StorageService {
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() => _instance;
  
  StorageService._internal();
  
  SharedPreferences? _prefs;
  
  /// Inicializar el servicio
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      print('StorageService initialized');
    }
  }
  
  /// Guardar un valor string
  Future<bool> saveString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }
  
  /// Obtener un valor string
  String? getString(String key) {
    return _prefs?.getString(key);
  }
  
  /// Guardar un valor boolean
  Future<bool> saveBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }
  
  /// Obtener un valor boolean
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }
  
  /// Guardar un valor int
  Future<bool> saveInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }
  
  /// Obtener un valor int
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }
  
  /// Eliminar una clave
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }
  
  /// Limpiar todo el almacenamiento
  Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }
  
  /// Verificar si existe una clave
  bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
  
  // Métodos específicos para la app
  
  /// Guardar token de sesión
  Future<bool> saveAuthToken(String token) async {
    return await saveString('auth_token', token);
  }
  
  /// Obtener token de sesión
  String? getAuthToken() {
    return getString('auth_token');
  }
  
  /// Guardar usuario actual
  Future<bool> saveCurrentUser(String userJson) async {
    return await saveString('current_user', userJson);
  }
  
  /// Obtener usuario actual
  String? getCurrentUser() {
    return getString('current_user');
  }
  
  /// Guardar si se debe recordar sesión
  Future<bool> saveRememberMe(bool remember) async {
    return await saveBool('remember_me', remember);
  }
  
  /// Obtener si se debe recordar sesión
  bool getRememberMe() {
    return getBool('remember_me') ?? false;
  }
}

/// Singleton instance
final storageService = StorageService();

