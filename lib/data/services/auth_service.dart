/// Servicio de autenticación para la aplicación ABSTI
///
/// Este servicio maneja todas las operaciones relacionadas con la autenticación
/// de usuarios, incluyendo login, registro y validación de tokens.
///
/// Utiliza HTTP para comunicarse con la API del backend.
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

/// Servicio que maneja la autenticación de usuarios
class AuthService {
  /// URL base de la API (se obtiene de las constantes)
  static final String _baseUrl = ApiConstants.baseUrl;

  /// Método para iniciar sesión con email y contraseña
  ///
  /// Parámetros:
  /// - [email]: Email del usuario
  /// - [password]: Contraseña del usuario
  ///
  /// Retorna:
  /// - [String?]: Token de autenticación si el login es exitoso, null si falla
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<String?> login(String email, String password) async {
    try {
      // Construir la URL completa para el endpoint de login
      final url = Uri.parse('$_baseUrl${ApiConstants.loginEndpoint}');

      print('AuthService: ===== INFORMACIÓN DE DEBUG =====');
      print('AuthService: URL completa: $url');
      print('AuthService: Base URL: $_baseUrl');
      print('AuthService: Login endpoint: ${ApiConstants.loginEndpoint}');
      print('AuthService: Intentando login para email: $email');
      print(
        'AuthService: Timeout configurado: ${ApiConstants.timeoutDuration} segundos',
      );

      // Preparar el cuerpo de la petición
      final requestBody = {'email': email, 'password': password};
      final jsonBody = jsonEncode(requestBody);

      print('AuthService: Cuerpo de la petición: $jsonBody');

      // Realizar petición POST con las credenciales
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonBody,
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('AuthService: ===== RESPUESTA DEL SERVIDOR =====');
      print('AuthService: Código de estado: ${response.statusCode}');
      print('AuthService: Headers de respuesta: ${response.headers}');
      print('AuthService: Cuerpo de respuesta: ${response.body}');

      // Verificar si la respuesta es exitosa (código 200)
      if (response.statusCode == 200) {
        try {
          // Decodificar la respuesta JSON
          final data = jsonDecode(response.body);
          print('AuthService: Datos decodificados: $data');

          // Extraer y retornar el token de autenticación
          final token = data['token'] as String?;

          if (token != null) {
            print('AuthService: Login exitoso - Token recibido');
            return token;
          } else {
            print('AuthService: ERROR - Token no encontrado en la respuesta');
            print(
              'AuthService: Estructura de datos recibida: ${data.keys.toList()}',
            );
            throw Exception('Token no encontrado en la respuesta del servidor');
          }
        } catch (jsonError) {
          print('AuthService: ERROR decodificando JSON: $jsonError');
          print('AuthService: Respuesta cruda: ${response.body}');
          throw Exception('Error decodificando respuesta del servidor');
        }
      } else {
        // Manejar errores de autenticación
        print(
          'AuthService: ERROR - Código de estado no exitoso: ${response.statusCode}',
        );

        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Error de autenticación';
          print('AuthService: Mensaje de error del servidor: $errorMessage');
          throw Exception(errorMessage);
        } catch (jsonError) {
          print(
            'AuthService: Error decodificando mensaje de error: $jsonError',
          );
          print('AuthService: Respuesta de error cruda: ${response.body}');
          throw Exception(
            'Error del servidor (${response.statusCode}): ${response.body}',
          );
        }
      }
    } catch (e) {
      // Capturar y relanzar cualquier excepción
      print('AuthService: ===== EXCEPCIÓN CAPTURADA =====');
      print('AuthService: Tipo de excepción: ${e.runtimeType}');
      print('AuthService: Mensaje de excepción: $e');
      print(
        'AuthService: Stack trace disponible: ${e is Error ? e.stackTrace : 'No disponible'}',
      );

      if (e.toString().contains('TimeoutException')) {
        print('AuthService: Detectado error de timeout');
        throw Exception(ErrorMessages.timeoutError);
      } else if (e.toString().contains('SocketException')) {
        print('AuthService: Detectado error de conexión de red');
        throw Exception(ErrorMessages.networkError);
      } else if (e.toString().contains('HandshakeException')) {
        print('AuthService: Detectado error de SSL/TLS');
        throw Exception(
          'Error de conexión segura. Verifica la URL del servidor.',
        );
      } else if (e.toString().contains('FormatException')) {
        print('AuthService: Detectado error de formato de URL');
        throw Exception('Error en el formato de la URL del servidor.');
      } else {
        print('AuthService: Error no categorizado');
        throw Exception('Error de autenticación: ${e.toString()}');
      }
    }
  }

  /// Método para registrar un nuevo usuario
  ///
  /// Parámetros:
  /// - [email]: Email del nuevo usuario
  /// - [name]: Nombre del usuario
  /// - [password]: Contraseña del usuario
  /// - [phone]: Teléfono del usuario
  /// - [surname]: Apellido del usuario
  ///
  /// Retorna:
  /// - [bool]: true si el registro es exitoso, false en caso contrario
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de red o del servidor
  static Future<bool> register({
    required String email,
    required String name,
    required String password,
    required String phone,
    required String surname,
  }) async {
    try {
      // Construir la URL completa para el endpoint de registro
      final url = Uri.parse('$_baseUrl${ApiConstants.registerEndpoint}');

      print('AuthService: Intentando registro para $email');

      // Realizar petición POST con los datos del usuario
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'name': name,
              'password': password,
              'phone': phone,
              'surname': surname,
            }),
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutDuration));

      print('AuthService: Respuesta de registro: ${response.statusCode}');

      // Verificar si el registro fue exitoso (códigos 200 o 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('AuthService: Registro exitoso');
        return true;
      } else {
        // Manejar errores de registro
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Error en el registro';

        print('AuthService: Error de registro: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Capturar y relanzar cualquier excepción
      print('AuthService: Excepción durante registro: $e');

      if (e.toString().contains('TimeoutException')) {
        throw Exception(ErrorMessages.timeoutError);
      } else if (e.toString().contains('SocketException')) {
        throw Exception(ErrorMessages.networkError);
      } else {
        throw Exception('Error de registro: ${e.toString()}');
      }
    }
  }

  /// Método para validar si un token de autenticación es válido
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación a validar
  ///
  /// Retorna:
  /// - [bool]: true si el token es válido, false en caso contrario
  ///
  /// Nota: Este método puede implementarse en el futuro cuando
  /// el backend proporcione un endpoint de validación de tokens
  static Future<bool> validateToken(String token) async {
    try {
      // TODO: Implementar validación de token con el backend
      // Por ahora, asumimos que el token es válido si no está vacío
      return token.isNotEmpty;
    } catch (e) {
      print('AuthService: Error validando token: $e');
      return false;
    }
  }

  /// Método para cerrar sesión (logout)
  ///
  /// Parámetros:
  /// - [token]: Token de autenticación del usuario
  ///
  /// Retorna:
  /// - [bool]: true si el logout es exitoso, false en caso contrario
  ///
  /// Nota: Este método puede implementarse en el futuro cuando
  /// el backend proporcione un endpoint de logout
  static Future<bool> logout(String token) async {
    try {
      // TODO: Implementar logout con el backend si es necesario
      // Por ahora, simplemente retornamos true
      print('AuthService: Logout realizado');
      return true;
    } catch (e) {
      print('AuthService: Error durante logout: $e');
      return false;
    }
  }
}
