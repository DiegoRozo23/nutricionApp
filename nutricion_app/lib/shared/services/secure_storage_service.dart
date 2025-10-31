import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio para almacenamiento seguro (contraseñas, tokens sensibles)
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  
  factory SecureStorageService() => _instance;
  
  SecureStorageService._internal();
  
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  /// Guardar un valor de forma segura
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  /// Leer un valor de forma segura
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  /// Eliminar un valor
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  /// Eliminar todos los valores
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
  
  /// Guardar contraseña de forma segura para "Recordar"
  Future<void> savePassword(String role, String password) async {
    await write('saved_password_$role', password);
  }
  
  /// Obtener contraseña guardada
  Future<String?> getPassword(String role) async {
    return await read('saved_password_$role');
  }
  
  /// Eliminar contraseña guardada
  Future<void> removePassword(String role) async {
    await delete('saved_password_$role');
  }
}

/// Singleton instance
final secureStorageService = SecureStorageService();

