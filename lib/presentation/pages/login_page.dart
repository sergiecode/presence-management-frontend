import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones de la nueva estructura
import '../../data/providers/auth_provider.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';

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

  @override
  void initState() {
    super.initState();
    // Verificar si hay un mensaje de éxito desde el registro
    _checkForSuccessMessage();
  }

  /// Verifica si hay un mensaje de éxito pasado desde la navegación
  void _checkForSuccessMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          _successMessage = args;
        });
      }
    });
  }

  /// Navega a la página de registro y maneja el resultado
  void _navigateToRegister() async {
    final result = await Navigator.pushNamed(context, '/register');

    // Si regresa un string desde el registro, mostrarlo como mensaje de éxito
    if (result is String) {
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
      final success = await context.read<AuthProvider>().login(email, password);

      if (success && mounted) {
        // Login exitoso - mostrar mensaje de éxito
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login exitoso')));

        // Navegar a la página principal
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Login fallido
        setState(() {
          _errorMessage = 'Email o contraseña incorrectos';
        });
      }
    } catch (e) {
      // Error durante el login
      setState(() {
        _errorMessage = 'Error de conexión. Intenta nuevamente.';
      });
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
    setState(() {
      _successMessage = null;
    });
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
            ],
          ),
        ),
      ),
    );
  }
}
