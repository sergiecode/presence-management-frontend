import 'package:flutter/material.dart';

/// **Chip de Tipo de Ausencia**
///
/// Molécula que representa un chip visual para mostrar un tipo de ausencia
/// con su ícono, etiqueta y color correspondiente.
///
/// [label] - Texto que se muestra en el chip
/// [icon] - Ícono que se muestra junto al texto
/// [color] - Color principal del chip
class AbsenceTypeChip extends StatelessWidget {
  /// Texto descriptivo del tipo de ausencia
  final String label;

  /// Ícono que representa el tipo de ausencia
  final IconData icon;

  /// Color principal del chip
  final Color color;

  const AbsenceTypeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
