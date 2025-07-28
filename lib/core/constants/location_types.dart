/// **CONSTANTES: Tipos de Ubicación**
///
/// Definiciones de tipos de ubicación que coinciden exactamente
/// con las constantes del backend.
///
/// Estas deben mantenerse sincronizadas con:
/// - Backend: LOCATION_TYPES
/// - Base de datos: location_types table
class LocationTypes {
  /// Trabajo remoto desde domicilio declarado
  static const int REMOTE_DECLARED = 1;
  
  /// Trabajo remoto desde ubicación alternativa (dirección especificada por el usuario)
  static const int REMOTE_ALTERNATIVE = 2;
  
  /// Trabajo en ubicación del cliente
  static const int CLIENT = 3;
  
  /// Trabajo en oficina de la empresa
  static const int OFFICE = 4;

  /// Mapeo de IDs a nombres descriptivos en español
  static const Map<int, String> names = {
    REMOTE_DECLARED: 'Domicilio',
    REMOTE_ALTERNATIVE: 'Domicilio Alternativo',
    CLIENT: 'Cliente',
    OFFICE: 'Oficina',
  };

  /// Mapeo de IDs a descripciones más detalladas
  static const Map<int, String> descriptions = {
    REMOTE_DECLARED: 'Trabajar desde el domicilio registrado',
    REMOTE_ALTERNATIVE: 'Trabajar desde un domicilio alternativo (especificar dirección)',
    CLIENT: 'Trabajar en las instalaciones del cliente',
    OFFICE: 'Trabajar en la oficina de la empresa',
  };

  /// Verifica si un tipo de ubicación requiere dirección personalizada
  static bool requiresCustomAddress(int locationType) {
    return locationType == REMOTE_ALTERNATIVE;
  }

  /// Verifica si un tipo de ubicación es válido
  static bool isValid(int locationType) {
    return names.containsKey(locationType);
  }

  /// Obtiene el nombre de un tipo de ubicación
  static String getName(int locationType) {
    return names[locationType] ?? 'Desconocido';
  }

  /// Obtiene la descripción de un tipo de ubicación
  static String getDescription(int locationType) {
    return descriptions[locationType] ?? 'Tipo de ubicación no válido';
  }

  /// Lista de todos los tipos de ubicación disponibles
  static List<int> get allTypes => [
    REMOTE_DECLARED,
    REMOTE_ALTERNATIVE,
    CLIENT,
    OFFICE,
  ];
}
