import 'package:flutter/material.dart';
import '../atoms/atoms.dart';

/// **MOLÉCULA: Diálogo para selección de horarios**
///
/// Diálogo que permite al usuario ver y modificar sus horarios habituales
/// antes de iniciar la jornada laboral.
///
/// **Características:**
/// - Muestra horarios habituales del usuario (desde API /users/me)
/// - Permite modificar horarios si es necesario
/// - Convierte horarios a formato UTC para envío al backend
class ScheduleSelectionDialog extends StatefulWidget {
  /// Horario habitual de inicio del usuario
  final TimeOfDay defaultStartTime;
  
  /// Horario habitual de fin del usuario
  final TimeOfDay defaultEndTime;
  
  /// Nombre de la ubicación seleccionada
  final String locationName;

  const ScheduleSelectionDialog({
    super.key,
    required this.defaultStartTime,
    required this.defaultEndTime,
    required this.locationName,
  });

  /// Muestra el diálogo y retorna los horarios seleccionados
  static Future<Map<String, TimeOfDay>?> show({
    required BuildContext context,
    required TimeOfDay defaultStartTime,
    required TimeOfDay defaultEndTime,
    required String locationName,
  }) {
    return showDialog<Map<String, TimeOfDay>>(
      context: context,
      barrierDismissible: false, // Requiere selección explícita
      builder: (context) => ScheduleSelectionDialog(
        defaultStartTime: defaultStartTime,
        defaultEndTime: defaultEndTime,
        locationName: locationName,
      ),
    );
  }

  @override
  State<ScheduleSelectionDialog> createState() => _ScheduleSelectionDialogState();
}

class _ScheduleSelectionDialogState extends State<ScheduleSelectionDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.defaultStartTime;
    _endTime = widget.defaultEndTime;
  }

  /// Valida que los horarios sean correctos
  bool _validateSchedule() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    if (endMinutes <= startMinutes) {
      _showError('La hora de fin debe ser posterior a la de inicio');
      return false;
    }
    
    return true;
  }

  /// Muestra un error al usuario
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.schedule, color: const Color(0xFFE67D21)),
          const SizedBox(width: 12),
          const Text(
            'Confirma tus horarios',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de ubicación
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trabajarás desde: ${widget.locationName}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Horarios habituales:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selector de hora de inicio
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hora de inicio:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _startTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                _startTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Selector de hora de fin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hora de fin:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _endTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _endTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                _endTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Información adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Estos son tus horarios habituales. Puedes modificarlos si necesitas trabajar en horarios diferentes hoy.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(),
                type: ButtonType.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Iniciar Jornada',
                onPressed: () {
                  if (_validateSchedule()) {
                    Navigator.of(context).pop({
                      'startTime': _startTime,
                      'endTime': _endTime,
                    });
                  }
                },
                type: ButtonType.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
