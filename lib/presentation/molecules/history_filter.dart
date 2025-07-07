import 'package:flutter/material.dart';

/// **Filtro de Historial**
///
/// Molécula que proporciona un dropdown para filtrar registros de historial
/// por período de tiempo (última semana, último mes, etc.).
///
/// [selectedFilter] - El valor actualmente seleccionado en el filtro
/// [filterOptions] - Lista de opciones disponibles para filtrar
/// [onFilterChanged] - Callback que se ejecuta cuando se cambia el filtro
class HistoryFilter extends StatelessWidget {
  /// El valor del filtro actualmente seleccionado
  final String selectedFilter;

  /// Lista de opciones disponibles para el filtro
  final List<String> filterOptions;

  /// Callback que se ejecuta cuando cambia la selección del filtro
  final ValueChanged<String> onFilterChanged;

  const HistoryFilter({
    super.key,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Filtrar:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedFilter,
                isExpanded: true,
                onChanged: (String? value) {
                  if (value != null) {
                    onFilterChanged(value);
                  }
                },
                items: filterOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
