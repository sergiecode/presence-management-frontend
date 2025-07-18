/// Servicio de gestión de ausencias para la aplicación Tareas
///
/// Este servicio maneja todas las operaciones relacionadas con las ausencias
/// y permisos de los empleados, incluyendo crear, consultar, actualizar
/// y eliminar solicitudes de ausencia.
///
/// Utiliza HTTP para comunicarse con la API del backend.
///
/// Autor: Equipo Gold
/// Fecha: 2025
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

/// Servicio que maneja las operaciones de ausencias y permisos
class AbsenceService {
  /// URL base de la API (se obtiene de las constantes)
  static final String baseUrl = ApiConstants.baseUrl;

  /// Obtener todas las ausencias del usuario autenticado
  ///
  /// Este método obtiene el historial completo de ausencias y permisos
  /// solicitados por el usuario actual, incluyendo su estado de aprobación.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  ///
  /// Retorna:
  /// - [List<Map<String, dynamic>>]: Lista de ausencias del usuario
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<List<Map<String, dynamic>>> getAbsences(String token) async {
    try {
      print('AbsenceService: Obteniendo ausencias del usuario...');

      // Realizar petición GET para obtener todas las ausencias
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConstants.absencesEndpoint}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('AbsenceService: Respuesta: ${response.statusCode}');

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('AbsenceService: ${data.length} ausencias obtenidas');

        // Convertir la lista de datos dinámicos a lista de mapas
        return data
            .map((item) => _parseAbsenceData(item as Map<String, dynamic>))
            .toList();
      } else {
        // Manejar errores de la API
        final errorMessage = _getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('AbsenceService: Error al obtener ausencias: $e');

      // Convertir errores de red en mensajes más amigables
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ErrorMessages.timeoutError);
      } else if (e.toString().contains('SocketException')) {
        throw Exception(ErrorMessages.networkError);
      } else {
        rethrow;
      }
    }
  }

  /// Crear una nueva solicitud de ausencia
  ///
  /// Este método permite al usuario crear una nueva solicitud de ausencia
  /// especificando el tipo, fecha, motivo y documentos de respaldo opcionales.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  /// - [absenceData]: Datos de la ausencia (tipo, fecha, motivo, etc.)
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Datos de la ausencia creada
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de validación, red o servidor
  static Future<Map<String, dynamic>> createAbsence(
    String token,
    Map<String, dynamic> absenceData,
  ) async {
    try {
      print('AbsenceService: Creando ausencia...');
      print('AbsenceService: Datos: $absenceData');

      // Validar datos antes de enviar
      _validateAbsenceData(absenceData);

      // Realizar petición POST para crear la ausencia
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConstants.absencesEndpoint}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(absenceData),
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('AbsenceService: Respuesta creación: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('AbsenceService: Ausencia creada exitosamente');
        return _parseAbsenceData(data);
      } else {
        // Manejar errores de creación
        final errorMessage = _getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('AbsenceService: Error al crear ausencia: $e');

      // Convertir errores de red en mensajes más amigables
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ErrorMessages.timeoutError);
      } else if (e.toString().contains('SocketException')) {
        throw Exception(ErrorMessages.networkError);
      } else {
        rethrow;
      }
    }
  }

  /// Actualizar una ausencia existente
  ///
  /// Este método permite actualizar los datos de una ausencia existente,
  /// siempre que esté en un estado que permita modificaciones.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  /// - [absenceId]: ID de la ausencia a actualizar
  /// - [absenceData]: Nuevos datos de la ausencia
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Datos de la ausencia actualizada
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de validación, red o servidor
  static Future<Map<String, dynamic>> updateAbsence(
    String token,
    int absenceId,
    Map<String, dynamic> absenceData,
  ) async {
    try {
      print('AbsenceService: Actualizando ausencia ID: $absenceId');
      print('AbsenceService: Datos: $absenceData');

      // Validar datos antes de enviar
      _validateAbsenceData(absenceData);

      // Realizar petición PUT para actualizar la ausencia
      final response = await http
          .put(
            Uri.parse('$baseUrl${ApiConstants.absencesEndpoint}/$absenceId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(absenceData),
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('AbsenceService: Respuesta actualización: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('AbsenceService: Ausencia actualizada exitosamente');
        return _parseAbsenceData(data);
      } else {
        // Manejar errores de actualización
        final errorMessage = _getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('AbsenceService: Error al actualizar ausencia: $e');

      // Convertir errores de red en mensajes más amigables
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ErrorMessages.timeoutError);
      } else if (e.toString().contains('SocketException')) {
        throw Exception(ErrorMessages.networkError);
      } else {
        rethrow;
      }
    }
  }

  /// Eliminar una ausencia
  ///
  /// Este método permite eliminar una solicitud de ausencia,
  /// siempre que esté en un estado que permita la eliminación.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  /// - [absenceId]: ID de la ausencia a eliminar
  ///
  /// Retorna:
  /// - [bool]: true si la eliminación fue exitosa
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<bool> deleteAbsence(String token, int absenceId) async {
    try {
      print('AbsenceService: Eliminando ausencia ID: $absenceId');

      // Realizar petición DELETE para eliminar la ausencia
      final response = await http
          .delete(
            Uri.parse('$baseUrl${ApiConstants.absencesEndpoint}/$absenceId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('AbsenceService: Respuesta eliminación: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('AbsenceService: Ausencia eliminada exitosamente');
        return true;
      } else {
        // Manejar errores de eliminación
        final errorMessage = _getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('AbsenceService: Error al eliminar ausencia: $e');

      // Convertir errores de red en mensajes más amigables
      if (e.toString().contains('TimeoutException')) {
        throw Exception(ErrorMessages.timeoutError);
      } else if (e.toString().contains('SocketException')) {
        throw Exception(ErrorMessages.networkError);
      } else {
        rethrow;
      }
    }
  }

  /// Método privado para parsear y normalizar datos de ausencia
  ///
  /// Parámetros:
  /// - [data]: Datos crudos de la ausencia desde la API
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Datos de la ausencia normalizados
  static Map<String, dynamic> _parseAbsenceData(Map<String, dynamic> data) {
    return {
      'id': data['id'] ?? 0,
      'user_id': data['user_id'] ?? 0,
      'type': data['type'] ?? '',
      'date': data['date'] ?? '',
      'reason': data['reason'] ?? '',
      'status': data['status'] ?? 'pending',
      'file_url': data['file_url'],
      'file_name': data['file_name'],
      'approved_by': data['approved_by'],
      'approved_at': data['approved_at'],
      'rejected_reason': data['rejected_reason'],
      'created_at': data['created_at'] ?? '',
      'updated_at': data['updated_at'] ?? '',
    };
  }

  /// Validar datos de ausencia antes de enviar a la API
  ///
  /// Parámetros:
  /// - [absenceData]: Datos de la ausencia a validar
  ///
  /// Excepciones:
  /// - Lanza [Exception] si los datos no son válidos
  static void _validateAbsenceData(Map<String, dynamic> absenceData) {
    // Validar que tenga tipo de ausencia
    if (!absenceData.containsKey('type') ||
        absenceData['type'].toString().isEmpty) {
      throw Exception('El tipo de ausencia es obligatorio');
    }

    // Validar que el tipo de ausencia sea válido
    final absenceType = absenceData['type'].toString();
    if (!AppConfig.absenceTypes.contains(absenceType)) {
      throw Exception('Tipo de ausencia no válido');
    }

    // Validar que tenga fecha
    if (!absenceData.containsKey('date') ||
        absenceData['date'].toString().isEmpty) {
      throw Exception('La fecha de ausencia es obligatoria');
    }

    // Validar formato de fecha (YYYY-MM-DD)
    final dateString = absenceData['date'].toString();
    try {
      DateTime.parse(dateString);
    } catch (e) {
      throw Exception('Formato de fecha inválido. Use YYYY-MM-DD');
    }

    // Validar que tenga motivo
    if (!absenceData.containsKey('reason') ||
        absenceData['reason'].toString().trim().isEmpty) {
      throw Exception('El motivo de la ausencia es obligatorio');
    }

    // Validar longitud del motivo
    final reason = absenceData['reason'].toString().trim();
    if (reason.length < 10) {
      throw Exception('El motivo debe tener al menos 10 caracteres');
    }
    if (reason.length > 500) {
      throw Exception('El motivo no puede exceder 500 caracteres');
    }

    // Validar fecha no sea en el pasado (opcional, dependiendo de los requerimientos)
    final absenceDate = DateTime.parse(dateString);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (absenceDate.isBefore(todayOnly)) {
      throw Exception('No se pueden solicitar ausencias para fechas pasadas');
    }
  }

  /// Obtener mensaje de error amigable basado en el código de respuesta HTTP
  ///
  /// Parámetros:
  /// - [statusCode]: Código de estado HTTP
  /// - [responseBody]: Cuerpo de la respuesta
  ///
  /// Retorna:
  /// - [String]: Mensaje de error amigable
  static String _getErrorMessage(int statusCode, String responseBody) {
    switch (statusCode) {
      case 400:
        return 'Datos de ausencia inválidos. Verifique la información.';
      case 401:
        return ErrorMessages.sessionExpired;
      case 403:
        return ErrorMessages.accessDenied;
      case 404:
        return 'Ausencia no encontrada.';
      case 409:
        return 'Ya existe una ausencia para esta fecha.';
      case 422:
        try {
          final data = json.decode(responseBody);
          if (data['message'] != null) {
            return data['message'].toString();
          }
        } catch (e) {
          // Si no se puede parsear, usar mensaje genérico
        }
        return 'Los datos de la ausencia no son válidos.';
      case 500:
        return ErrorMessages.serverError;
      default:
        return 'Error inesperado al procesar ausencia. Código: $statusCode';
    }
  }

  /// Obtener etiqueta legible para el tipo de ausencia
  ///
  /// Parámetros:
  /// - [absenceType]: Tipo de ausencia en formato de API
  ///
  /// Retorna:
  /// - [String]: Etiqueta legible para mostrar al usuario
  static String getAbsenceTypeLabel(String? absenceType) {
    const absenceLabels = {
      'absence': 'Ausencia',
      'medical': 'Permiso Médico',
      'vacation': 'Vacaciones',
      'personal': 'Permiso Personal',
    };

    if (absenceType == null || absenceType.isEmpty) {
      return 'No especificado';
    }
    return absenceLabels[absenceType] ?? absenceType;
  }

  /// Obtener etiqueta legible para el estado de la ausencia
  ///
  /// Parámetros:
  /// - [status]: Estado de la ausencia en formato de API
  ///
  /// Retorna:
  /// - [String]: Etiqueta legible para mostrar al usuario
  static String getStatusLabel(String? status) {
    switch (status) {
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      case 'pending':
      default:
        return 'Pendiente';
    }
  }

  /// Verificar si una ausencia puede ser editada
  ///
  /// Parámetros:
  /// - [absenceData]: Datos de la ausencia
  ///
  /// Retorna:
  /// - [bool]: true si la ausencia puede ser editada
  static bool canEditAbsence(Map<String, dynamic> absenceData) {
    final status = absenceData['status']?.toString() ?? 'pending';
    // Solo se pueden editar ausencias pendientes
    return status == 'pending';
  }

  /// Verificar si una ausencia puede ser eliminada
  ///
  /// Parámetros:
  /// - [absenceData]: Datos de la ausencia
  ///
  /// Retorna:
  /// - [bool]: true si la ausencia puede ser eliminada
  static bool canDeleteAbsence(Map<String, dynamic> absenceData) {
    final status = absenceData['status']?.toString() ?? 'pending';
    // Solo se pueden eliminar ausencias pendientes
    return status == 'pending';
  }

  /// Subir documento para una ausencia
  ///
  /// Este método permite subir documentos de respaldo para ausencias
  /// que requieren justificación documental (médicas, ausencias justificadas).
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  /// - [absenceId]: ID de la ausencia a la cual adjuntar el documento
  /// - [filePath]: Ruta del archivo a subir
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Datos de la respuesta del servidor
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de validación, red o servidor
  static Future<Map<String, dynamic>> uploadDocument(
    String token,
    int absenceId,
    String filePath,
  ) async {
    try {
      print('AbsenceService: Subiendo documento para ausencia ID: $absenceId');
      print('AbsenceService: Archivo: $filePath');

      // Validar el archivo antes de subirlo
      _validateDocumentFile(filePath);

      final file = File(filePath);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl${ApiConstants.absenceDocumentEndpoint}/$absenceId/documents',
        ),
      );

      // Agregar headers
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Agregar el archivo
      final multipartFile = await http.MultipartFile.fromPath(
        'document',
        filePath,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      print('AbsenceService: Enviando documento...');

      // Enviar la petición
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: ApiConstants.timeoutDuration),
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('AbsenceService: Respuesta subida: ${response.statusCode}');
      print('AbsenceService: Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('AbsenceService: Documento subido exitosamente');
        return data;
      } else {
        // Manejar errores de subida
        final errorMessage = _getErrorMessage(
          response.statusCode,
          response.body,
        );
        print('AbsenceService: Error al subir documento: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('AbsenceService: Error al subir documento: $e');

      // Convertir errores de red en mensajes más amigables
      if (e.toString().contains('TimeoutException')) {
        throw Exception(
          'Tiempo de espera agotado. El archivo puede ser muy grande.',
        );
      } else if (e.toString().contains('SocketException')) {
        throw Exception(ErrorMessages.networkError);
      } else {
        rethrow;
      }
    }
  }

  /// Verificar si un tipo de ausencia requiere documento
  ///
  /// Parámetros:
  /// - [absenceType]: Tipo de ausencia
  ///
  /// Retorna:
  /// - [bool]: true si requiere documento
  static bool requiresDocument(String absenceType) {
    return AppConfig.absenceTypesRequiringDocuments.contains(absenceType);
  }

  /// Validar archivo de documento antes de subirlo
  ///
  /// Parámetros:
  /// - [filePath]: Ruta del archivo a validar
  ///
  /// Excepciones:
  /// - Lanza [Exception] si el archivo no es válido
  static void _validateDocumentFile(String filePath) {
    final file = File(filePath);

    // Verificar que el archivo existe
    if (!file.existsSync()) {
      throw Exception('El archivo no existe');
    }

    // Verificar tamaño del archivo
    final fileSize = file.lengthSync();
    if (fileSize > AppConfig.maxDocumentSize) {
      final maxSizeMB = AppConfig.maxDocumentSize / (1024 * 1024);
      throw Exception(
        'El archivo es muy grande. Tamaño máximo: ${maxSizeMB.toStringAsFixed(1)}MB',
      );
    }

    // Verificar extensión del archivo
    final extension = filePath.split('.').last.toLowerCase();
    if (!AppConfig.validDocumentExtensions.contains(extension)) {
      throw Exception(
        'Formato de archivo no válido. Formatos permitidos: ${AppConfig.validDocumentExtensions.join(', ').toUpperCase()}',
      );
    }
  }
}
