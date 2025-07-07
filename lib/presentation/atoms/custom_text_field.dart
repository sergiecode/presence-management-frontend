import 'package:flutter/material.dart';

/// **ÁTOMO: Campo de texto personalizado**
///
/// Campo de entrada de texto reutilizable que mantiene la consistencia
/// visual en toda la aplicación.
///
/// **Características:**
/// - Estilos predefinidos consistentes con el tema de la app
/// - Soporte para diferentes tipos de teclado (email, texto, números)
/// - Iconos de prefijo y sufijo opcionales
/// - Manejo de texto oculto (contraseñas)
/// - Validación integrada
/// - Soporte para campos de solo lectura
class CustomTextField extends StatelessWidget {
  /// Controlador del campo de texto
  final TextEditingController controller;

  /// Texto de la etiqueta
  final String labelText;

  /// Icono que aparece al inicio del campo
  final IconData? prefixIcon;

  /// Icono que aparece al final del campo
  final Widget? suffixIcon;

  /// Si el texto debe estar oculto (para contraseñas)
  final bool obscureText;

  /// Tipo de teclado a mostrar
  final TextInputType keyboardType;

  /// Función de validación opcional
  final String? Function(String?)? validator;

  /// Si el campo está habilitado
  final bool enabled;

  /// Si el campo es de solo lectura
  final bool readOnly;

  /// Función que se ejecuta al tocar el campo
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
    );
  }
}
