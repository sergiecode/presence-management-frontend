import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones de la nueva estructura
import '../../data/providers/auth_provider.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';
import '../../core/utils/debug_logger.dart';

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
/// - Panel de debug para diagnóstico de problemas
///
/// **Componentes utilizados:**
/// - AppLogo (átomo)
/// - LoginForm (molécula)
/// - CustomButton (átomo)
/// - StatusMessage (átomo)
/// - DebugPanel (átomo)
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

  /// Mostrar/ocultar panel de debug
  bool _showDebugPanel = false;
  
  /// Logger de debug
  final DebugLogger _logger = DebugLogger();

  @override
  void initState() {
    super.initState();
    // Verificar si hay un mensaje de éxito desde el registro
    _checkForSuccessMessage();
    _checkBiometricStatus(); // Verificar el estado de la biometría
    
    // Agregar log inicial
    _logger.info('LoginPage inicializada');
  }

  Future<void> _checkBiometricStatus() async {
    _logger.info('Verificando estado de biometría...');
    
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('biometric_login_enabled') ?? false;
    
    _logger.info('Biometría habilitada: $isEnabled');
    
    if (mounted) {
      setState(() {
        _biometricEnabled = isEnabled;
      });
    }
  }

  /// Maneja la autenticación biométrica
  Future<void> _authenticateWithBiometrics() async {
    _logger.info('Iniciando autenticación biométrica...');
    
    // Usar el AuthProvider que ya tiene toda la lógica
    final authProvider = context.read<AuthProvider>();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _logger.info('Verificando credenciales guardadas...');
      final hasCredentials = await authProvider.hasSavedCredentials();
      
      if (!hasCredentials) {
        _logger.warning('No hay credenciales guardadas para biometría');
        setState(() {
          _errorMessage = 'No hay credenciales guardadas. Inicia sesión manualmente.';
          _isLoading = false;
        });
        return;
      }

      _logger.info('Credenciales encontradas, procediendo con biometría...');
      final success = await authProvider.authenticateWithBiometrics();

      if (success && mounted) {
        _logger.info('Autenticación biométrica exitosa, navegando a home...');
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        _logger.error('Autenticación biométrica fallida: ${authProvider.error}');
        setState(() {
          _errorMessage = authProvider.error ?? 'Error en la autenticación biométrica';
        });
      }
    } catch (e) {
      _logger.error('Error durante autenticación biométrica', error: e);
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
    _logger.info('Verificando soporte de biometría...');
    
    // Verificar si el dispositivo soporta biometría
    final canCheckBiometrics = await auth.canCheckBiometrics;
    _logger.info('Dispositivo soporta biometría: $canCheckBiometrics');
    
    // Solo mostrar el diálogo si:
    // 1. El dispositivo soporta biometría
    // 2. La biometría no está habilitada aún
    // 3. El widget está montado
    if (canCheckBiometrics && !_biometricEnabled && mounted) {
      _logger.info('Mostrando diálogo de activación biométrica...');
      
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
        _logger.info('Usuario activó biometría, guardando configuración...');
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
      _logger.info('No se muestra diálogo - canCheckBiometrics: $canCheckBiometrics, _biometricEnabled: $_biometricEnabled');
    }
  }

  /// Verifica si hay un mensaje de éxito pasado desde la navegación
  void _checkForSuccessMessage() {
    _logger.info('Verificando mensaje de éxito...');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificar mounted antes de setState
      if (mounted) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String) {
          _logger.info('Mensaje de éxito recibido: $args');
          setState(() {
            _successMessage = args;
          });
        } else {
          _logger.info('No hay mensaje de éxito en los argumentos');
        }
      }
    });
  }

  /// Navega a la página de registro y maneja el resultado
  void _navigateToRegister() async {
    _logger.info('Navegando a página de registro...');
    
    final result = await Navigator.pushNamed(context, '/register');

    // Si regresa un string desde el registro, mostrarlo como mensaje de éxito
    // Verificar mounted después de la navegación
    if (result is String && mounted) {
      _logger.info('Resultado del registro: $result');
      setState(() {
        _successMessage = result;
      });
    } else {
      _logger.info('No hay resultado del registro');
    }
  }

  /// Maneja el proceso de login
  Future<void> _handleLogin(String email, String password) async {
    _logger.info('Iniciando proceso de login para: $email');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Usar el AuthProvider para manejar el login
      final authProvider = context.read<AuthProvider>();
      _logger.info('AuthProvider obtenido, procediendo con login...');
      
      // ¡IMPORTANTE! Pasar saveBiometrics: true para que guarde las credenciales
      final success = await authProvider.login(email, password, saveBiometrics: true);

      if (success && mounted) {
        _logger.info('Login exitoso, mostrando mensaje de éxito...');
        // Login exitoso - mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login exitoso'))
        );

        // Preguntar si quiere activar biometría
        await _showBiometricActivationDialog();

        // Navegar a la página principal
        if (mounted) {
          _logger.info('Navegando a página principal...');
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Login fallido - usar el error específico del AuthProvider
        final errorMsg = authProvider.error ?? 'Usuario o contraseña incorrectos. Verifica tus datos.';
        _logger.error('Login fallido: $errorMsg');
        
        if (mounted) {
          setState(() {
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
      _logger.error('Error durante el login', error: e);
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
    _logger.info('Limpiando mensaje de éxito');
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
        actions: [
          // Botón para mostrar/ocultar panel de debug
          IconButton(
            icon: Icon(_showDebugPanel ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _showDebugPanel = !_showDebugPanel;
              });
              _logger.info(_showDebugPanel ? 'Panel de debug activado' : 'Panel de debug desactivado');
            },
            tooltip: 'Panel de Debug',
          ),
        ],
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
              
              // Panel de debug
              if (_showDebugPanel) ...[
                const SizedBox(height: 30),
                DebugPanel(
                  title: '🔧 DEBUG LOGS - LOGIN',
                  height: 250,
                  initiallyExpanded: true,
                ),
              ],
              
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


