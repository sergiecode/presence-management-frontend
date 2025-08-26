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
    print('🔧 AuthProvider: Constructor llamado');
    _initAuth();
  }

  // --- MÉTODOS PÚBLICOS ---

  /// Realiza el login con email y contraseña.
  /// Si [saveBiometrics] es true, guarda las credenciales para futuro uso biométrico.
  Future<bool> login(String email, String password, {bool saveBiometrics = false}) async {
    print('🔑 AuthProvider: Iniciando login para $email');
    print('🔑 AuthProvider: saveBiometrics = $saveBiometrics');
    _setLoading(true);
    _setError(null);

    try {
      print('🔑 AuthProvider: Llamando a AuthService.login...');
      final token = await AuthService.login(email, password);
      
      if (token != null) {
        print('🔑 AuthProvider: Login exitoso, token recibido. Longitud: ${token.length}');
        print('🔑 AuthProvider: Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        
        await _saveToken(token);
        _token = token;
        _isAuthenticated = true;

        if (saveBiometrics) {
          print('🔑 AuthProvider: Guardando credenciales para biometría...');
          await _saveCredentialsForBiometrics(email, password);
          print('🔑 AuthProvider: Credenciales guardadas exitosamente');
        }
        
        _setLoading(false);
        print('🔑 AuthProvider: Login completado exitosamente');
        return true;
      } else {
        print('🔑 AuthProvider: Login fallido, credenciales incorrectas.');
        _setError('Credenciales incorrectas.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('🔑 AuthProvider: Error durante el login: $e');
      print('🔑 AuthProvider: Tipo de error: ${e.runtimeType}');
      print('🔑 AuthProvider: Stack trace: ${StackTrace.current}');
      
      // Extraer el mensaje de error limpio
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      print('🔑 AuthProvider: Mensaje de error procesado: $errorMessage');
      
      // Preservar el mensaje específico del AuthService
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  /// Realiza el logout, limpiando el token y las credenciales biométricas.
  Future<void> logout({bool clearBiometricCredentials = false}) async {
    print('🚪 AuthProvider: Iniciando logout...');
    print('🚪 AuthProvider: clearBiometricCredentials = $clearBiometricCredentials');
    _setLoading(true);
    
    if (_token != null) {
      print('🚪 AuthProvider: Token presente, longitud: ${_token!.length}');
      // Opcional: notificar al backend sobre el logout
      // await AuthService.logout(_token!);
    } else {
      print('🚪 AuthProvider: No hay token para limpiar');
    }
    
    await _clearStoredToken();
    print('🚪 AuthProvider: Token local eliminado');

    if (clearBiometricCredentials) {
      await _clearSavedCredentials();
      print('🚪 AuthProvider: Credenciales biométricas también eliminadas.');
    }

    _token = null;
    _isAuthenticated = false;
    print('🚪 AuthProvider: Logout completado.');
    _setLoading(false);
  }

  /// Intenta autenticar al usuario usando biometría (huella/rostro).
  Future<bool> authenticateWithBiometrics() async {
    print('🔐 AuthProvider: Iniciando autenticación biométrica.');
    _setLoading(true);
    _setError(null);

    try {
      print('🔐 AuthProvider: Verificando credenciales guardadas...');
      if (!await hasSavedCredentials()) {
        print('🔐 AuthProvider: No hay credenciales guardadas para biometría.');
        _setError('No hay credenciales guardadas para la biometría.');
        _setLoading(false);
        return false;
      }

      print('🔐 AuthProvider: Verificando disponibilidad de biometría...');
      final isAvailable = await _localAuth.canCheckBiometrics;
      print('🔐 AuthProvider: Biometría disponible: $isAvailable');
      
      if (!isAvailable) {
        print('🔐 AuthProvider: Biometría no disponible en el dispositivo.');
        _setError('La biometría no está disponible en este dispositivo.');
        _setLoading(false);
        return false;
      }

      print('🔐 AuthProvider: Iniciando autenticación biométrica...');
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Usa tu huella o rostro para ingresar',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      print('🔐 AuthProvider: Resultado de autenticación biométrica: $didAuthenticate');

      if (didAuthenticate) {
        print('🔐 AuthProvider: Biometría exitosa. Realizando login con credenciales guardadas.');
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('saved_email')!;
        final password = prefs.getString('saved_password')!;
        print('🔐 AuthProvider: Credenciales recuperadas - Email: $email, Password: ${password.length > 0 ? "***" : "VACÍA"}');
        
        // Reutiliza la lógica de login principal con las credenciales guardadas
        return await login(email, password);
      } else {
        print('🔐 AuthProvider: Autenticación biométrica cancelada por el usuario.');
        _setError('Autenticación biométrica cancelada.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('🔐 AuthProvider: Error durante la autenticación biométrica: $e');
      print('🔐 AuthProvider: Stack trace: ${StackTrace.current}');
      _setError('Error en la autenticación biométrica.');
      _setLoading(false);
      return false;
    }
  }

  /// Verifica si existen credenciales guardadas para la autenticación biométrica.
  Future<bool> hasSavedCredentials() async {
    print('🔍 AuthProvider: Verificando credenciales guardadas...');
    final prefs = await SharedPreferences.getInstance();
    
    final hasEmail = prefs.containsKey('saved_email');
    final hasPassword = prefs.containsKey('saved_password');
    
    print('🔍 AuthProvider: Email guardado: $hasEmail, Password guardada: $hasPassword');
    
    if (hasEmail && hasPassword) {
      final email = prefs.getString('saved_email');
      final password = prefs.getString('saved_password');
      print('🔍 AuthProvider: Email: $email, Password length: ${password?.length ?? 0}');
    }
    
    final hasCreds = hasEmail && hasPassword;
    print('🔍 AuthProvider: Credenciales completas: $hasCreds');
    return hasCreds;
  }

  /// Verificar si el token actual es válido
  Future<bool> isTokenValid() async {
    print('✅ AuthProvider: Verificando validez del token...');
    try {
      if (_token == null) {
        print('✅ AuthProvider: No hay token para validar');
        return false;
      }
      
      print('✅ AuthProvider: Token presente, longitud: ${_token!.length}');
      final isValid = await AuthService.validateToken(_token!);
      print('✅ AuthProvider: Token válido: $isValid');
      return isValid;
    } catch (e) {
      print('✅ AuthProvider: Error validando token: $e');
      return false;
    }
  }

  /// Refrescar el estado de autenticación
  Future<void> refreshAuthState() async {
    print('🔄 AuthProvider: Refrescando estado de autenticación...');
    try {
      _setLoading(true);
      if (_token != null) {
        print('🔄 AuthProvider: Token presente, validando...');
        final isValid = await AuthService.validateToken(_token!);
        if (!isValid) {
          print('🔄 AuthProvider: Token inválido, haciendo logout...');
          await logout();
        } else {
          print('🔄 AuthProvider: Token válido, estado refrescado');
        }
      } else {
        print('🔄 AuthProvider: No hay token para refrescar');
      }
      _setLoading(false);
    } catch (e) {
      print('🔑 AuthProvider: Error refrescando estado: $e');
      _setLoading(false);
    }
  }

  Future<void> clearBiometricCredentials() async {
    print('🧹 AuthProvider: Limpiando credenciales biométricas manualmente...');
    await _clearSavedCredentials();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_login_enabled', false);
    print('🔑 AuthProvider: Credenciales biométricas eliminadas manualmente.');
    notifyListeners();
  }

  /// Obtener información básica del usuario desde el token
  Map<String, dynamic>? getUserInfo() {
    print('👤 AuthProvider: Obteniendo información del usuario...');
    if (_token == null) {
      print('👤 AuthProvider: No hay token disponible');
      return null;
    }
    
    final info = {
      'hasToken': true,
      'isAuthenticated': _isAuthenticated,
      'tokenLength': _token!.length,
    };
    
    print('👤 AuthProvider: Información del usuario: $info');
    return info;
  }

  /// Verificar si necesita renovar autenticación
  bool needsAuthRefresh() {
    print('🔄 AuthProvider: Verificando si necesita renovar autenticación...');
    if (_token == null) {
      print('🔄 AuthProvider: No hay token, necesita renovación');
      return true;
    }
    print('🔄 AuthProvider: Token presente, no necesita renovación');
    return false;
  }

  /// Limpiar completamente el estado
  Future<void> clearState() async {
    print('🧹 AuthProvider: Limpiando estado completamente...');
    await _clearStoredToken();
    await _clearSavedCredentials();
    _token = null;
    _isAuthenticated = false;
    _isInitialized = false;
    _isLoading = false;
    _error = null;
    print('🧹 AuthProvider: Estado completamente limpiado');
    notifyListeners();
  }

  // --- MÉTODOS PRIVADOS DE GESTIÓN DE ESTADO ---

  /// Inicializa el estado de autenticación al arrancar la app.
  Future<void> _initAuth() async {
    print('🚀 AuthProvider: Inicializando...');
    try {
      final prefs = await SharedPreferences.getInstance();
      print('🚀 AuthProvider: SharedPreferences obtenido');
      
      _token = prefs.getString('auth_token');
      print('🚀 AuthProvider: Token recuperado de SharedPreferences: ${_token != null ? "SÍ" : "NO"}');

      if (_token != null) {
        print('🚀 AuthProvider: Token encontrado. Longitud: ${_token!.length}');
        print('🚀 AuthProvider: Validando token...');
        final isValid = await AuthService.validateToken(_token!);
        if (isValid) {
          _isAuthenticated = true;
          print('🚀 AuthProvider: Token válido. Usuario autenticado.');
        } else {
          print('🚀 AuthProvider: Token inválido. Limpiando...');
          await _clearStoredToken();
        }
      } else {
        print('🚀 AuthProvider: No se encontró token.');
      }
    } catch (e) {
      print('🚀 AuthProvider: Error durante inicialización: $e');
      print('🚀 AuthProvider: Stack trace: ${StackTrace.current}');
      _isAuthenticated = false;
      _token = null;
    }
    
    _isInitialized = true;
    print('🚀 AuthProvider: Inicialización completa. Autenticado: $_isAuthenticated');
    notifyListeners();
  }

  void _setLoading(bool loading) {
    print('⏳ AuthProvider: Cambiando loading a: $loading');
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    print('❌ AuthProvider: Estableciendo error: $error');
    _error = error;
    notifyListeners();
  }

  // --- MÉTODOS PRIVADOS DE ALMACENAMIENTO ---

  Future<void> _saveToken(String token) async {
    print('💾 AuthProvider: Guardando token localmente...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('💾 AuthProvider: Token guardado localmente exitosamente');
    } catch (e) {
      print('💾 AuthProvider: Error guardando token: $e');
      rethrow;
    }
  }

  Future<void> _clearStoredToken() async {
    print('🗑️ AuthProvider: Eliminando token local...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('🗑️ AuthProvider: Token local eliminado exitosamente');
    } catch (e) {
      print('🗑️ AuthProvider: Error eliminando token: $e');
    }
  }

  Future<void> _saveCredentialsForBiometrics(String email, String password) async {
    print('💾 AuthProvider: Guardando credenciales para biometría...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      print('💾 AuthProvider: Credenciales para biometría guardadas exitosamente');
    } catch (e) {
      print('💾 AuthProvider: Error guardando credenciales: $e');
      rethrow;
    }
  }

  Future<void> _clearSavedCredentials() async {
    print('🗑️ AuthProvider: Eliminando credenciales guardadas...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      print('🗑️ AuthProvider: Credenciales para biometría eliminadas exitosamente');
    } catch (e) {
      print('🗑️ AuthProvider: Error eliminando credenciales: $e');
    }
  }
}