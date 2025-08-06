import 'package:flutter/material.dart';

/// **MOLÉCULA: Diálogo de Confirmación de Trabajo**
///
/// Componente que muestra diálogos de confirmación para iniciar o
/// terminar la jornada laboral con información relevante.
///
/// **Características:**
/// - Información detallada de la acción a realizar
/// - Botones de confirmación y cancelación
/// - Diferentes tipos de diálogo (inicio/fin de jornada)
/// - Información contextual (ubicación, hora, duración)
class WorkConfirmationDialog {
  /// Muestra un diálogo para confirmar el inicio de jornada
  static Future<bool?> showStartWorkDialog({
    required BuildContext context,
    required String locationName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Iniciar Jornada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Deseas iniciar tu jornada laboral?'),
              const SizedBox(height: 12),

              // Información de ubicación
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFFE67D21),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ubicación: $locationName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE67D21),
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Información de hora
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Hora: ${_formatCurrentTime()}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67D21),
              ),
              child: const Text(
                'Iniciar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para confirmar el fin de jornada
  static Future<bool?> showStopWorkDialog({
    required BuildContext context,
    required Duration sessionDuration,
    required String locationName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terminar Jornada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Deseas terminar tu jornada laboral?'),
              const SizedBox(height: 12),

              // Información de la sesión
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Color(0xFFE67D21),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Duración: ${_formatDuration(sessionDuration)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE67D21),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ubicación: $locationName',
                            style: TextStyle(color: Colors.grey[600]),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hora final: ${_formatCurrentTime()}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Terminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Formatea la hora actual como "HH:MM"
  static String _formatCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// Formatea una duración como "HH:MM:SS"
  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
