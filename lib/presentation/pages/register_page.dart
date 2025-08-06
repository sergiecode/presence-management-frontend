import 'package:flutter/material.dart';

// Importaciones de la nueva estructura
import '../../data/services/auth_service.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';

/// **PÁGINA: Registro de Usuario**
///
/// Página para que nuevos usuarios se registren en la aplicación.
/// Implementa los principios de Atomic Design usando átomos y moléculas.
///
/// **Funcionalidades:**
/// - Formulario completo de registro con validación
/// - Verificación de confirmación de contraseña
/// - Manejo de errores y estados de carga
/// - Integración con el sistema de autenticación
/// - Navegación de regreso al login con mensaje de éxito
/// - UI responsive y accesible
///
/// **Componentes utilizados:**
/// - AppLogo (átomo)
/// - RegisterForm (molécula)
/// - CustomButton (átomo)
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  /// Estado de carga del registro
  bool _isLoading = false;

  /// Mensaje de error actual (null si no hay error)
  String? _errorMessage;

  /// Maneja el proceso de registro
  Future<void> _handleRegister({
    required String email,
    required String name,
    required String surname,
    required String phone,
    required String password,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Intentar registrar al usuario a través del servicio de autenticación
      final success = await AuthService.register(
        email: email,
        name: name,
        surname: surname,
        phone: phone,
        password: password,
      );

      if (success && mounted) {
        // Registro exitoso - regresar al login con mensaje de éxito
        Navigator.pop(
          context,
          'Registro exitoso. Pendiente de revisión con RH para activar el login.',
        );
      } else {
        // Registro fallido - esto no debería llegar aquí si el servicio maneja las excepciones correctamente
        setState(() {
          _errorMessage = 'Error en el registro. Inténtalo nuevamente.';
        });
      }
    } catch (e) {
      // Manejo específico de errores del backend
      if (mounted) {
        setState(() {
          String errorMsg = e.toString();
          
          // Eliminar el prefijo "Exception: " si existe
          if (errorMsg.startsWith('Exception: ')) {
            errorMsg = errorMsg.substring(11);
          }
          
          // Verificar si es un error específico de email duplicado
          if (errorMsg.toLowerCase().contains('email') && 
              (errorMsg.toLowerCase().contains('existe') || 
               errorMsg.toLowerCase().contains('registrado') ||
               errorMsg.toLowerCase().contains('ya existe') ||
               errorMsg.toLowerCase().contains('already exists'))) {
            _errorMessage = 'Este email ya está registrado. Por favor usa otro email.';
          } 
          // Verificar errores de conexión
          else if (errorMsg.contains('SocketException') || 
                   errorMsg.contains('TimeoutException') ||
                   errorMsg.contains('Error de conexión') ||
                   errorMsg.contains('Error de red')) {
            _errorMessage = 'Error de conexión. Verifica tu internet e intenta nuevamente.';
          }
          // Otros errores del backend
          else if (errorMsg.isNotEmpty) {
            _errorMessage = errorMsg;
          } 
          // Error genérico
          else {
            _errorMessage = 'Error en el registro. Inténtalo nuevamente.';
          }
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

  /// Navega de regreso a la página de login
  void _navigateToLogin() {
    Navigator.pop(context);
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
              // Logo principal de la aplicación (más pequeño que en login)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: AppLogo(width: 100, height: 100),
                ),
              ),

              // Título de la página
              Text(
                'Crear nueva cuenta',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Formulario de registro
              RegisterForm(
                onRegister: _handleRegister,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
              ),

              const SizedBox(height: 16),

              // Botón para regresar al login
              CustomButton(
                text: '¿Ya tienes cuenta? Inicia sesión',
                onPressed: _navigateToLogin,
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
