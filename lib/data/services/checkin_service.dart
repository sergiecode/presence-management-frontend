/// Servicio de gestión de check-ins para la aplicación Tareas
///
/// Este servicio maneja todas las operaciones relacionadas con el registro
/// de entrada y salida de los empleados, incluyendo check-in, check-out,
/// y consulta del historial de asistencia.
///
/// Utiliza HTTP para comunicarse con la API del backend.
///
/// Autor: Equipo Gold
/// Fecha: 2025
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

/// Servicio que maneja las operaciones de check-in y check-out
class CheckInService {
  /// URL base de la API (se obtiene de las constantes)
  static final String baseUrl = ApiConstants.baseUrl;

  /// Obtener todos los check-ins del usuario autenticado
  ///
  /// Este método obtiene el historial completo de registros de asistencia
  /// del usuario actual, incluyendo entradas, salidas y detalles de ubicación.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  ///
  /// Retorna:
  /// - [List<Map<String, dynamic>>]: Lista de registros de check-in
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<List<Map<String, dynamic>>> getCheckIns(String token) async {
    try {
      print('CheckInService: Obteniendo check-ins del usuario...');

      // Realizar petición GET para obtener todos los check-ins
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConstants.checkinsEndpoint}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('CheckInService: Respuesta: ${response.statusCode}');

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('CheckInService: ${data.length} check-ins obtenidos');

        // Convertir la lista de datos dinámicos a lista de mapas
        return data
            .map((item) => _parseCheckInData(item as Map<String, dynamic>))
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
      print('CheckInService: Error al obtener check-ins: $e');

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

  /// Obtener el check-in del día actual
  ///
  /// Este método verifica si el usuario ya registró entrada hoy
  /// y retorna la información del check-in actual.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  ///
  /// Retorna:
  /// - [Map<String, dynamic>?]: Datos del check-in de hoy o null si no existe
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<Map<String, dynamic>?> getTodayCheckIn(String token) async {
    try {
      print('CheckInService: Obteniendo check-in de hoy...');

      // Realizar petición GET para obtener el check-in de hoy
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConstants.checkinTodayEndpoint}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('CheckInService: Respuesta today: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Si hay datos, parsearlos y retornarlos
        if (data != null && data is Map<String, dynamic>) {
          print('CheckInService: Check-in de hoy encontrado');
          return _parseCheckInData(data);
        } else {
          print('CheckInService: No hay check-in para hoy');
          return null;
        }
      } else if (response.statusCode == 404) {
        // No hay check-in para hoy (esto es normal)
        print('CheckInService: No hay check-in para hoy');
        return null;
      } else {
        // Manejar otros errores
        final errorMessage = _getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('CheckInService: Error al obtener check-in de hoy: $e');

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

  /// Realizar check-in (registrar entrada)
  ///
  /// Este método registra la entrada del empleado con información
  /// de ubicación, hora y notas opcionales.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  /// - [checkInData]: Datos del check-in (debe contener date y time)
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Datos del check-in creado
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de validación, red o servidor
  static Future<Map<String, dynamic>> checkIn(
    String token,
    Map<String, dynamic> checkInData,
  ) async {
    try {
      print('CheckInService: Realizando check-in...');
      print('CheckInService: Datos recibidos: $checkInData');

      // Validar que tenemos date y time
      if (!checkInData.containsKey('date') || checkInData['date'] == null) {
        throw Exception('La fecha es obligatoria para el check-in');
      }

      if (!checkInData.containsKey('time') || checkInData['time'] == null) {
        throw Exception('La hora es obligatoria para el check-in');
      }

      // Validar que tenemos user_id
      if (!checkInData.containsKey('user_id') || checkInData['user_id'] == null) {
        throw Exception('El ID de usuario es obligatorio para el check-in');
      }

      // Construir el body específico que requiere el backend
      // Basado en el ejemplo del servidor con los campos requeridos: 
      // {
      //   "date": "2025-07-07",
      //   "time": "2025-07-07T09:01:02-03:00", 
      //   "location_type": "home",
      //   "location_detail": "string",
      //   "notes": "string",
      //   "gps_lat": 0,
      //   "gps_long": 0,
      //   "user_id": 123,
      //   "late_reason": "traffic" (opcional, solo si llega tarde)
      // }
      final requestBody = {
        "date": checkInData['date'].toString(), // YYYY-MM-DD
        "time": checkInData['time'].toString(), // ISO 8601 timestamp con zona horaria
        "location_type": checkInData['location_type'] ?? "home",
        "location_detail": checkInData['location_detail'] ?? "string",
        "notes": checkInData['notes'] ?? "string",
        "gps_lat": checkInData['gps_lat'] ?? 0,
        "gps_long": checkInData['gps_long'] ?? 0,
        "user_id": checkInData['user_id'], // ID del usuario (requerido)
      };

      // Agregar late_reason solo si está presente (cuando el usuario llega tarde)
      if (checkInData.containsKey('late_reason') && 
          checkInData['late_reason'] != null && 
          checkInData['late_reason'].toString().isNotEmpty) {
        requestBody["late_reason"] = checkInData['late_reason'].toString();
      }

      print('CheckInService: Body para enviar: $requestBody');
      print('CheckInService: JSON string que se enviará: ${json.encode(requestBody)}');
      
      // Debug detallado de cada campo
      print('CheckInService: === DETALLES DEL BODY ===');
      print('CheckInService: date = "${requestBody['date']}" (tipo: ${requestBody['date'].runtimeType})');
      print('CheckInService: time = "${requestBody['time']}" (tipo: ${requestBody['time'].runtimeType})');
      print('CheckInService: location_type = "${requestBody['location_type']}" (tipo: ${requestBody['location_type'].runtimeType})');
      print('CheckInService: location_detail = "${requestBody['location_detail']}" (tipo: ${requestBody['location_detail'].runtimeType})');
      print('CheckInService: notes = "${requestBody['notes']}" (tipo: ${requestBody['notes'].runtimeType})');
      print('CheckInService: gps_lat = ${requestBody['gps_lat']} (tipo: ${requestBody['gps_lat'].runtimeType})');
      print('CheckInService: gps_long = ${requestBody['gps_long']} (tipo: ${requestBody['gps_long'].runtimeType})');
      print('CheckInService: user_id = ${requestBody['user_id']} (tipo: ${requestBody['user_id'].runtimeType})');
      if (requestBody.containsKey('late_reason')) {
        print('CheckInService: late_reason = "${requestBody['late_reason']}" (tipo: ${requestBody['late_reason'].runtimeType})');
      } else {
        print('CheckInService: late_reason = NO INCLUIDO');
      }
      print('CheckInService: === FIN DETALLES ===');

      http.Response response;
      
      // Estrategia 1: Intentar con el endpoint normal
      print('CheckInService: Estrategia 1 - Endpoint normal');
      response = await _attemptCheckIn(token, requestBody, ApiConstants.checkinsEndpoint);

      // Estrategia 2: Si obtenemos un 307, intentar con la variante que tiene barra final
      if (response.statusCode == 307) {
        print('CheckInService: Estrategia 2 - Endpoint con barra final');
        response = await _attemptCheckIn(token, requestBody, ApiConstants.checkinsEndpointWithSlash);
      }

      // Estrategia 3: Si seguimos obteniendo 307, intentar con headers alternativos
      if (response.statusCode == 307) {
        print('CheckInService: Estrategia 3 - Headers alternativos en endpoint normal');
        response = await _attemptCheckIn(token, requestBody, ApiConstants.checkinsEndpoint, useAlternativeHeaders: true);
      }

      // Estrategia 4: Headers alternativos con barra final
      if (response.statusCode == 307) {
        print('CheckInService: Estrategia 4 - Headers alternativos con barra final');
        response = await _attemptCheckIn(token, requestBody, ApiConstants.checkinsEndpointWithSlash, useAlternativeHeaders: true);
      }

      print('CheckInService: Respuesta check-in: ${response.statusCode}');
      print('CheckInService: Headers de respuesta: ${response.headers}');
      print('CheckInService: Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('CheckInService: Check-in realizado exitosamente');
        return _parseCheckInData(data);
      } else if (response.statusCode == 307) {
        // Si seguimos obteniendo 307 después de todas las estrategias
        print('CheckInService: Error 307 persistente después de todas las estrategias');
        final location = response.headers['location'];
        String errorMessage = 'Error del servidor (307): No se pudo realizar el check-in.';
        if (location != null) {
          print('CheckInService: Ubicación sugerida por el servidor: $location');
          errorMessage += ' El servidor sugiere usar: $location';
        }
        errorMessage += ' Contacte al administrador del sistema.';
        throw Exception(errorMessage);
      } else {
        // Manejar otros errores de check-in
        final errorMessage = _getErrorMessage(
          response.statusCode,
          response.body,
        );
        print('CheckInService: Error del servidor: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('CheckInService: Error al hacer check-in: $e');

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

  /// Realizar check-out (registrar salida)
  ///
  /// Este método registra la salida del empleado y calcula
  /// automáticamente la duración del turno.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  /// - [checkOutData]: Datos del check-out (notas opcionales, etc.)
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Datos del check-out actualizado
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<Map<String, dynamic>> checkOut(
    String token,
    Map<String, dynamic> checkOutData,
  ) async {
    try {
      print('CheckInService: Realizando check-out...');
      print('CheckInService: Datos: $checkOutData');

      // Realizar petición POST para registrar el check-out
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConstants.checkoutEndpoint}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(checkOutData),
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('CheckInService: Respuesta check-out: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('CheckInService: Check-out realizado exitosamente');
        return _parseCheckInData(data);
      } else {
        // Manejar errores de check-out
        final errorMessage = _getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('CheckInService: Error al hacer check-out: $e');

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

  /// Método privado para parsear y normalizar datos de check-in
  ///
  /// Parámetros:
  /// - [data]: Datos crudos del check-in desde la API
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Datos del check-in normalizados
  static Map<String, dynamic> _parseCheckInData(Map<String, dynamic> data) {
    return {
      'id': data['id'] ?? 0,
      'user_id': data['user_id'] ?? 0,
      'date': data['date'] ?? '',
      'time':
          data['time'] ??
          data['check_in_time'] ??
          '', // Mantener campo original
      'check_in_time': data['check_in_time'] ?? data['time'] ?? '',
      'check_out_time': data['check_out_time'] ?? data['checkout_time'],
      'location_type': data['location_type'] ?? '',
      'location_detail': data['location_detail'] ?? '',
      'gps_lat': data['gps_lat'] ?? 0.0,
      'gps_long': data['gps_long'] ?? 0.0,
      'notes': data['notes'] ?? '',
      'late': data['late'] ?? false,
      'overtime': data['overtime'] ?? false,
      'created_at': data['created_at'] ?? '',
      'updated_at': data['updated_at'] ?? '',
    };
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
        return 'Datos de check-in inválidos. Verifique la información.';
      case 401:
        return ErrorMessages.sessionExpired;
      case 403:
        return ErrorMessages.accessDenied;
      case 404:
        return 'Check-in no encontrado.';
      case 409:
        return 'Ya existe un check-in para hoy.';
      case 422:
        try {
          final data = json.decode(responseBody);
          if (data['message'] != null) {
            return data['message'].toString();
          }
        } catch (e) {
          // Si no se puede parsear, usar mensaje genérico
        }
        return 'Los datos del check-in no son válidos.';
      case 500:
        return ErrorMessages.serverError;
      default:
        return 'Error inesperado al procesar check-in. Código: $statusCode';
    }
  }

  /// Obtener etiqueta legible para el tipo de ubicación
  ///
  /// Parámetros:
  /// - [locationType]: Tipo de ubicación en formato de API
  ///
  /// Retorna:
  /// - [String]: Etiqueta legible para mostrar al usuario
  static String getLocationLabel(String? locationType) {
    if (locationType == null || locationType.isEmpty) {
      return 'No especificado';
    }
    return AppConfig.locationLabels[locationType] ?? locationType;
  }

  /// Calcular duración entre check-in y check-out
  ///
  /// Parámetros:
  /// - [checkInData]: Datos del check-in con horas de entrada y salida
  ///
  /// Retorna:
  /// - [Duration]: Duración del turno o Duration.zero si no hay check-out
  static Duration calculateWorkDuration(Map<String, dynamic> checkInData) {
    try {
      final checkInTime = checkInData['check_in_time'] ?? checkInData['time'];
      final checkOutTime =
          checkInData['check_out_time'] ?? checkInData['checkout_time'];
      final date = checkInData['date'];

      if (checkInTime != null && checkOutTime != null && date != null) {
        final checkInDateTime = DateTime.parse('$date $checkInTime');
        final checkOutDateTime = DateTime.parse('$date $checkOutTime');
        return checkOutDateTime.difference(checkInDateTime);
      }
    } catch (e) {
      print('CheckInService: Error calculando duración: $e');
    }
    return Duration.zero;
  }

  /// Formatear duración en formato legible (HH:MM)
  ///
  /// Parámetros:
  /// - [duration]: Duración a formatear
  ///
  /// Retorna:
  /// - [String]: Duración formateada (ej: "8:30")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Formatea la fecha para la API (YYYY-MM-DD)
  ///
  /// Parámetros:
  /// - [date]: Fecha a formatear
  ///
  /// Retorna:
  /// - [String]: Fecha formateada para la API
  static String formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Formatea la hora para la API (ISO 8601 con zona horaria)
  ///
  /// Parámetros:
  /// - [dateTime]: Fecha y hora completa a formatear
  ///
  /// Retorna:
  /// - [String]: Timestamp completo formateado para la API (ISO 8601)
  static String formatDateTimeForAPI(DateTime dateTime) {
    // Formatear como ISO 8601 con zona horaria (ej: "2025-07-07T09:01:02-03:00")
    return dateTime.toIso8601String();
  }

  /// Formatea la hora para la API (HH:MM:SS) - DEPRECATED
  ///
  /// Parámetros:
  /// - [time]: Hora a formatear
  ///
  /// Retorna:
  /// - [String]: Hora formateada para la API
  @deprecated
  static String formatTimeForAPI(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  /// Método helper para intentar check-in con un endpoint específico
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación
  /// - [requestBody]: Datos del check-in
  /// - [endpoint]: Endpoint específico a utilizar
  /// - [useAlternativeHeaders]: Si usar headers alternativos
  ///
  /// Retorna:
  /// - [http.Response]: Respuesta del servidor
  static Future<http.Response> _attemptCheckIn(
    String token,
    Map<String, dynamic> requestBody,
    String endpoint, {
    bool useAlternativeHeaders = false,
  }) async {
    print('CheckInService: Intentando check-in en endpoint: $endpoint');
    print('CheckInService: Usando headers alternativos: $useAlternativeHeaders');
    print('CheckInService: Body completo: ${json.encode(requestBody)}');
    
    // Headers básicos
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    
    // Si usamos headers alternativos, agregar más headers que podrían ayudar
    if (useAlternativeHeaders) {
      headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'Tareas-Flutter-App/1.0',
        'Connection': 'keep-alive',
      });
    }
    
    print('CheckInService: Headers que se enviarán: $headers');
    final jsonBody = json.encode(requestBody);
    print('CheckInService: JSON body final: $jsonBody');
    print('CheckInService: Longitud del body: ${jsonBody.length} bytes');
    
    return await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonBody,
        )
        .timeout(const Duration(seconds: ApiConstants.timeoutDuration));
  }
}
