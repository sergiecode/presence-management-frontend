import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../atoms/atoms.dart';

/// **MOLÉCULA: Formulario de Registro**
///
/// Componente que combina múltiples átomos para crear un formulario
/// de registro completo y funcional.
///
/// **Características:**
/// - Campos para todos los datos requeridos del usuario
/// - Validación robusta de entrada de datos
/// - Confirmación de contraseña
/// - Manejo de estados de carga y error
/// - Integración con el sistema de registro
///
/// **Átomos utilizados:**
/// - CustomTextField (para todos los campos)
/// - CustomButton (para el botón de registro)
/// - StatusMessage (para mostrar errores)
class RegisterForm extends StatefulWidget {
  /// Función callback que se ejecuta cuando se intenta registrar un usuario
  /// Recibe todos los datos del usuario como parámetros
  final Future<void> Function({
    required String email,
    required String name,
    required String surname,
    required String phone,
    required String password,
  })
  onRegister;

  /// Si el formulario está en estado de carga
  final bool isLoading;

  /// Mensaje de error a mostrar (null si no hay error)
  final String? errorMessage;

  const RegisterForm({
    super.key,
    required this.onRegister,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  /// Clave global para el formulario (para validación)
  final _formKey = GlobalKey<FormState>();

  /// Controladores para todos los campos del formulario
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// Controla si la contraseña está visible o no
  bool _obscurePassword = true;

  /// Controla si la confirmación de contraseña está visible o no
  bool _obscureConfirmPassword = true;

  /// Alterna la visibilidad de la contraseña
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  /// Alterna la visibilidad de la confirmación de contraseña
  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  @override
  void dispose() {
    // Limpiar todos los controladores al destruir el widget
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Maneja el submit del formulario
  void _handleSubmit() {
    // Validar el formulario
    if (_formKey.currentState?.validate() ?? false) {
      // Verificar que las contraseñas coincidan
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')),
        );
        return;
      }

      // Si todo está bien, ejecutar la función de registro
      widget.onRegister(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  /// Validador para el campo de nombre
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  /// Validador para el campo de apellido
  String? _validateSurname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El apellido es requerido';
    }
    if (value.trim().length < 2) {
      return 'El apellido debe tener al menos 2 caracteres';
    }
    return null;
  }

  /// Validador para el campo de email
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    // Regex más robusto para validar formato de email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  /// Validador para el campo de teléfono
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    
    // Verificar que solo contenga números, espacios, paréntesis, guiones y el signo +
    if (!RegExp(r'^[0-9+\-\s\(\)]+$').hasMatch(value.trim())) {
      return 'El teléfono solo puede contener números, +, -, espacios, ( y )';
    }
    
    // Contar solo los dígitos para validar longitud mínima
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 8) {
      return 'El teléfono debe tener al menos 8 dígitos';
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

  /// Validador para el campo de confirmación de contraseña
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    // No verificamos aquí si coinciden porque se hace en el submit
    // para evitar validación prematura
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de nombre
          CustomTextField(
            controller: _nameController,
            labelText: 'Nombre *',
            prefixIcon: Icons.person,
            validator: _validateName,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),

          // Campo de apellido
          CustomTextField(
            controller: _surnameController,
            labelText: 'Apellido *',
            prefixIcon: Icons.person_outline,
            validator: _validateSurname,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),

          // Campo de email
          CustomTextField(
            controller: _emailController,
            labelText: 'Email *',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),

          // Campo de teléfono
          CustomTextField(
            controller: _phoneController,
            labelText: 'Teléfono *',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            enabled: !widget.isLoading,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de contraseña
          CustomTextField(
            controller: _passwordController,
            labelText: 'Contraseña *',
            prefixIcon: Icons.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFFE67D21), // Color naranja corporativo
                size: 20,
              ),
              onPressed: _togglePasswordVisibility,
              splashRadius: 20, // Radio del efecto splash más pequeño
            ),
            validator: _validatePassword,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),

          // Campo de confirmación de contraseña
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirmar contraseña *',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFFE67D21), // Color naranja corporativo
                size: 20,
              ),
              onPressed: _toggleConfirmPasswordVisibility,
              splashRadius: 20, // Radio del efecto splash más pequeño
            ),
            validator: _validateConfirmPassword,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 24),

          // Mensaje de error (si existe)
          if (widget.errorMessage != null)
            StatusMessage(
              message: widget.errorMessage!,
              type: MessageType.error,
            ),

          // Botón de registro
          CustomButton(
            text: 'Registrarse',
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
