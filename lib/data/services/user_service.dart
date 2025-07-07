/// Servicio de gestión de usuarios para la aplicación ABSTI
///
/// Este servicio maneja todas las operaciones relacionadas con usuarios,
/// incluyendo obtener datos del perfil, actualizar información personal,
/// y validación de datos de usuario.
///
/// Utiliza HTTP para comunicarse con la API del backend.
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

/// Servicio que maneja las operaciones de usuario
class UserService {
  /// URL base de la API (se obtiene de las constantes)
  static final String baseUrl = ApiConstants.baseUrl;

  /// Método privado para parsear y normalizar los datos del usuario
  ///
  /// Parámetros:
  /// - [data]: Datos crudos del usuario desde la API
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Datos del usuario normalizados
  static Map<String, dynamic> _parseUserData(Map<String, dynamic> data) {
    return {
      'id': data['id'] ?? 0,
      'name': data['name'] ?? '',
      'surname': data['surname'] ?? '',
      'email': data['email'] ?? '',
      'phone': data['phone'] ?? '',
      'picture': data['picture'] ?? '',
      'role': data['role'] ?? '',
      'timezone': data['timezone'] ?? '',
      'notification_offset_min': data['notification_offset_min'] ?? 0,
      'checkin_start_time': data['checkin_start_time'] ?? '',
      'email_confirmed': data['email_confirmed'] ?? false,
      'deactivated': data['deactivated'] ?? false,
      'pending_approval': data['pending_approval'] ?? false,
    };
  }

