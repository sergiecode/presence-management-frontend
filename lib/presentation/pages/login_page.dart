import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones de la nueva estructura
import '../../data/providers/auth_provider.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';

// Importaciones de autenticación
import 'package:local_auth/local_auth.dart';

/// **PÁGINA: Inicio de Sesión**
///
/// Página principal para que los usuarios inicien sesión en la aplicación.
/// Implementa los principios de Atomic Design usando átomos y moléculas.
///
/// **Funcionalidades:**
/// - Formulario de login con validación
/// - Navegación a página de registro
/// - Manejo de mensajes de éxito desde el registro
/// - Integración completa con el sistema de autenticación
/// - UI responsive y accesible
///
/// **Componentes utilizados:**
/// - AppLogo (átomo)
/// - LoginForm (molécula)
/// - CustomButton (átomo)
/// - StatusMessage (átomo)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Estado de carga del login
  bool _isLoading = false;

  /// Mensaje de error actual (null si no hay error)
  String? _errorMessage;

  /// Mensaje de éxito (normalmente viene del registro)
  String? _successMessage;

    /// Controlador para autenticación biométrica
  final LocalAuthentication auth = LocalAuthentication();

  /// Estado de biometría habilitada
  bool _biometricEnabled = false;


  @override
  void initState() {
    super.initState();
    // Verificar si hay un mensaje de éxito desde el registro
    _checkForSuccessMessage();
    _checkBiometricStatus(); // Verificar el estado de la biometría
  }

    Future<void> _checkBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('biometric_login_enabled') ?? false;
   if (mounted) {
      setState(() {
        _biometricEnabled = isEnabled;
      });
    }

  } 

    /// Maneja la autenticación biométrica
   Future<void> _authenticateWithBiometrics() async {
  print('LoginPage: Iniciando autenticación biométrica...');
  
  // Usar el AuthProvider que ya tiene toda la lógica
  final authProvider = context.read<AuthProvider>();
  
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
     final hasCredentials = await authProvider.hasSavedCredentials();
    if (!hasCredentials) {
      setState(() {
        _errorMessage = 'No hay credenciales guardadas. Inicia sesión manualmente.';
        _isLoading = false;
      });
      return;
    }

    final success = await authProvider.authenticateWithBiometrics();

    if (success && mounted) {
      print('LoginPage: Autenticación biométrica exitosa, navegando a home...');
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      print('LoginPage: Autenticación biométrica fallida.');
      setState(() {
        _errorMessage = authProvider.error ?? 'Error en la autenticación biométrica';
      });
    }
  } catch (e) {
    print('LoginPage: Error durante autenticación biométrica: $e');
    if (mounted) {
      setState(() {
        _errorMessage = 'Error en la autenticación biométrica';
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

    /// Muestra el diálogo para activar la biometría después del login exitoso
  Future<void> _showBiometricActivationDialog() async {
  // Verificar si el dispositivo soporta biometría
  final canCheckBiometrics = await auth.canCheckBiometrics;
  
  // Solo mostrar el diálogo si:
  // 1. El dispositivo soporta biometría
  // 2. La biometría no está habilitada aún
  // 3. El widget está montado
  if (canCheckBiometrics && !_biometricEnabled && mounted) {
    print('LoginPage: Mostrando diálogo de activación biométrica...');
    
    final activate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Activar Ingreso Biométrico'),
        content: const Text(
            '¿Deseas usar tu huella o rostro para ingresar la próxima vez?'),
        actions: [
          TextButton(
            child: const Text('No, gracias'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Sí, activar'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    // Verificar mounted después del diálogo
    if (activate == true && mounted) {
      print('LoginPage: Usuario activó biometría, guardando configuración...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_login_enabled', true);
      
      setState(() {
        _biometricEnabled = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autenticación biométrica activada')),
      );
    }
  } else {
    print('LoginPage: No se muestra diálogo - canCheckBiometrics: $canCheckBiometrics, _biometricEnabled: $_biometricEnabled');
  }
}

  /// Verifica si hay un mensaje de éxito pasado desde la navegación
  void _checkForSuccessMessage() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificar mounted antes de setState
      if (mounted) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String) {
          setState(() {
            _successMessage = args;
          });
        }
      }
    });
  }

  /// Navega a la página de registro y maneja el resultado
  void _navigateToRegister() async {
    final result = await Navigator.pushNamed(context, '/register');

    // Si regresa un string desde el registro, mostrarlo como mensaje de éxito
    // Verificar mounted después de la navegación
    if (result is String && mounted) {
      setState(() {
        _successMessage = result;
      });
    }
  }

  /// Maneja el proceso de login
  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Usar el AuthProvider para manejar el login
      final authProvider = context.read<AuthProvider>();
      
      // ¡IMPORTANTE! Pasar saveBiometrics: true para que guarde las credenciales
      final success = await authProvider.login(email, password, saveBiometrics: true);

      if (success && mounted) {
        // Login exitoso - mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login exitoso'))
        );

        // Preguntar si quiere activar biometría
        await _showBiometricActivationDialog();

        // Navegar a la página principal
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Login fallido - usar el error específico del AuthProvider
        if (mounted) {
          setState(() {
            String errorMsg = authProvider.error ?? 'Usuario o contraseña incorrectos. Verifica tus datos.';
            
            // Si el mensaje contiene información sobre credenciales incorrectas
            if (errorMsg.toLowerCase().contains('credenciales') ||
                errorMsg.toLowerCase().contains('unauthorized') ||
                errorMsg.toLowerCase().contains('invalid') ||
                errorMsg.toLowerCase().contains('wrong') ||
                errorMsg.toLowerCase().contains('incorrectas') ||
                errorMsg.toLowerCase().contains('authentication') ||
                errorMsg.toLowerCase().contains('login')) {
              _errorMessage = 'Usuario o contraseña incorrectos. Verifica tus datos.';
            } else {
              // Para cualquier otro error, usar el mensaje original del backend
              _errorMessage = errorMsg;
            }
          });
        }
      }
    } catch (e) {
      // Error durante el login
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión. Intenta nuevamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Limpia el mensaje de éxito
  void _clearSuccessMessage() {
     if (mounted) {
      setState(() {
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      // AppBar con el logo de la empresa
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        title: const AppLogo.navbar(),
      ),

      body: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo principal de la aplicación
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: AppLogo.login(),
                ),
              ),

              // Título y subtítulo de bienvenida
              Text(
                'Bienvenido',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para continuar',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Mensaje de registro exitoso (si existe)
              if (_successMessage != null)
                StatusMessage(
                  message: _successMessage!,
                  type: MessageType.success,
                  showCloseButton: true,
                  onClose: _clearSuccessMessage,
                ),

              // Formulario de login
              LoginForm(
                onLogin: _handleLogin,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
              ),

              const SizedBox(height: 16),

              // Botón para ir al registro
              CustomButton(
                text: '¿No tienes cuenta? Regístrate aquí',
                onPressed: _navigateToRegister,
                type: ButtonType.secondary,
                fullWidth: true,
              ),
                 // Botón de autenticación biométrica
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'Continuar el ingreso con',
                  style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _authenticateWithBiometrics,
                  child: Column(
                    children: <Widget>[
                      Image.asset('assets/icons/face_id.png', height: 30, color: Colors.orange,),
                      const SizedBox(height: 8),
                      const Text(
                        'Face ID',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
    @override
  void dispose() {
    // Limpiar cualquier listener o timer aquí si los hubiera
    super.dispose();
  }
}


