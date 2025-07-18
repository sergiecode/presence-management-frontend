/// Constantes globales de la aplicación Tareas
///
/// Este archivo contiene todas las constantes que se usan en toda la aplicación,
/// como URLs de API, colores corporativos, configuraciones, etc.
///
/// Autor: Equipo Gold
/// Fecha: 2025
library;

import 'package:flutter/material.dart';

/// Configuración de la API
class ApiConstants {
  /// URL base de la API del backend
  /// Nota: Para Android, usar 10.0.2.2 en lugar de localhost
  static const String baseUrl = 'http://10.0.2.2:8080';
  
  /// URL alternativa en caso de problemas de conexión
  static const String alternativeBaseUrl = 'http://localhost:8080';

  /// Endpoints de autenticación (sin prefijo /api)
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';

  /// Endpoints de usuario (con prefijo /api)
  static const String userMeEndpoint = '/api/users/me';
  static const String userUpdateEndpoint = '/api/users';
  static const String userAvatarEndpoint = '/api/users/avatar';

  /// Endpoints de check-in/check-out (con prefijo /api)
  static const String checkinsEndpoint = '/api/checkins';
  static const String checkinsEndpointWithSlash = '/api/checkins/'; // Variante con barra final
  static const String checkinTodayEndpoint = '/api/checkins/today';
  static const String checkoutEndpoint = '/api/checkins/checkout';

  /// Endpoints de ausencias (con prefijo /api)
  static const String absencesEndpoint = '/api/absences';
  static const String absenceDocumentEndpoint =
      '/api/absences'; // Para /{id}/documents

  /// Tiempo de espera para las peticiones HTTP (en segundos)
  static const int timeoutDuration = 30;
}

/// Colores corporativos de Tareas
class AppColors {
  /// Color principal de la marca Tareas (naranja)
  static const Color primary = Color(0xFFE67D21);

  /// Variaciones del color principal
  static const Color primaryLight = Color(0xFFFF9E4D);
  static const Color primaryDark = Color(0xFFB85C00);

  /// Colores de fondo
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  /// Colores de texto
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  /// Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  /// Colores específicos para estados de asistencia
  static const Color checkedIn = Color(0xFF4CAF50);
  static const Color checkedOut = Color(0xFFF44336);
  static const Color pending = Color(0xFFFF9800);

  /// Colores para estados de usuario
  static const Map<String, Color> userStatusColors = {
    'active': Colors.green,
    'inactive': Colors.grey,
    'pending': Colors.orange,
    'deactivated': Colors.red,
  };
}

/// Configuraciones de estilo
class AppStyles {
  /// Radio de bordes redondeados estándar
  static const double borderRadius = 12.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 16.0;

  /// Espaciado estándar
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  /// Tamaños de fuente
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeTitle = 24.0;

  /// Elevación para sombras
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}

/// Configuraciones de animación
class AppAnimations {
  /// Duración estándar de animaciones
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  /// Curvas de animación
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceOut;
}

/// Configuraciones de la aplicación
class AppConfig {
  /// Nombre de la aplicación
  static const String appName = 'Tareas Asistencia';

  /// Versión de la aplicación
  static const String appVersion = '1.0.0';

  /// Configuraciones de check-in
  static const List<String> locationTypes = [
    'office',
    'home',
    'client',
    'other',
  ];

  /// Etiquetas legibles para tipos de ubicación
  static const Map<String, String> locationLabels = {
    'office': 'Oficina',
    'home': 'Domicilio',
    'client': 'Cliente',
    'other': 'Otro',
  };

  /// Tipos de ausencia disponibles
  static const List<String> absenceTypes = [
    'absence',
    'medical',
    'vacation',
    'personal',
  ];

  /// Etiquetas legibles para tipos de ausencia
  static const Map<String, String> absenceLabels = {
    'absence': 'Ausencia',
    'medical': 'Permiso Médico',
    'vacation': 'Vacaciones',
    'personal': 'Permiso Personal',
  };

  /// Iconos para tipos de ausencia
  static const Map<String, IconData> absenceIcons = {
    'absence': Icons.event_busy,
    'medical': Icons.medical_services,
    'vacation': Icons.beach_access,
    'personal': Icons.person,
  };

