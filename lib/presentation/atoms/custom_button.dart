import 'package:flutter/material.dart';

/// **ÁTOMO: Botón principal personalizado**
///
/// Botón reutilizable que mantiene la consistencia visual y de comportamiento
/// en toda la aplicación.
///
/// **Características:**
/// - Estilos predefinidos consistentes con el tema corporativo
/// - Estado de carga integrado con indicador circular
/// - Configuración flexible de texto y acción
/// - Soporte para deshabilitación
class CustomButton extends StatelessWidget {
  /// Texto que se muestra en el botón
  final String text;

  /// Función que se ejecuta al presionar el botón
  final VoidCallback? onPressed;

  /// Si el botón está en estado de carga
  final bool isLoading;

  /// Tipo de botón (primario, secundario, etc.)
  final ButtonType type;

  /// Ancho completo del botón
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar el estilo del botón basado en el tipo
    Widget button;

    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _buildButtonContent(),
        );
        break;
      case ButtonType.secondary:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildButtonContent(),
        );
        break;
    }

    // Si fullWidth es true, expandir el botón al ancho completo
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  /// Construye el contenido del botón (texto o loading indicator)
  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Text(text, style: const TextStyle(fontSize: 16));
  }
}

/// **Enumeración: Tipos de botón disponibles**
enum ButtonType {
  /// Botón principal (ElevatedButton con colores corporativos)
  primary,

  /// Botón secundario (TextButton)
  secondary,
}
