import 'package:flutter/material.dart';

/// **ÁTOMO: Widget de mensaje de estado**
///
/// Componente reutilizable para mostrar mensajes de éxito, error,
/// información o advertencia de manera consistente.
///
/// **Características:**
/// - Diferentes tipos de mensaje con colores apropiados
/// - Icono automático según el tipo de mensaje
/// - Botón de cierre opcional
/// - Diseño consistente con el tema de la app
class StatusMessage extends StatelessWidget {
  /// Texto del mensaje a mostrar
  final String message;

  /// Tipo de mensaje (determina colores e icono)
  final MessageType type;

  /// Si debe mostrar botón de cierre
  final bool showCloseButton;

  /// Función que se ejecuta al presionar el botón de cierre
  final VoidCallback? onClose;

  const StatusMessage({
    super.key,
    required this.message,
    required this.type,
    this.showCloseButton = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Configuración visual según el tipo de mensaje
    final config = _getMessageConfig(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        border: Border.all(color: config.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icono del tipo de mensaje
          Icon(config.icon, color: config.iconColor),
          const SizedBox(width: 8),

          // Texto del mensaje
          Expanded(
            child: Text(message, style: TextStyle(color: config.textColor)),
          ),

          // Botón de cierre opcional
          if (showCloseButton)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  /// Obtiene la configuración visual para cada tipo de mensaje
  _MessageConfig _getMessageConfig(MessageType type) {
    switch (type) {
      case MessageType.success:
        return _MessageConfig(
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          iconColor: Colors.green.shade600,
          textColor: Colors.green.shade700,
          icon: Icons.check_circle,
        );
      case MessageType.error:
        return _MessageConfig(
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
          iconColor: Colors.red.shade600,
          textColor: Colors.red.shade700,
          icon: Icons.error,
        );
      case MessageType.warning:
        return _MessageConfig(
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          iconColor: Colors.orange.shade600,
          textColor: Colors.orange.shade700,
          icon: Icons.warning,
        );
      case MessageType.info:
        return _MessageConfig(
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          iconColor: Colors.blue.shade600,
          textColor: Colors.blue.shade700,
          icon: Icons.info,
        );
    }
  }
}

/// **Enumeración: Tipos de mensaje disponibles**
enum MessageType {
  /// Mensaje de éxito (verde)
  success,

  /// Mensaje de error (rojo)
  error,

  /// Mensaje de advertencia (naranja)
  warning,

  /// Mensaje informativo (azul)
  info,
}

/// **Clase interna: Configuración visual de mensajes**
///
/// Almacena la configuración de colores e iconos para cada tipo de mensaje
class _MessageConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  const _MessageConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}
