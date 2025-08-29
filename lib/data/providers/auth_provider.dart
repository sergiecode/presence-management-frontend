/// Proveedor de autenticación para la aplicación ABSTI
///
/// Este proveedor maneja el estado global de autenticación de la aplicación,
/// incluyendo login, logout, persistencia de tokens y verificación de estado.
///
/// Utiliza ChangeNotifier para notificar cambios de estado a los widgets
/// que escuchan estos cambios.
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
/// Proveedor de autenticación para la aplicación ABSTI
library;

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Proveedor que maneja el estado de autenticación global de la aplicación
class AuthProvider with ChangeNotifier {
  // --- ESTADO INTERNO ---
  String? _token;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  final LocalAuthentication _localAuth = LocalAuthentication();

  // --- GETTERS PÚBLICOS (SOLO LECTURA) ---
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Constructor que inicializa el estado de autenticación
  AuthProvider() {
    _initAuth();
  }

  // --- MÉTODOS PÚBLICOS ---

  /// Realiza el login con email y contraseña.
  /// Si [saveBiometrics] es true, guarda las credenciales para futuro uso biométrico.
  Future<bool> login(String email, String password, {bool saveBiometrics = false}) async {
    _setLoading(true);
    _setError(null);

    try {
      final token = await AuthService.login(email, password);
      
      if (token != null) {
        
        await _saveToken(token);
        _token = token;
        _isAuthenticated = true;

        if (saveBiometrics) {
          await _saveCredentialsForBiometrics(email, password);
        }
        
        _setLoading(false);
        return true;
      } else {
        _setError('Credenciales incorrectas.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      
      // Extraer el mensaje de error limpio
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      
      // Preservar el mensaje específico del AuthService
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  /// Realiza el logout, limpiando el token y las credenciales biométricas.
  Future<void> logout({bool clearBiometricCredentials = false}) async {
    _setLoading(true);
    
    if (_token != null) {
      // Opcional: notificar al backend sobre el logout
      // await AuthService.logout(_token!);
    } else {
    }
    
    await _clearStoredToken();

    if (clearBiometricCredentials) {
      await _clearSavedCredentials();
    }

    _token = null;
    _isAuthenticated = false;
    _setLoading(false);
  }

  /// Intenta autenticar al usuario usando biometría (huella/rostro).
  Future<bool> authenticateWithBiometrics() async {
    _setLoading(true);
    _setError(null);

    try {
      if (!await hasSavedCredentials()) {
        _setError('No hay credenciales guardadas para la biometría.');
        _setLoading(false);
        return false;
      }

      final isAvailable = await _localAuth.canCheckBiometrics;
      
      if (!isAvailable) {
        _setError('La biometría no está disponible en este dispositivo.');
        _setLoading(false);
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Usa tu huella o rostro para ingresar',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );


      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('saved_email')!;
        final password = prefs.getString('saved_password')!;
        
        // Reutiliza la lógica de login principal con las credenciales guardadas
        return await login(email, password);
      } else {
        _setError('Autenticación biométrica cancelada.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error en la autenticación biométrica.');
      _setLoading(false);
      return false;
    }
  }

  /// Verifica si existen credenciales guardadas para la autenticación biométrica.
  Future<bool> hasSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    final hasEmail = prefs.containsKey('saved_email');
    final hasPassword = prefs.containsKey('saved_password');
    
    
    if (hasEmail && hasPassword) {
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');
    }
    
    final hasCreds = hasEmail && hasPassword;
    return hasCreds;
  }

  /// Verificar si el token actual es válido
  Future<bool> isTokenValid() async {
    try {
      if (_token == null) {
        return false;
      }
      
      final isValid = await AuthService.validateToken(_token!);
      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// Refrescar el estado de autenticación
  Future<void> refreshAuthState() async {
    try {
      _setLoading(true);
      if (_token != null) {
        final isValid = await AuthService.validateToken(_token!);
        if (!isValid) {
          await logout();
        } else {
        }
      } else {
      }
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  Future<void> clearBiometricCredentials() async {
    await _clearSavedCredentials();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_login_enabled', false);
    notifyListeners();
  }

  /// Obtener información básica del usuario desde el token
  Map<String, dynamic>? getUserInfo() {
    if (_token == null) {
      return null;
    }
    
    final info = {
      'hasToken': true,
      'isAuthenticated': _isAuthenticated,
      'tokenLength': _token!.length,
    };
    
    return info;
  }

  /// Verificar si necesita renovar autenticación
  bool needsAuthRefresh() {
    if (_token == null) {
      return true;
    }
    return false;
  }

  /// Limpiar completamente el estado
  Future<void> clearState() async {
    await _clearStoredToken();
    await _clearSavedCredentials();
    _token = null;
    _isAuthenticated = false;
    _isInitialized = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // --- MÉTODOS PRIVADOS DE GESTIÓN DE ESTADO ---

  /// Inicializa el estado de autenticación al arrancar la app.
  Future<void> _initAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _token = prefs.getString('auth_token');

      if (_token != null) {
        final isValid = await AuthService.validateToken(_token!);
        if (isValid) {
          _isAuthenticated = true;
        } else {
          await _clearStoredToken();
        }
      } else {
      }
    } catch (e) {
      _isAuthenticated = false;
      _token = null;
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // --- MÉTODOS PRIVADOS DE ALMACENAMIENTO ---

  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _clearStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
    }
  }

  Future<void> _saveCredentialsForBiometrics(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    } catch (e) {
    }
  }
}