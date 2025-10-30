/// Constantes de la aplicación
class AppConstants {
  // Roles de usuario
  static const String roleNutricionista = 'nutricionista';
  static const String rolePaciente = 'paciente';
  
  // Storage keys
  static const String keyAuthToken = 'auth_token';
  static const String keyCurrentUser = 'current_user';
  static const String keyRememberMe = 'remember_me';
  
  // Validaciones
  static const int minPasswordLength = 4;
  static const int maxPasswordLength = 50;
  
  // Errores comunes
  static const String errorEmptyField = 'Este campo no puede estar vacío';
  static const String errorInvalidCredentials = 'Credenciales inválidas';
  static const String errorNetworkError = 'Error de conexión. Intenta de nuevo.';
  static const String errorGeneric = 'Ocurrió un error. Intenta de nuevo.';
  
  // Mensajes de éxito
  static const String successLogin = 'Inicio de sesión exitoso';
  static const String successLogout = 'Sesión cerrada correctamente';
  
  // Sizes
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  
  // Api endpoints (cuando se implemente)
  static const String apiBaseUrl = 'https://api.nutricion.app'; // TODO: Cambiar por URL real
}

/// Clase para validaciones comunes
class Validators {
  /// Validar si un string no está vacío
  static String? notEmpty(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Este campo'} no puede estar vacío';
    }
    return null;
  }
  
  /// Validar longitud mínima
  static String? minLength(String? value, int length, {String? fieldName}) {
    if (value != null && value.length < length) {
      return '${fieldName ?? 'Este campo'} debe tener al menos $length caracteres';
    }
    return null;
  }
  
  /// Validar longitud máxima
  static String? maxLength(String? value, int length, {String? fieldName}) {
    if (value != null && value.length > length) {
      return '${fieldName ?? 'Este campo'} no puede tener más de $length caracteres';
    }
    return null;
  }
  
  /// Validar DNI
  static String? dni(String? value) {
    if (value == null || value.isEmpty) {
      return 'El DNI no puede estar vacío';
    }
    if (value.length < 8) {
      return 'El DNI debe tener al menos 8 caracteres';
    }
    return null;
  }
  
  /// Validar contraseña
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña no puede estar vacía';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres';
    }
    return null;
  }
}