  /// Colores para tipos de ausencia
  static const Map<String, Color> absenceColors = {
    'absence': Colors.orange,
    'medical': Colors.red,
    'vacation': Colors.blue,
    'personal': Colors.green,
  };

  /// Estados de ausencia disponibles
  static const List<String> absenceStatuses = [
    'pending',
    'approved',
    'rejected',
  ];

  /// Tipos de ausencia que requieren documentos adjuntos
  static const List<String> absenceTypesRequiringDocuments = [
    'medical', // Permiso médico siempre requiere documento
    'absence', // Ausencia justificada puede requerir documento
  ];

  /// Extensiones de archivo válidas para documentos de ausencia
  static const List<String> validDocumentExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
  ];

  /// Tamaño máximo para documentos de ausencia (en bytes) - 5MB
  static const int maxDocumentSize = 5 * 1024 * 1024;

  /// Etiquetas legibles para estados de ausencia
  static const Map<String, String> absenceStatusLabels = {
    'pending': 'Pendiente',
    'approved': 'Aprobada',
    'rejected': 'Rechazada',
  };

  /// Colores para estados de ausencia
  static const Map<String, Color> absenceStatusColors = {
    'pending': Colors.orange,
    'approved': Colors.green,
    'rejected': Colors.red,
  };

  /// Iconos para estados de ausencia
  static const Map<String, IconData> absenceStatusIcons = {
    'pending': Icons.hourglass_empty,
    'approved': Icons.check_circle,
    'rejected': Icons.cancel,
  };

  /// Etiquetas para roles de usuario
  static const Map<String, String> userRoleLabels = {
    'admin': 'Administrador',
    'manager': 'Gerente',
    'employee': 'Empleado',
    'supervisor': 'Supervisor',
  };

  /// Iconos para roles de usuario
  static const Map<String, IconData> userRoleIcons = {
    'admin': Icons.admin_panel_settings,
    'manager': Icons.supervisor_account,
    'employee': Icons.person,
    'supervisor': Icons.manage_accounts,
  };

  /// Configuraciones para campos del usuario
  static const Map<String, bool> userFieldsEditability = {
    'name': true,
    'surname': true,
    'email': false, // Generalmente no editable
    'phone': true,
    'picture': true,
    'role': false, // Solo admin puede cambiar
    'timezone': true,
    'notification_offset_min': true,
    'checkin_start_time': true,
    'email_confirmed': false, // Solo lectura
    'deactivated': false, // Solo admin
    'pending_approval': false, // Solo lectura
  };

  /// Configuraciones para validación de imágenes
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
  ];
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
}

/// Mensajes de error estándar
class ErrorMessages {
  /// Errores de red
  static const String networkError =
      'Error de conexión. Verifique su conexión a internet.';
  static const String timeoutError =
      'La operación tardó demasiado. Intente nuevamente.';
  static const String serverError = 'Error del servidor. Intente más tarde.';

  /// Errores de autenticación
  static const String invalidCredentials =
      'Credenciales inválidas. Verifique su email y contraseña.';
  static const String sessionExpired =
      'Su sesión ha expirado. Inicie sesión nuevamente.';
  static const String accessDenied =
      'Acceso denegado. No tiene permisos para esta operación.';

  /// Errores de validación
  static const String requiredField = 'Este campo es obligatorio.';
  static const String invalidEmail = 'Ingrese un email válido.';
  static const String passwordTooShort =
      'La contraseña debe tener al menos 6 caracteres.';
  static const String passwordsDoNotMatch = 'Las contraseñas no coinciden.';

  /// Errores específicos de la aplicación
  static const String checkinError =
      'Error al registrar entrada. Intente nuevamente.';
  static const String checkoutError =
      'Error al registrar salida. Intente nuevamente.';
  static const String profileUpdateError =
      'Error al actualizar perfil. Intente nuevamente.';
  static const String absenceCreateError =
      'Error al crear ausencia. Intente nuevamente.';
}

/// Mensajes de éxito
class SuccessMessages {
  static const String checkinSuccess = 'Entrada registrada exitosamente.';
  static const String checkoutSuccess = 'Salida registrada exitosamente.';
  static const String profileUpdateSuccess = 'Perfil actualizado exitosamente.';
  static const String absenceCreateSuccess =
      'Ausencia registrada exitosamente.';
  static const String loginSuccess = 'Bienvenido a Tareas.';
}
