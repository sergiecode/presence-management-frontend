import 'package:flutter/material.dart';
import '../molecules/molecules.dart';

/// **Lista de Historial de Asistencia**
///
/// Organismo que maneja la visualización completa del historial de asistencia,
/// incluyendo filtros, estadísticas y la lista de registros agrupados por fecha.
///
/// [checkInHistory] - Lista completa de registros de entrada/salida
/// [selectedFilter] - Filtro actualmente seleccionado
/// [filterOptions] - Opciones disponibles para filtrar
/// [onFilterChanged] - Callback cuando cambia el filtro
/// [onRefresh] - Callback para refrescar los datos
class HistoryList extends StatelessWidget {
  /// Lista completa de registros de check-in/check-out
  final List<Map<String, dynamic>> checkInHistory;

  /// Filtro actualmente seleccionado (ej: "Última semana")
  final String selectedFilter;

  /// Lista de opciones disponibles para el filtro
  final List<String> filterOptions;

  /// Callback que se ejecuta cuando cambia el filtro
  final ValueChanged<String> onFilterChanged;

  /// Callback que se ejecuta al hacer pull-to-refresh
  final Future<void> Function() onRefresh;

  const HistoryList({
    super.key,
    required this.checkInHistory,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterChanged,
    required this.onRefresh,
  });

  /// Filtra el historial según el filtro seleccionado
  List<Map<String, dynamic>> _getFilteredHistory() {
    final now = DateTime.now();

    switch (selectedFilter) {
      case 'Última semana':
        final weekAgo = now.subtract(const Duration(days: 7));
        return checkInHistory.where((entry) {
          final entryDate = DateTime.parse(entry['check_in_time']);
          return entryDate.isAfter(weekAgo);
        }).toList();
      case 'Último mes':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return checkInHistory.where((entry) {
          final entryDate = DateTime.parse(entry['check_in_time']);
          return entryDate.isAfter(monthAgo);
        }).toList();
      case 'Este año':
        final yearStart = DateTime(now.year, 1, 1);
        return checkInHistory.where((entry) {
          final entryDate = DateTime.parse(entry['check_in_time']);
          return entryDate.isAfter(yearStart);
        }).toList();
      default:
        return checkInHistory;
    }
  }

  /// Agrupa el historial por fecha
  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> history,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final entry in history) {
      final date = DateTime.parse(entry['check_in_time']);
      final dateKey =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(entry);
    }

    return grouped;
  }

  /// Calcula el tiempo total acumulado
  String _getTotalTime(List<Map<String, dynamic>> history) {
    Duration totalDuration = Duration.zero;

    for (final entry in history) {
      if (entry['check_out_time'] != null) {
        final checkIn = DateTime.parse(entry['check_in_time']);
        final checkOut = DateTime.parse(entry['check_out_time']);
        totalDuration += checkOut.difference(checkIn);
      }
    }

    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _getFilteredHistory();
    final groupedHistory = _groupByDate(filteredHistory);
    final totalTime = _getTotalTime(filteredHistory);

    return RefreshIndicator(
      color: const Color(0xFFe67d21),
      onRefresh: onRefresh,
      child: Column(
        children: [
          // Panel de filtros y estadísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Filtro
                HistoryFilter(
                  selectedFilter: selectedFilter,
                  filterOptions: filterOptions,
                  onFilterChanged: onFilterChanged,
                ),
                const SizedBox(height: 16),
                // Panel de estadísticas
                HistoryStatsPanel(
                  totalRecords: filteredHistory.length,
                  totalTime: totalTime,
                ),
              ],
            ),
          ),
          // Lista de historial
          Expanded(
            child: filteredHistory.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(groupedHistory),
          ),
        ],
      ),
    );
  }

  /// Construye el estado vacío cuando no hay registros
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay registros para mostrar',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Construye la lista de historial agrupada por fecha
  Widget _buildHistoryList(
    Map<String, List<Map<String, dynamic>>> groupedHistory,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedHistory.keys.length,
      itemBuilder: (context, index) {
        final date = groupedHistory.keys.elementAt(index);
        final dayEntries = groupedHistory[date]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shadowColor: Colors.grey.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de fecha
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFe67d21).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFe67d21),
                  ),
                ),
              ),
              // Entradas del día usando HistoryEntryCard
              ...dayEntries.map((entry) => HistoryEntryCard(entry: entry)),
            ],
          ),
        );
      },
    );
  }
}
