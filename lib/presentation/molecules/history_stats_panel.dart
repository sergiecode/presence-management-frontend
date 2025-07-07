import 'package:flutter/material.dart';

/// **Panel de Estadísticas de Historial**
///
/// Molécula que muestra estadísticas resumidas del historial de registros,
/// incluyendo el total de registros y el tiempo total acumulado.
///
/// [totalRecords] - Número total de registros
/// [totalTime] - Tiempo total formateado como string (ej: "8h 30m")
class HistoryStatsPanel extends StatelessWidget {
  /// Número total de registros en el historial filtrado
  final int totalRecords;

  /// Tiempo total acumulado formateado como string
  final String totalTime;

  const HistoryStatsPanel({
    super.key,
    required this.totalRecords,
    required this.totalTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFe67d21).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Total de registros
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total de registros',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalRecords',
                  style: const TextStyle(
                    color: Color(0xFFe67d21),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Separador
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          // Tiempo total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Tiempo total',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalTime,
                  style: const TextStyle(
                    color: Color(0xFFe67d21),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
