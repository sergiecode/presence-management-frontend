/// Proveedor de autenticación para la aplicación Tareas
///
/// Este proveedor maneja el estado global de autenticación de la aplicación,
/// incluyendo login, logout, persistencia de tokens y verificación de estado.
///
/// Utiliza ChangeNotifier para notificar cambios de estado a los widgets
/// que escuchan estos cambios.
///
/// Autor: Equipo Gold
/// Fecha: 2025
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Proveedor que maneja el estado de autenticación global de la aplicación
class AuthProvider with ChangeNotifier {
  // Variables privadas para el estado de autenticación
  String? _token;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  bool _isLoading = false;

  // Getters públicos para acceder al estado (solo lectura)

  /// Token de autenticación actual
  String? get token => _token;

  /// Indica si el usuario está autenticado
  bool get isAuthenticated => _isAuthenticated;

  /// Indica si el proveedor ha terminado de inicializarse
  bool get isInitialized => _isInitialized;

  /// Indica si hay una operación en progreso
  bool get isLoading => _isLoading;

  /// Constructor que inicializa automáticamente el estado de autenticación
  AuthProvider() {
    _initAuth();
  }

  /// Inicializar el estado de autenticación al arrancar la aplicación
  ///
  /// Este método verifica si existe un token guardado localmente
  /// y actualiza el estado de autenticación en consecuencia.
  Future<void> _initAuth() async {
    try {
      print('AuthProvider: Inicializando autenticación...');

      // Obtener instancia de SharedPreferences para acceder al almacenamiento local
      final prefs = await SharedPreferences.getInstance();

      // Buscar token guardado en el almacenamiento local
      _token = prefs.getString('auth_token');

      // Si existe un token, validarlo con el servidor (opcional)
      if (_token != null) {
        print('AuthProvider: Token encontrado, validando...');

        // Opcional: Validar token con el servidor
        final isValid = await AuthService.validateToken(_token!);

        if (isValid) {
          _isAuthenticated = true;
          print('AuthProvider: Token válido, usuario autenticado');
        } else {
          // Si el token no es válido, limpiarlo
          await _clearStoredToken();
          print('AuthProvider: Token inválido, limpiando...');
        }
      } else {
        print('AuthProvider: No hay token guardado');
      }

      // Marcar la inicialización como completada
      _isInitialized = true;

      print(
        'AuthProvider: Inicialización completa - isAuthenticated: $_isAuthenticated',
      );

      // Notificar a los widgets que escuchan este proveedor
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Error durante inicialización: $e');

      // En caso de error, marcar como no autenticado pero inicializado
      _isAuthenticated = false;
      _isInitialized = true;
      _token = null;

      notifyListeners();
    }
  }

  /// Realizar login con las credenciales del usuario
  ///
  /// Parámetros:
  /// - [email]: Email del usuario
  /// - [password]: Contraseña del usuario
  ///
  /// Retorna:
  /// - [bool]: true si el login fue exitoso, false en caso contrario
  ///
  /// Excepciones:
  /// - Puede lanzar [Exception] si hay errores de autenticación o red
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('AuthProvider: Intentando login para $email');

      // Realizar login usando el servicio de autenticación
      final token = await AuthService.login(email, password);

      if (token != null) {
        // Guardar token en almacenamiento local
        await _saveToken(token);

        // Actualizar estado de autenticación
        _token = token;
        _isAuthenticated = true;

        print('AuthProvider: Login exitoso');

        _isLoading = false;
        notifyListeners();

        return true;
      } else {
        print('AuthProvider: Login fallido - token nulo');

        _isLoading = false;
        notifyListeners();

        return false;
      }
    } catch (e) {
      print('AuthProvider: Error durante login: $e');

      _isLoading = false;
      notifyListeners();

      // Re-lanzar la excepción para que la UI pueda mostrar el error
      rethrow;
    }
  }

  /// Realizar logout y limpiar el estado de autenticación
  ///
  /// Este método limpia el token tanto del estado en memoria
  /// como del almacenamiento local persistente.
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('AuthProvider: Iniciando logout...');

      // Opcional: Notificar al servidor sobre el logout
      if (_token != null) {
        await AuthService.logout(_token!);
      }

      // Limpiar token del almacenamiento local
      await _clearStoredToken();

      // Limpiar estado en memoria
      _token = null;
      _isAuthenticated = false;

      print('AuthProvider: Logout completado');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Error durante logout: $e');

      // Incluso si hay error, limpiar el estado local
      _token = null;
      _isAuthenticated = false;
      _isLoading = false;

      await _clearStoredToken();

      notifyListeners();
    }
  }

  /// Verificar si el token actual es válido
  ///
  /// Retorna:
  /// - [bool]: true si el token es válido, false en caso contrario
  Future<bool> isTokenValid() async {
    try {
      if (_token == null) return false;

      // Validar token con el servidor
      return await AuthService.validateToken(_token!);
    } catch (e) {
      print('AuthProvider: Error validando token: $e');
      return false;
    }
  }

  /// Refrescar el estado de autenticación
  ///
  /// Útil para verificar el estado después de cambios externos
  /// o para forzar una re-validación del token.
  Future<void> refreshAuthState() async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_token != null) {
        final isValid = await AuthService.validateToken(_token!);

        if (!isValid) {
          // Token inválido, realizar logout
          await logout();
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Error refrescando estado: $e');

      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar token (útil si el servidor proporciona token refresh)
  ///
  /// Parámetros:
  /// - [newToken]: Nuevo token de autenticación
  Future<void> updateToken(String newToken) async {
    try {
      await _saveToken(newToken);

      _token = newToken;
      _isAuthenticated = true;

      print('AuthProvider: Token actualizado');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Error actualizando token: $e');
    }
  }

  /// Método privado para guardar token en almacenamiento local
  ///
  /// Parámetros:
  /// - [token]: Token a guardar
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('AuthProvider: Token guardado en almacenamiento local');
    } catch (e) {
      print('AuthProvider: Error guardando token: $e');
      throw Exception('Error guardando credenciales');
    }
  }

  /// Método privado para limpiar token del almacenamiento local
  Future<void> _clearStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('AuthProvider: Token removido del almacenamiento local');
    } catch (e) {
      print('AuthProvider: Error limpiando token: $e');
    }
  }

  /// Obtener información básica del usuario desde el token (si está disponible)
  ///
  /// Nota: Este método podría expandirse en el futuro para decodificar
  /// información del JWT token si el backend lo proporciona.
  ///
  /// Retorna:
  /// - [Map<String, dynamic>?]: Información básica del usuario o null
  Map<String, dynamic>? getUserInfo() {
    if (_token == null) return null;

    // TODO: Implementar decodificación de JWT si es necesario
    // Por ahora, retornar información básica
    return {
      'hasToken': true,
      'isAuthenticated': _isAuthenticated,
      'tokenLength': _token!.length,
    };
  }

  /// Verificar si necesita renovar autenticación
  ///
  /// Útil para verificar si el token está próximo a expirar
  /// (requiere que el backend proporcione información de expiración)
  ///
  /// Retorna:
  /// - [bool]: true si necesita renovar, false en caso contrario
  bool needsAuthRefresh() {
    if (_token == null) return true;

    // TODO: Implementar verificación de expiración de token
    // Por ahora, retornar false (no necesita renovación)
    return false;
  }

  /// Limpiar completamente el estado (útil para pruebas o reset de app)
  Future<void> clearState() async {
    await _clearStoredToken();

    _token = null;
    _isAuthenticated = false;
    _isInitialized = false;
    _isLoading = false;

    notifyListeners();
  }
}
