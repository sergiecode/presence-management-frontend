import 'package:flutter/material.dart';

/// **Tarjeta de Ausencia**
///
/// Molécula que representa una tarjeta individual de ausencia en el historial.
/// Muestra el tipo, fecha, motivo y estado de adjuntos de una ausencia.
///
/// [absence] - Datos de la ausencia
/// [absenceTypes] - Lista de tipos disponibles para obtener iconos y colores
class AbsenceCard extends StatelessWidget {
  /// Datos de la ausencia individual
  final Map<String, dynamic> absence;

  /// Lista de tipos de ausencia disponibles con sus propiedades visuales
  final List<Map<String, dynamic>> absenceTypes;

  const AbsenceCard({
    super.key,
    required this.absence,
    required this.absenceTypes,
  });

  /// Formatea una fecha a formato legible
  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Obtiene el ícono correspondiente al tipo de ausencia
  IconData _getIconForType(String type) {
    final typeInfo = absenceTypes.firstWhere(
      (t) => t['type'] == type,
      orElse: () => absenceTypes[0],
    );
    return typeInfo['icon'];
  }

  /// Obtiene el color correspondiente al tipo de ausencia
  Color _getColorForType(String type) {
    final typeInfo = absenceTypes.firstWhere(
      (t) => t['type'] == type,
      orElse: () => absenceTypes[0],
    );
    return typeInfo['color'];
  }

  /// Obtiene la etiqueta correspondiente al tipo de ausencia
  String _getLabelForType(String type) {
    final typeInfo = absenceTypes.firstWhere(
      (t) => t['type'] == type,
      orElse: () => absenceTypes[0],
    );
    return typeInfo['label'];
  }

  /// Obtiene el color para el status de la ausencia
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene la etiqueta para el status de la ausencia
  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'Aprobado';
      case 'pending':
        return 'Pendiente';
      case 'rejected':
        return 'Rechazado';
      default:
        return 'Sin estado';
    }
  }

  /// Obtiene el ícono para el status de la ausencia
  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (absence['reason'] != null) _buildReason(),
          ],
        ),
      ),
    );
  }

  /// Construye el encabezado de la tarjeta con tipo, fecha y archivo adjunto
  Widget _buildHeader() {
    final date = DateTime.parse(absence['date']);

    return Row(
      children: [
        // Ícono del tipo de ausencia
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getColorForType(absence['type']).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForType(absence['type']),
            color: _getColorForType(absence['type']),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Información principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getLabelForType(absence['type']),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                _formatDate(date),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        // Indicador de archivo adjunto y status
        Column(
          children: [
            if (absence['file_url'] != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file, size: 12, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Archivo',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            // Indicador de status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(absence['status']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(absence['status']),
                    size: 12,
                    color: _getStatusColor(absence['status']),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusLabel(absence['status']),
                    style: TextStyle(
                      color: _getStatusColor(absence['status']),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construye la sección del motivo de la ausencia
  Widget _buildReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motivo:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          absence['reason'],
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }
}