  /// Obtener los datos del usuario actual autenticado
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  ///
  /// Retorna:
  /// - [Map<String, dynamic>?]: Datos del usuario o null si hay error
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<Map<String, dynamic>?> getCurrentUser(String token) async {
    try {
      print('UserService: Obteniendo datos del usuario...');

      // Realizar petición GET para obtener datos del usuario actual
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConstants.userMeEndpoint}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('UserService: Respuesta del servidor: ${response.statusCode}');

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('UserService: Datos recibidos exitosamente');
        return _parseUserData(data);
      } else {
        // Manejar errores usando el método helper
        final errorMessage = getErrorMessage(
          response.statusCode,
          response.body,
        );
        print('UserService: Error ${response.statusCode}: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('UserService: Error al obtener usuario: $e');

      // Convertir errores de red en mensajes más amigables
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ErrorMessages.timeoutError);
      } else if (e.toString().contains('SocketException')) {
        throw Exception(ErrorMessages.networkError);
      } else {
        rethrow; // Re-lanzar la excepción original
      }
    }
  }

  /// Actualizar los datos del usuario
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  /// - [userId]: ID del usuario a actualizar
  /// - [userData]: Nuevos datos del usuario
  ///
  /// Retorna:
  /// - [Map<String, dynamic>?]: Datos actualizados del usuario
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de validación, red o servidor
  static Future<Map<String, dynamic>?> updateUser(
    String token,
    int userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      print('UserService: Actualizando usuario con ID: $userId');
      print('UserService: Datos a enviar: $userData');

      // Validar datos antes de enviar a la API
      final validationErrors = validateUserData(userData);
      if (validationErrors.isNotEmpty) {
        print('UserService: Errores de validación: $validationErrors');
        throw Exception('Datos inválidos: ${validationErrors.values.first}');
      }

      // Preparar datos solo con campos editables
      final editableData = prepareUserDataForUpdate(userData);

      // Realizar petición PUT para actualizar el usuario
      final response = await http
          .put(
            Uri.parse('$baseUrl${ApiConstants.userUpdateEndpoint}/$userId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(editableData),
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('UserService: Respuesta de actualización: ${response.statusCode}');

      // Verificar si la actualización fue exitosa
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('UserService: Usuario actualizado exitosamente');
        return _parseUserData(data);
      } else {
        // Manejar errores de actualización
        final errorMessage = getErrorMessage(
          response.statusCode,
          response.body,
        );
        print('UserService: Error ${response.statusCode}: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('UserService: Error al actualizar usuario: $e');

      // Convertir errores de red en mensajes más amigables
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ErrorMessages.timeoutError);
      } else if (e.toString().contains('SocketException')) {
        throw Exception(ErrorMessages.networkError);
      } else {
        rethrow; // Re-lanzar la excepción original
      }
    }
  }

  /// Subir imagen de avatar del usuario
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación
  /// - [userId]: ID del usuario
  /// - [imageFile]: Archivo de imagen a subir
  ///
  /// Retorna:
  /// - [String?]: URL de la imagen subida o null si hay error
  static Future<String?> uploadUserAvatar(
    String token,
    int userId,
    File imageFile,
  ) async {
    try {
      print('UserService: Subiendo avatar para usuario $userId');

      // Crear request multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${ApiConstants.userAvatarEndpoint}/$userId'),
      );

      // Agregar headers
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Agregar archivo
      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path),
      );

      // Enviar request
      final response = await request.send().timeout(
        const Duration(seconds: ApiConstants.timeoutDuration),
      );

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        print('UserService: Avatar subido exitosamente');
        return data['picture'] ?? data['avatar_url'];
      } else {
        print('UserService: Error al subir avatar: ${response.statusCode}');
        throw Exception('Error al subir imagen de perfil');
      }
    } catch (e) {
      print('UserService: Error al subir avatar: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ErrorMessages.timeoutError);
      } else if (e.toString().contains('SocketException')) {
        throw Exception(ErrorMessages.networkError);
      } else {
        rethrow;
      }
    }
  }

  /// Preparar datos del usuario para actualización (filtrar campos editables)
  ///
  /// Solo incluye campos que el usuario puede editar desde la aplicación.
  /// Esto previene que se envíen campos de solo lectura o sensibles.
  ///
  /// Parámetros:
  /// - [userData]: Datos completos del usuario
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Solo los campos editables
  static Map<String, dynamic> prepareUserDataForUpdate(
    Map<String, dynamic> userData,
  ) {
    final Map<String, dynamic> editableData = {};

    // Campos básicos editables por el usuario
    if (userData.containsKey('name')) editableData['name'] = userData['name'];
    if (userData.containsKey('surname')) {
      editableData['surname'] = userData['surname'];
    }
    if (userData.containsKey('phone')) {
      editableData['phone'] = userData['phone'];
    }
    if (userData.containsKey('timezone')) {
      editableData['timezone'] = userData['timezone'];
    }
    if (userData.containsKey('notification_offset_min')) {
      editableData['notification_offset_min'] =
          userData['notification_offset_min'];
    }
    if (userData.containsKey('checkin_start_time')) {
      editableData['checkin_start_time'] = userData['checkin_start_time'];
    }

    // El email puede ser editable dependiendo de la configuración del servidor
    if (userData.containsKey('email')) {
      editableData['email'] = userData['email'];
    }

    return editableData;
  }

  /// Validar datos del usuario antes de enviar a la API
  ///
  /// Verifica que los datos cumplan con los formatos y restricciones
  /// requeridas antes de enviarlos al servidor.
  ///
  /// Parámetros:
  /// - [userData]: Datos del usuario a validar
  ///
  /// Retorna:
  /// - [Map<String, String>]: Mapa de errores (vacío si no hay errores)
  static Map<String, String> validateUserData(Map<String, dynamic> userData) {
    Map<String, String> errors = {};

    // Validar nombre (campo obligatorio)
    if (userData['name'] == null ||
        userData['name'].toString().trim().isEmpty) {
      errors['name'] = 'El nombre es obligatorio';
    } else if (userData['name'].toString().trim().length < 2) {
      errors['name'] = 'El nombre debe tener al menos 2 caracteres';
    }

    // Validar apellido (campo obligatorio)
    if (userData['surname'] == null ||
        userData['surname'].toString().trim().isEmpty) {
      errors['surname'] = 'El apellido es obligatorio';
    } else if (userData['surname'].toString().trim().length < 2) {
      errors['surname'] = 'El apellido debe tener al menos 2 caracteres';
    }

    // Validar email si está presente
    if (userData['email'] != null && userData['email'].toString().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(userData['email'].toString())) {
        errors['email'] = 'Formato de email no válido';
      }
    }

    // Validar teléfono si está presente
    if (userData['phone'] != null && userData['phone'].toString().isNotEmpty) {
      // Limpiar el teléfono de espacios, guiones y paréntesis
      final cleanPhone = userData['phone'].toString().replaceAll(
        RegExp(r'[\s\-\(\)]'),
        '',
      );
      final phoneRegex = RegExp(r'^\+?[1-9]\d{7,14}$');
      if (!phoneRegex.hasMatch(cleanPhone)) {
        errors['phone'] = 'Formato de teléfono no válido';
      }
    }

    // Validar hora de check-in si está presente
    if (userData['checkin_start_time'] != null &&
        userData['checkin_start_time'].toString().isNotEmpty) {
      final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
      if (!timeRegex.hasMatch(userData['checkin_start_time'].toString())) {
        errors['checkin_start_time'] = 'Formato de hora no válido (HH:MM)';
      }
    }

    // Validar offset de notificaciones si está presente
    if (userData['notification_offset_min'] != null) {
      final offset = userData['notification_offset_min'];
      if (offset is! int || offset < 0 || offset > 120) {
        errors['notification_offset_min'] =
            'El offset debe ser entre 0 y 120 minutos';
      }
    }

    return errors;
  }

  /// Obtener mensaje de error amigable basado en el código de respuesta HTTP
  ///
  /// Convierte códigos de error HTTP en mensajes comprensibles para el usuario.
  ///
  /// Parámetros:
  /// - [statusCode]: Código de estado HTTP
  /// - [responseBody]: Cuerpo de la respuesta (puede contener detalles del error)
  ///
  /// Retorna:
  /// - [String]: Mensaje de error amigable para el usuario
  static String getErrorMessage(int statusCode, String responseBody) {
    switch (statusCode) {
      case 400:
        return ErrorMessages.requiredField;
      case 401:
        return ErrorMessages.sessionExpired;
      case 403:
        return ErrorMessages.accessDenied;
      case 404:
        return 'Usuario no encontrado.';
      case 422:
        // Intentar extraer errores específicos del cuerpo de la respuesta
        try {
          final data = json.decode(responseBody);
          if (data['errors'] != null) {
            final errors = data['errors'] as Map<String, dynamic>;
            return errors.values.first.toString();
          } else if (data['message'] != null) {
            return data['message'].toString();
          }
        } catch (e) {
          // Si no se puede parsear, usar mensaje genérico
        }
        return 'Los datos proporcionados no son válidos.';
      case 500:
        return ErrorMessages.serverError;
      default:
        return 'Error inesperado. Código: $statusCode';
    }
  }

  /// Formatear nombre completo del usuario
  ///
  /// Parámetros:
  /// - [userData]: Datos del usuario
  ///
  /// Retorna:
  /// - [String]: Nombre completo formateado
  static String getFullName(Map<String, dynamic> userData) {
    final name = userData['name']?.toString().trim() ?? '';
    final surname = userData['surname']?.toString().trim() ?? '';

    if (name.isNotEmpty && surname.isNotEmpty) {
      return '$name $surname';
    } else if (name.isNotEmpty) {
      return name;
    } else if (surname.isNotEmpty) {
      return surname;
    } else {
      return 'Usuario';
    }
  }

  /// Obtener iniciales del usuario para avatares
  ///
  /// Parámetros:
  /// - [userData]: Datos del usuario
  ///
  /// Retorna:
  /// - [String]: Iniciales del usuario (máximo 2 caracteres)
  static String getUserInitials(Map<String, dynamic> userData) {
    final name = userData['name']?.toString().trim() ?? '';
    final surname = userData['surname']?.toString().trim() ?? '';

    String initials = '';

    if (name.isNotEmpty) {
      initials += name[0].toUpperCase();
    }

    if (surname.isNotEmpty && initials.length < 2) {
      initials += surname[0].toUpperCase();
    }

    return initials.isEmpty ? 'U' : initials;
  }
}
