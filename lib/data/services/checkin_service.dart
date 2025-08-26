/// Servicio de gestión de check-ins para la aplicación ABSTI
///
/// Este servicio maneja todas las operaciones relacionadas con el registro
/// de entrada y salida de los empleados, incluyendo check-in, check-out,
/// y consulta del historial de asistencia.
///
/// Utiliza HTTP para comunicarse con la API del backend.
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'dart:convert';
import 'dart:async';
import 'dart:io';
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
      print(
        'CheckInService: Obteniendo check-ins del usuario (con paginación)...',
      );

      final List<Map<String, dynamic>> allCheckIns = [];
      int currentPage = 1;
      int totalPages = 1;

      // Bucle para obtener todas las páginas por su número
      do {
        final url =
            '$baseUrl${ApiConstants.checkinsEndpoint}?page=$currentPage';
        print('CheckInService: Obteniendo página: $url');

        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

        print('CheckInService: Respuesta: ${response.statusCode}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> pageData = json.decode(response.body);

          // Validar que la respuesta tiene el formato esperado
          if (pageData['data'] != null &&
              pageData['data'] is List &&
              pageData['pagination'] != null &&
              pageData['pagination'] is Map) {
            final List<dynamic> results = pageData['data'];
            allCheckIns.addAll(
              results.map(
                (item) => _parseCheckInData(item as Map<String, dynamic>),
              ),
            );

            totalPages = pageData['pagination']['total_pages'] ?? 1;

            currentPage++;
          } else {
            // Si la respuesta no tiene 'data' o 'pagination', el formato es incorrecto.
            throw Exception(
              'Formato de respuesta de paginación inesperado. No hay elementos para mostrar".',
            );
          }
        } else {
          // Manejar errores de la API
          final errorMessage = _getErrorMessage(
            response.statusCode,
            response.body,
          );
          throw Exception(errorMessage);
        }
      } while (currentPage <= totalPages);

      print(
        'CheckInService: Total de ${allCheckIns.length} check-ins obtenidos de todas las páginas.',
      );
      return allCheckIns;
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


      if (!checkInData.containsKey('time') || checkInData['time'] == null) {
        throw Exception('La hora es obligatoria para el check-in');
      }

      // Validar que tenemos user_id
      if (!checkInData.containsKey('user_id') ||
          checkInData['user_id'] == null) {
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
        "locations": checkInData['locations'],
        "notes": checkInData['notes'] ?? "",
        "time": checkInData['time'].toString(),
        "user_id": checkInData['user_id'],
      };

      // Agregar late_reason solo si está presente (cuando el usuario llega tarde)
      if (checkInData.containsKey('late_reason') &&
          checkInData['late_reason'] != null &&
          checkInData['late_reason'].toString().isNotEmpty) {
        requestBody["late_reason"] = checkInData['late_reason'].toString();
      }

      print('CheckInService: Body para enviar: $requestBody');
      print(
        'CheckInService: JSON string que se enviará: ${json.encode(requestBody)}',
      );

      // Debug detallado de cada campo
      print('CheckInService: === DETALLES DEL BODY ===');
      print(
        'CheckInService: locations = ${requestBody['locations']} (tipo: ${requestBody['locations'].runtimeType})',
      );
      if (requestBody['locations'] is List &&
          (requestBody['locations'] as List).isNotEmpty) {
        final firstLocation = (requestBody['locations'] as List)[0];
        print(
          'CheckInService: location_type = ${firstLocation['location_type']} (tipo: ${firstLocation['location_type'].runtimeType})',
        );
        print(
          'CheckInService: location_detail = "${firstLocation['location_detail']}" (tipo: ${firstLocation['location_detail'].runtimeType})',
        );
      }
      print(
        'CheckInService: notes = "${requestBody['notes']}" (tipo: ${requestBody['notes'].runtimeType})',
      );
      print(
        'CheckInService: time = "${requestBody['time']}" (tipo: ${requestBody['time'].runtimeType})',
      );
      print(
        'CheckInService: user_id = ${requestBody['user_id']} (tipo: ${requestBody['user_id'].runtimeType})',
      );
      if (requestBody.containsKey('late_reason')) {
        print(
          'CheckInService: late_reason = "${requestBody['late_reason']}" (tipo: ${requestBody['late_reason'].runtimeType})',
        );
      } else {
        print('CheckInService: late_reason = NO INCLUIDO');
      }
      print('CheckInService: === FIN DETALLES ===');

      http.Response response;

      // Estrategia 1: Intentar con el endpoint normal
      print('CheckInService: Estrategia 1 - Endpoint normal');
      response = await _attemptCheckIn(
        token,
        requestBody,
        ApiConstants.checkinsEndpoint,
      );

      // Estrategia 2: Si obtenemos un 307, intentar con la variante que tiene barra final
      if (response.statusCode == 307) {
        print('CheckInService: Estrategia 2 - Endpoint con barra final');
        response = await _attemptCheckIn(
          token,
          requestBody,
          ApiConstants.checkinsEndpointWithSlash,
        );
      }

      // Estrategia 3: Si seguimos obteniendo 307, intentar con headers alternativos
      if (response.statusCode == 307) {
        print(
          'CheckInService: Estrategia 3 - Headers alternativos en endpoint normal',
        );
        response = await _attemptCheckIn(
          token,
          requestBody,
          ApiConstants.checkinsEndpoint,
          useAlternativeHeaders: true,
        );
      }

      // Estrategia 4: Headers alternativos con barra final
      if (response.statusCode == 307) {
        print(
          'CheckInService: Estrategia 4 - Headers alternativos con barra final',
        );
        response = await _attemptCheckIn(
          token,
          requestBody,
          ApiConstants.checkinsEndpointWithSlash,
          useAlternativeHeaders: true,
        );
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
        print(
          'CheckInService: Error 307 persistente después de todas las estrategias',
        );
        final location = response.headers['location'];
        String errorMessage =
            'Error del servidor (307): No se pudo realizar el check-in.';
        if (location != null) {
          print(
            'CheckInService: Ubicación sugerida por el servidor: $location',
          );
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
    dynamic locationType = '';
    String locationDetail = '';

    if (data['locations'] != null &&
        data['locations'] is List &&
        (data['locations'] as List).isNotEmpty) {
      final firstLocation = (data['locations'] as List)[0];
      if (firstLocation is Map<String, dynamic>) {
        // Parsear location_type como int si es posible
        final locationTypeRaw = firstLocation['location_type'];
        if (locationTypeRaw is int) {
          locationType = locationTypeRaw;
        } else if (locationTypeRaw is String) {
          locationType =
              int.tryParse(locationTypeRaw) ??
              1; // Default a 1 si no se puede parsear
        } else {
          locationType = 1; // Default
        }
        locationDetail = firstLocation['location_detail']?.toString() ?? '';
      }
    }

    return {
      'id': data['id'] ?? 0,
      'user_id': data['user_id'] ?? 0,
      'date': data['date'] ?? '',
      'time': data['time'] ?? data['check_in_time'] ?? '',
      'check_in_time': data['check_in_time'] ?? data['time'] ?? '',
      'check_out_time': data['check_out_time'] ?? data['checkout_time'],
      'location_type': locationType, // Ahora será int
      'location_detail': locationDetail,
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
        print('$responseBody');
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
  /// - [String]: Timestamp completo formateado para la API (RFC3339 UTC)
  static String formatDateTimeForAPI(DateTime dateTime) {
    // Convertir a UTC y formatear como RFC3339 (ej: "2025-07-24T11:55:59.000Z")
    final utc = dateTime.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}T${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}:${utc.second.toString().padLeft(2, '0')}.${utc.millisecond.toString().padLeft(3, '0')}Z';
  }

  /// Formatea DateTime a RFC3339 UTC - Método helper principal
  ///
  /// Este es el método que debe usarse para todos los timestamps del backend.
  /// Formato esperado: 2025-07-24T11:55:59.000Z
  ///
  /// Parámetros:
  /// - [dateTime]: DateTime a formatear
  ///
  /// Retorna:
  /// - [String]: Timestamp RFC3339 UTC
  static String toRFC3339(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}T${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}:${utc.second.toString().padLeft(2, '0')}.${utc.millisecond.toString().padLeft(3, '0')}Z';
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
    print(
      'CheckInService: Usando headers alternativos: $useAlternativeHeaders',
    );
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
        'User-Agent': 'ABSTI-Flutter-App/1.0',
        'Connection': 'keep-alive',
      });
    }

    print('CheckInService: Headers que se enviarán: $headers');
    final jsonBody = json.encode(requestBody);
    print('CheckInService: JSON body final: $jsonBody');
    print('CheckInService: Longitud del body: ${jsonBody.length} bytes');

    return await http
        .post(Uri.parse('$baseUrl$endpoint'), headers: headers, body: jsonBody)
        .timeout(const Duration(seconds: ApiConstants.timeoutDuration));
  }

  /// Cambiar ubicación durante la jornada laboral
  ///
  /// Este método permite cambiar la ubicación actual del usuario mientras
  /// está trabajando, sin necesidad de hacer check-out y check-in nuevamente.
  ///
  /// Cambiar ubicación durante el trabajo
  ///
  /// Utiliza el endpoint PUT /api/checkins/locations/:id para actualizar
  /// una ubicación específica durante la jornada laboral.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  /// - [locationId]: ID de la ubicación a modificar
  /// - [locationData]: Datos de la nueva ubicación
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Respuesta del servidor con el resultado
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<Map<String, dynamic>?> changeLocationDuringWork(
    String token,
    int locationId,
    Map<String, dynamic> locationData,
  ) async {
    try {
      print('🔄 CheckInService: Iniciando cambio de ubicación durante trabajo...');
      print('🔄 CheckInService: ID de ubicación a editar: $locationId');
      print('🔄 CheckInService: Datos de ubicación: $locationData');
      print('🔄 CheckInService: Token presente: ${token.isNotEmpty}');

      // Usar el endpoint correcto: PUT /api/checkins/locations/:id
      final url = '$baseUrl${ApiConstants.checkinsEndpoint}/locations/$locationId';
      print('🔄 CheckInService: URL completa: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Formatear los datos según el nuevo formato del backend
      print('🔄 CheckInService: locationData recibido: $locationData');
      print('🔄 CheckInService: start_time en locationData: ${locationData['start_time']}');
      print('🔄 CheckInService: end_time en locationData: ${locationData['end_time']}');
      
      // El nuevo formato del backend es más simple, solo los campos directos
      final requestBody = {
        'location_type': locationData['location_type'],
        'location_detail': locationData['location_detail'] ?? _buildLocationDetail(locationData),
        'start_time': locationData['start_time'], // Hora seleccionada por el usuario
        'end_time': locationData['end_time'], // Hora de fin (opcional)
      };
      
      // Limpiar valores null del requestBody
      final Map<String, dynamic> cleanedBody = {};
      requestBody.forEach((key, value) {
        if (value != null) {
          cleanedBody[key] = value;
        }
      });
      
      print('🔄 CheckInService: requestBody limpio: $cleanedBody');

      final jsonBody = json.encode(cleanedBody);
      print('🔄 CheckInService: Request headers: $headers');
      print('🔄 CheckInService: Request body: $jsonBody');

      print('📡 CheckInService: Enviando petición PUT...');
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonBody,
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('📡 CheckInService: Respuesta recibida');
      print('📡 CheckInService: Status code: ${response.statusCode}');
      print('📡 CheckInService: Response headers: ${response.headers}');
      print('📡 CheckInService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          print('✅ CheckInService: Ubicación cambiada exitosamente');
          return {
            'success': true,
            'data': responseData,
            'message': 'Ubicación cambiada exitosamente',
          };
        } catch (e) {
          print('❌ CheckInService: Error parseando respuesta exitosa: $e');
          return {
            'success': true,
            'message': 'Ubicación cambiada exitosamente (respuesta sin parsear)',
          };
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = json.decode(response.body);
          print('❌ CheckInService: Error 400 - ${errorData['message']}');
          return {
            'success': false,
            'message': errorData['message'] ?? 'Datos inválidos',
            'errors': errorData['errors'],
          };
        } catch (e) {
          print('❌ CheckInService: Error 400 - Sin parsear: ${response.body}');
          return {
            'success': false,
            'message': 'Error 400: Datos inválidos',
          };
        }
      } else if (response.statusCode == 401) {
        print('❌ CheckInService: Error 401 - No autorizado');
        return {
          'success': false,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
        };
      } else if (response.statusCode == 403) {
        print('❌ CheckInService: Error 403 - Prohibido');
        return {
          'success': false,
          'message': 'No tienes permisos para realizar esta acción.',
        };
      } else if (response.statusCode == 404) {
        print('❌ CheckInService: Error 404 - Endpoint no encontrado');
        return {
          'success': false,
          'message': 'Sesión de trabajo no encontrada.',
        };
      } else if (response.statusCode == 500) {
        print('❌ CheckInService: Error 500 - Error interno del servidor');
        return {
          'success': false,
          'message': 'Error interno del servidor. Inténtalo más tarde.',
        };
      } else {
        print('❌ CheckInService: Error ${response.statusCode} - Respuesta: ${response.body}');
        return {
          'success': false,
          'message': 'Error del servidor (${response.statusCode}): ${response.reasonPhrase}',
        };
      }
    } on TimeoutException catch (e) {
      print('❌ CheckInService: Timeout al cambiar ubicación: $e');
      return {
        'success': false,
        'message': 'Tiempo de espera agotado. Verifica tu conexión e inténtalo nuevamente.',
      };
    } on SocketException catch (e) {
      print('❌ CheckInService: Error de conexión al cambiar ubicación: $e');
      return {
        'success': false,
        'message': 'Error de conexión. Verifica tu conexión a internet.',
      };
    } catch (e) {
      print('❌ CheckInService: Excepción inesperada al cambiar ubicación: $e');
      return {
        'success': false,
        'message': 'Error inesperado: $e',
      };
    }
  }

  /// Construye el location_detail según el tipo de ubicación
  static String _buildLocationDetail(Map<String, dynamic> locationData) {
    final locationType = locationData['location_type'];
    
    print('🏠 _buildLocationDetail: locationType=$locationType, locationData=$locationData');
    
    // Si es "Domicilio Alternativo" (LocationTypes.REMOTE_ALTERNATIVE = 2)
    if (locationType == 2) {
      print('🏠 _buildLocationDetail: Es domicilio alternativo');
      
      if (locationData['address'] != null && locationData['address'].toString().isNotEmpty) {
        String detail = locationData['address'];
        print('🏠 _buildLocationDetail: Construyendo con address: $detail');
        
        // Agregar piso si está disponible
        if (locationData['floor'] != null && locationData['floor'].toString().isNotEmpty) {
          detail += ', Piso ${locationData['floor']}';
          print('🏠 _buildLocationDetail: Agregando piso: $detail');
        }
        
        // Agregar departamento si está disponible
        if (locationData['apartment'] != null && locationData['apartment'].toString().isNotEmpty) {
          detail += ', Dpto ${locationData['apartment']}';
          print('🏠 _buildLocationDetail: Agregando depto: $detail');
        }
        
        print('🏠 _buildLocationDetail: Detalle final: $detail');
        return detail;
      } else {
        print('🏠 _buildLocationDetail: ⚠️ PROBLEMA: No hay address válida para domicilio alternativo!');
        print('🏠 _buildLocationDetail: address value: ${locationData['address']}');
        // En lugar de retornar "Domicilio Alternativo", intentar usar otros campos o dar error
        return 'Domicilio Alternativo (Sin dirección especificada)';
      }
    }
    
    // Para otros tipos, usar el nombre del tipo de ubicación según LocationTypes
    switch (locationType) {
      case 1: // REMOTE_DECLARED
        return 'Domicilio';
      case 3: // CLIENT
        return 'Cliente';
      case 4: // OFFICE
        return 'Oficina';
      default:
        return 'Ubicación no especificada';
    }
  }

  /// Obtener historial de ubicaciones de la sesión actual de trabajo
  ///
  /// Utiliza el endpoint GET /api/checkins/locations para obtener
  /// el historial real de cambios de ubicación durante la jornada actual.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  ///
  /// Retorna:
  /// - [List<Map<String, dynamic>>]: Lista de ubicaciones con timestamps
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<List<Map<String, dynamic>>> getSessionLocationHistory(String token) async {
    try {
      print('🔍 CheckInService: Obteniendo historial de ubicaciones desde API...');
      
      // Verificar que hay una sesión activa
      final todayCheckIn = await getTodayCheckIn(token);
      if (todayCheckIn == null) {
        print('🔍 CheckInService: No hay sesión de trabajo activa');
        return [];
      }

      // Llamar al endpoint GET /api/checkins/locations
      final url = '$baseUrl${ApiConstants.checkinsEndpoint}/locations';
      print('🔍 CheckInService: URL completa: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('📡 CheckInService: Enviando petición GET al historial de ubicaciones...');
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('📡 CheckInService: Respuesta recibida');
      print('📡 CheckInService: Status code: ${response.statusCode}');
      print('📡 CheckInService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          print('✅ CheckInService: Historial de ubicaciones obtenido exitosamente');
          
          // Procesar los datos del historial
          List<Map<String, dynamic>> locationHistory = [];
          
          if (responseData is List) {
            // Si es una lista directa de ubicaciones
            for (var location in responseData) {
              if (location is Map<String, dynamic>) {
                locationHistory.add(_parseLocationHistoryEntry(location));
              }
            }
          } else if (responseData is Map<String, dynamic>) {
            // Si viene envuelto en un objeto
            if (responseData['data'] is List) {
              for (var location in responseData['data']) {
                if (location is Map<String, dynamic>) {
                  locationHistory.add(_parseLocationHistoryEntry(location));
                }
              }
            } else if (responseData['locations'] is List) {
              for (var location in responseData['locations']) {
                if (location is Map<String, dynamic>) {
                  locationHistory.add(_parseLocationHistoryEntry(location));
                }
              }
            }
          }
          
          // Ordenar por timestamp (más reciente primero para la UI)
          locationHistory.sort((a, b) {
            final timeA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
            final timeB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
            return timeA.compareTo(timeB); // Orden cronológico (más antiguo primero)
          });

          print('🔍 CheckInService: ✅ Historial procesado: ${locationHistory.length} entradas');
          for (int i = 0; i < locationHistory.length; i++) {
            print('🔍   Entrada $i: ${locationHistory[i]}');
          }
          
          return locationHistory;

        } catch (e) {
          print('❌ CheckInService: Error parseando respuesta del historial: $e');
          return [];
        }
      } else if (response.statusCode == 404) {
        // No hay historial (es normal si no se han hecho cambios)
        print('🔍 CheckInService: No hay historial de cambios de ubicación');
        return [];
      } else {
        // Manejar otros errores
        final errorMessage = _getErrorMessage(response.statusCode, response.body);
        print('❌ CheckInService: Error del servidor: $errorMessage');
        return [];
      }

    } catch (e) {
      print('❌ CheckInService: Error obteniendo historial de ubicaciones: $e');
      print('❌ CheckInService: Stack trace: ${StackTrace.current}');
      
      // Convertir errores de red en mensajes más amigables
      if (e.toString().contains('TimeoutException')) {
        print('❌ CheckInService: Timeout al obtener historial');
      } else if (e.toString().contains('SocketException')) {
        print('❌ CheckInService: Error de conexión al obtener historial');
      }
      
      return [];
    }
  }

  /// Parsear una entrada del historial de ubicaciones
  ///
  /// Convierte los datos raw del servidor en el formato esperado por la UI
  ///
  /// Parámetros:
  /// - [data]: Datos raw de una entrada del historial
  ///
  /// Retorna:
  /// - [Map<String, dynamic>]: Entrada formateada para la UI
  static Map<String, dynamic> _parseLocationHistoryEntry(Map<String, dynamic> data) {
    // Determinar el tipo de evento
    String event = 'location_change';
    if (data['event_type'] != null) {
      event = data['event_type'];
    } else if (data['event'] != null) {
      event = data['event'];
    }
    
    // Construir descripción
    String description = '';
    if (data['description'] != null && data['description'].toString().isNotEmpty) {
      description = data['description'];
    } else {
      // Generar descripción basada en el tipo de evento
      final locationDetail = data['location_detail']?.toString() ?? 'Ubicación';
      switch (event) {
        case 'check_in':
          description = 'Inicio de jornada en $locationDetail';
          break;
        case 'check_out':
          description = 'Fin de jornada en $locationDetail';
          break;
        case 'location_change':
        default:
          description = 'Cambio de ubicación a $locationDetail';
          break;
      }
    }

    return {
      'id': data['id'], // Preservar el ID de la ubicación para futuras actualizaciones
      'location_type': data['location_type'] ?? 1,
      'location_detail': data['location_detail']?.toString() ?? '',
      'start_time': data['start_time']?.toString(), // Hora de inicio de la ubicación
      'end_time': data['end_time']?.toString(), // Hora de fin de la ubicación (si la tiene)
      'timestamp': data['timestamp'] ?? data['created_at'] ?? data['updated_at'] ?? DateTime.now().toIso8601String(),
      'event': event,
      'description': description,
    };
  }
}
