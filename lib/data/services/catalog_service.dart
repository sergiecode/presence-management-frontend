/// Servicio para obtener catálogos de la aplicación ABSTI
///
/// Este servicio maneja las operaciones relacionadas con la obtención
/// de catálogos como ubicaciones, países, etc.
///
/// Utiliza HTTP para comunicarse con la API del backend.
///
/// Ejemplo de uso:
/// ```dart
/// try {
///   final locations = await CatalogService.getLocations(token);
///   print('Ubicaciones obtenidas: ${locations.length}');
///   for (final location in locations) {
///     print('- ${location.name}: ${location.description}');
///   }
/// } catch (e) {
///   print('Error obteniendo ubicaciones: $e');
/// }
/// ```
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

/// Modelo para las ubicaciones del catálogo
class CatalogLocation {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final bool isActive;
  
  CatalogLocation({
    required this.id,
    required this.name,
    this.description,
    this.address,
    required this.isActive,
  });

  factory CatalogLocation.fromJson(Map<String, dynamic> json) {
    return CatalogLocation(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'is_active': isActive,
    };
  }
}

/// Servicio que maneja las operaciones de catálogos
class CatalogService {
  /// URL base de la API (se obtiene de las constantes)
  static final String baseUrl = ApiConstants.baseUrl;

  /// Obtener todas las ubicaciones del catálogo
  ///
  /// Este método obtiene todas las ubicaciones disponibles en el catálogo
  /// como oficinas, sucursales, etc.
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  ///
  /// Retorna:
  /// - [List<CatalogLocation>]: Lista de ubicaciones del catálogo
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<List<CatalogLocation>> getLocations(String token) async {
    try {
      print('CatalogService: === INICIO OBTENER UBICACIONES ===');
      print('CatalogService: Token length: ${token.length}');
      print('CatalogService: Token starts with: ${token.substring(0, 10)}...');

      final url = '$baseUrl/api/catalog/locations';
      print('CatalogService: URL completa: $url');
      print('CatalogService: BaseUrl: $baseUrl');

      print('CatalogService: Enviando request...');
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('CatalogService: Response recibida!');
      print('CatalogService: Status Code: ${response.statusCode}');
      print('CatalogService: Headers: ${response.headers}');
      print('CatalogService: Body length: ${response.body.length}');
      print('CatalogService: Body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('CatalogService: Response body type: ${responseBody.runtimeType}');
        
        final dynamic responseData = json.decode(responseBody);
        print('CatalogService: Decoded data type: ${responseData.runtimeType}');
        
        // El endpoint puede devolver diferentes formatos
        List<dynamic> locationsList;
        
        if (responseData is List<dynamic>) {
          // Si la respuesta es directamente un array
          locationsList = responseData;
          print('CatalogService: Response is direct array with ${locationsList.length} items');
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          // Si la respuesta tiene formato { data: [...] }
          locationsList = responseData['data'] as List<dynamic>;
          print('CatalogService: Response is object with data property containing ${locationsList.length} items');
        } else {
          // Si la respuesta es un solo objeto, convertir a array
          locationsList = [responseData];
          print('CatalogService: Response is single object, converted to array');
        }

        final List<CatalogLocation> locations = locationsList
            .map((item) => CatalogLocation.fromJson(item as Map<String, dynamic>))
            .where((location) => location.isActive) // Solo ubicaciones activas
            .toList();

        print('CatalogService: ${locations.length} ubicaciones obtenidas');
        return locations;
      } else {
        // Manejar errores de la API
        final errorMessage = _getErrorMessage(response.statusCode, response.body);
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      print('CatalogService: ERROR - Sin conexión a internet: $e');
      throw Exception('Sin conexión a internet: ${e.message}');
    } on TimeoutException catch (e) {
      print('CatalogService: ERROR - Tiempo agotado: $e');
      throw Exception('Tiempo de espera agotado: ${e.message}');
    } on FormatException catch (e) {
      print('CatalogService: ERROR - Formato inválido: $e');
      throw Exception('Error de formato JSON: ${e.message}');
    } catch (e) {
      print('CatalogService: ERROR - General: $e');
      print('CatalogService: ERROR - Type: ${e.runtimeType}');
      throw Exception('Error obteniendo ubicaciones: $e');
    }
  }

  /// Extrae el mensaje de error de la respuesta de la API
  static String _getErrorMessage(int statusCode, String responseBody) {
    try {
      final Map<String, dynamic> errorData = json.decode(responseBody);
      
      // Intentar obtener el mensaje de error de diferentes campos posibles
      if (errorData.containsKey('message')) {
        return errorData['message'] as String;
      } else if (errorData.containsKey('error')) {
        return errorData['error'] as String;
      } else if (errorData.containsKey('detail')) {
        return errorData['detail'] as String;
      }
    } catch (e) {
      // Si no se puede parsear el JSON, usar mensajes predeterminados
    }

    // Mensajes de error basados en el código de estado
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida';
      case 401:
        return 'No autorizado. Inicie sesión nuevamente';
      case 403:
        return 'Sin permisos para acceder a esta información';
      case 404:
        return 'Ubicaciones no encontradas';
      case 500:
        return 'Error interno del servidor';
      default:
        return 'Error del servidor (código: $statusCode)';
    }
  }
}
