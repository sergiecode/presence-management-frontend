import 'package:flutter/material.dart';

/// **Tarjeta de Entrada/Salida del Historial**
///
/// Molécula que representa una tarjeta individual de registro de entrada/salida
/// en el historial de asistencia.
///
/// [entry] - Datos del registro que incluye check_in_time, check_out_time, etc.
class HistoryEntryCard extends StatelessWidget {
  /// Datos del registro de entrada/salida
  final Map<String, dynamic> entry;

  const HistoryEntryCard({super.key, required this.entry});

  /// Formatea una fecha/hora ISO string a formato HH:mm
  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Calcula la duración entre entrada y salida
  String _calculateDuration(String checkInStr, String? checkOutStr) {
    if (checkOutStr == null) return 'En curso';

    final checkIn = DateTime.parse(checkInStr);
    final checkOut = DateTime.parse(checkOutStr);
    final duration = checkOut.difference(checkIn);

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Indicador de estado
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: entry['check_out_time'] != null
                  ? Colors.green
                  : const Color(0xFFe67d21),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          // Información de entrada/salida
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hora de entrada
                Row(
                  children: [
                    const Icon(Icons.login, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Entrada: ${_formatDateTime(entry['check_in_time'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Hora de salida (si existe)
                if (entry['check_out_time'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.logout, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Salida: ${_formatDateTime(entry['check_out_time'])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                // Ubicación (si existe)
                if (entry['location'] != null &&
                    entry['location'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry['location'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Duración
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: entry['check_out_time'] != null
                  ? Colors.green.withOpacity(0.1)
                  : const Color(0xFFe67d21).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _calculateDuration(
                entry['check_in_time'],
                entry['check_out_time'],
              ),
              style: TextStyle(
                color: entry['check_out_time'] != null
                    ? Colors.green
                    : const Color(0xFFe67d21),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
