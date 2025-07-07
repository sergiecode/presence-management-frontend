import 'package:flutter/material.dart';
import '../atoms/atoms.dart';

/// **MOLÉCULA: Formulario de Login**
///
/// Componente que combina múltiples átomos para crear un formulario
/// de inicio de sesión completo y funcional.
///
/// **Características:**
/// - Campos de email y contraseña integrados
/// - Validación de entrada
/// - Manejo de estados de carga y error
/// - Integración con el sistema de autenticación
///
/// **Átomos utilizados:**
/// - CustomTextField (para email y contraseña)
/// - CustomButton (para el botón de login)
/// - StatusMessage (para mostrar errores)
class LoginForm extends StatefulWidget {
  /// Función callback que se ejecuta cuando se intenta hacer login
  /// Recibe email y contraseña como parámetros
  final Future<void> Function(String email, String password) onLogin;

  /// Si el formulario está en estado de carga
  final bool isLoading;

  /// Mensaje de error a mostrar (null si no hay error)
  final String? errorMessage;

  const LoginForm({
    super.key,
    required this.onLogin,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  /// Clave global para el formulario (para validación)
  final _formKey = GlobalKey<FormState>();

  /// Controlador para el campo de email
  final _emailController = TextEditingController();

  /// Controlador para el campo de contraseña
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Limpiar controladores al destruir el widget
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Maneja el submit del formulario
  void _handleSubmit() {
    // Validar el formulario
    if (_formKey.currentState?.validate() ?? false) {
      // Si la validación pasa, ejecutar la función de login
      widget.onLogin(_emailController.text, _passwordController.text);
    }
  }

  /// Validador para el campo de email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    // Regex básico para validar formato de email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  /// Validador para el campo de contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de email
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),

          // Campo de contraseña
          CustomTextField(
            controller: _passwordController,
            labelText: 'Contraseña',
            prefixIcon: Icons.lock,
            obscureText: true,
            validator: _validatePassword,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 24),

          // Mensaje de error (si existe)
          if (widget.errorMessage != null)
            StatusMessage(
              message: widget.errorMessage!,
              type: MessageType.error,
            ),

          // Botón de login
          CustomButton(
            text: 'Iniciar Sesión',
            onPressed: widget.isLoading ? null : _handleSubmit,
            isLoading: widget.isLoading,
            type: ButtonType.primary,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
