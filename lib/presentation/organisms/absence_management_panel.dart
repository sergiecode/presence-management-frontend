import 'package:flutter/material.dart';
import '../molecules/molecules.dart';

/// **Panel de Gestión de Ausencias**
///
/// Organismo que maneja la visualización y creación de ausencias.
/// Incluye el botón para nueva ausencia, tipos disponibles y lista de ausencias.
///
/// [absences] - Lista de ausencias del usuario
/// [absenceTypes] - Tipos de ausencia disponibles
/// [isCreating] - Indica si se está creando una ausencia
/// [onNewAbsence] - Callback para mostrar diálogo de nueva ausencia
/// [onRefresh] - Callback para refrescar los datos
class AbsenceManagementPanel extends StatelessWidget {
  /// Lista de ausencias del usuario
  final List<Map<String, dynamic>> absences;

  /// Lista de tipos de ausencia disponibles con sus propiedades
  final List<Map<String, dynamic>> absenceTypes;

  /// Indica si se está procesando la creación de una ausencia
  final bool isCreating;

  /// Callback que se ejecuta al presionar el botón de nueva ausencia
  final VoidCallback onNewAbsence;

  /// Callback que se ejecuta al hacer pull-to-refresh
  final Future<void> Function() onRefresh;

  const AbsenceManagementPanel({
    super.key,
    required this.absences,
    required this.absenceTypes,
    required this.isCreating,
    required this.onNewAbsence,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildAbsenceTypesPanel(),
          const SizedBox(height: 24),
          _buildHistoryHeader(),
          const SizedBox(height: 12),
          Expanded(child: _buildAbsencesList()),
        ],
      ),
    );
  }

  /// Construye el encabezado con título y botón de nueva ausencia
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mis Ausencias',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Container(
          decoration: BoxDecoration(
            color: isCreating ? Colors.grey[400] : const Color(0xFFe67d21),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add, color: Colors.white),
            onPressed: isCreating ? null : onNewAbsence,
          ),
        ),
      ],
    );
  }

  /// Construye el panel que muestra los tipos de ausencia disponibles
  Widget _buildAbsenceTypesPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipos de Ausencia Disponibles:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: absenceTypes.map((type) {
              return AbsenceTypeChip(
                label: type['label'],
                icon: type['icon'],
                color: type['color'],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Construye el encabezado de la sección de historial
  Widget _buildHistoryHeader() {
    return const Text(
      'Historial de Ausencias',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  /// Construye la lista de ausencias o el estado vacío
  Widget _buildAbsencesList() {
    if (absences.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFFe67d21),
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: absences.length,
        itemBuilder: (context, index) {
          final absence = absences[index];
          return AbsenceCard(absence: absence, absenceTypes: absenceTypes);
        },
      ),
    );
  }

  /// Construye el estado vacío cuando no hay ausencias
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes ausencias registradas',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onNewAbsence,
            child: const Text(
              'Registrar mi primera ausencia',
              style: TextStyle(color: Color(0xFFe67d21)),
            ),
          ),
        ],
      ),
    );
  }
}
