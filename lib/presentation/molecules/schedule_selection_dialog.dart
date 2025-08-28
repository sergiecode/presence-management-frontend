import 'package:flutter/material.dart';
import '../atoms/atoms.dart';

/// **MOLÉCULA: Diálogo para confirmación y selección de horarios**
///
/// Diálogo que permite al usuario ver sus horarios calculados inteligentemente
/// y opcionalmente modificarlos antes de iniciar la jornada laboral.
///
/// **Características:**
/// - Muestra horarios inteligentes (habituales vs actuales según hora del día)
/// - Permite iniciar jornada con horarios mostrados
/// - Opción para modificar horarios manualmente
/// - Validaciones de duración mínima y coherencia de horarios
class ScheduleSelectionDialog extends StatefulWidget {
  /// Horario habitual de inicio del usuario
  final TimeOfDay defaultStartTime;
  
  /// Horario habitual de fin del usuario
  final TimeOfDay defaultEndTime;
  
  /// Horario habitual original de inicio (para comparación)
  final TimeOfDay habitualStartTime;
  
  /// Horario habitual original de fin (para comparación)
  final TimeOfDay habitualEndTime;
  
  /// Nombre de la ubicación seleccionada
  final String locationName;

  const ScheduleSelectionDialog({
    super.key,
    required this.defaultStartTime,
    required this.defaultEndTime,
    required this.habitualStartTime,
    required this.habitualEndTime,
    required this.locationName,
  });

  /// Muestra el diálogo y retorna los horarios seleccionados
  static Future<Map<String, TimeOfDay>?> show({
    required BuildContext context,
    required TimeOfDay defaultStartTime,
    required TimeOfDay defaultEndTime,
    required TimeOfDay habitualStartTime,
    required TimeOfDay habitualEndTime,
    required String locationName,
  }) {
    return showDialog<Map<String, TimeOfDay>>(
      context: context,
      barrierDismissible: false, // Requiere selección explícita
      builder: (context) => ScheduleSelectionDialog(
        defaultStartTime: defaultStartTime,
        defaultEndTime: defaultEndTime,
        habitualStartTime: habitualStartTime,
        habitualEndTime: habitualEndTime,
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

  /// Calcula la duración en minutos entre dos horarios
  int _calculateDurationInMinutes(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes - startMinutes;
  }

  /// Verifica si la duración actual es menor a la habitual
  bool _isWorkingFewerHours() {
    final currentDuration = _calculateDurationInMinutes(_startTime, _endTime);
    final habitualDuration = _calculateDurationInMinutes(widget.habitualStartTime, widget.habitualEndTime);
    return currentDuration < habitualDuration;
  }

  /// Muestra diálogos para seleccionar nuevos horarios
  Future<void> _showTimeSelectionDialog() async {
    final startTime = await _selectTime(
      context: context,
      initialTime: _startTime,
      title: 'Selecciona hora de inicio',
    );
    
    if (startTime != null && mounted) {
      final endTime = await _selectTime(
        context: context,
        initialTime: _endTime,
        title: 'Selecciona hora de fin',
      );
      
      if (endTime != null && mounted) {
        // Validar que el horario de fin sea después del de inicio
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;
        
        if (endMinutes <= startMinutes) {
          _showError('La hora de fin debe ser posterior a la hora de inicio');
          return;
        }
        
        // Validar duración mínima (por ejemplo, al menos 1 hora)
        final durationHours = (endMinutes - startMinutes) / 60;
        if (durationHours < 1) {
          _showError('La jornada debe tener una duración mínima de 1 hora');
          return;
        }
        
        setState(() {
          _startTime = startTime;
          _endTime = endTime;
        });
      }
    }
  }

  /// Muestra selector de tiempo
  Future<TimeOfDay?> _selectTime({
    required BuildContext context,
    required TimeOfDay initialTime,
    required String title,
  }) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: title,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Muestra mensaje de error
  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
            // Información de ubicación y horarios seleccionados
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título principal
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Información de tu jornada',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Ubicación (en su propia línea)
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Trabajarás desde:',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      widget.locationName,
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Horarios (en su propia línea)
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Horarios:',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      '${_startTime.format(context)} - ${_endTime.format(context)}',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Advertencia si está trabajando menos horas
            if (_isWorkingFewerHours()) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ Advertencia: Menos horas que lo habitual',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trabajarás menos horas que tu horario habitual. ¿Deseas continuar?',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            const SizedBox(height: 16),
            

          ],
        ),
      ),
      actions: [
        Column(
          children: [
            // Botón principal: Iniciar Jornada
            SizedBox(
              width: double.maxFinite,
              child: CustomButton(
                text: 'Iniciar Jornada',
                onPressed: () {
                  Navigator.of(context).pop({
                    'startTime': _startTime,
                    'endTime': _endTime,
                  });
                },
                type: ButtonType.primary,
              ),
            ),
            const SizedBox(height: 8),
            // Segunda fila: Modificar Horarios y Cancelar
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Modificar Horarios',
                    onPressed: _showTimeSelectionDialog,
                    type: ButtonType.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(),
                    type: ButtonType.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
