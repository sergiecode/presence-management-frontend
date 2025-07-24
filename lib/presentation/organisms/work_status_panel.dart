import 'package:flutter/material.dart';
import '../atoms/atoms.dart';

/// **ORGANISMO: Panel de Estado de Trabajo**
///
/// Componente que muestra el estado actual del trabajo del usuario,
/// incluyendo si está trabajando o no, el tiempo transcurrido, y
/// controles para iniciar/terminar la jornada.
///
/// **Características:**
/// - Muestra tiempo en tiempo real cuando está trabajando
/// - Estados visuales claros (trabajando vs no trabajando)
/// - Controles intuitivos para iniciar/terminar jornada
/// - Selección de ubicación de trabajo
/// - Información de tiempo acumulado del día
///
/// **Átomos/Moléculas utilizados:**
/// - CustomButton (para acciones principales)
/// - StatusMessage (para información del estado)
class WorkStatusPanel extends StatelessWidget {
  /// Si el usuario está actualmente trabajando
  final bool isWorking;

  /// Hora de inicio de la jornada actual (null si no está trabajando)
  final DateTime? workStartTime;

  /// Duración actual de la sesión de trabajo
  final Duration workDuration;

  /// Tiempo total trabajado en el día
  final Duration totalDayTime;

  /// Ubicación seleccionada para trabajar
  final List<int> selectedLocations;

  /// Mapa de ubicaciones disponibles
  final Map<int, String> locations;

  /// Si una operación está en progreso (para mostrar loading)
  final bool isProcessing;

  /// Si la jornada del día ya está completada
  final bool dayCompleted;

  /// Función que se ejecuta al iniciar trabajo
  final VoidCallback onStartWork;

  /// Función que se ejecuta al terminar trabajo
  final VoidCallback onStopWork;

  /// Función que se ejecuta al cambiar ubicación
  final Function(int, bool) onLocationToggled;

  final String? otherLocationDetail;
  final Function(String)? onOtherLocationChanged;

  const WorkStatusPanel({
    super.key,
    required this.isWorking,
    this.workStartTime,
    required this.workDuration,
    required this.totalDayTime,
    required this.selectedLocations,
    required this.locations,
    this.isProcessing = false,
    this.dayCompleted = false,
    required this.onStartWork,
    required this.onStopWork,
    required this.onLocationToggled,
    this.otherLocationDetail,
    this.onOtherLocationChanged,
  });

  /// Formatea una duración como "HH:MM:SS"
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cartel especial para día completado
            if (dayCompleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Icono de completado
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Texto principal
                    const Text(
                      '¡Día Completado!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Texto secundario
                    Text(
                      'Has terminado tu jornada laboral de hoy',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Emoji celebratorio
                    const Text(
                      '🎉 ¡Buen trabajo! 🎉',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],

            // Estado actual del trabajo
            if (!dayCompleted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isWorking ? Colors.green.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isWorking
                        ? Colors.green.shade200
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    // Indicador visual del estado
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isWorking ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Texto del estado
                    Expanded(
                      child: Text(
                        isWorking
                            ? 'Trabajando actualmente'
                            : 'No está trabajando',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isWorking
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Espaciado condicional
            SizedBox(height: dayCompleted ? 0 : 20),

            // Tiempo actual de la sesión
            if (isWorking) ...[
              Text(
                'Tiempo de sesión actual',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDuration(workDuration),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE67D21),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Tiempo total del día
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE67D21).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total trabajado hoy:',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDuration(totalDayTime),
                    style: const TextStyle(
                      color: Color(0xFFE67D21),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Selector de ubicación (solo cuando no está trabajando)
             if (!isWorking) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFE67D21)),
                  const SizedBox(width: 8),
                  const Text(
                    'Ubicación de trabajo:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ExpansionTile(
                  title: Text(
                    selectedLocations.isEmpty 
                        ? 'Seleccionar ubicaciones'
                        : selectedLocations.map((key) => locations[key] ?? '').join(', '),
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedLocations.isEmpty ? Colors.grey.shade600 : Colors.black87,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down),
                  children: [
                    ...locations.entries.map((entry) {
                      final isSelected = selectedLocations.contains(entry.key);
                      return CheckboxListTile(
                        title: Text(entry.value),
                        value: isSelected,
                        onChanged: isProcessing
                            ? null
                            : (bool? value) {
                                onLocationToggled(entry.key, value ?? false);
                              },
                        activeColor: const Color(0xFFE67D21),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }),
                  ],
                ),
              ),
              // Mostrar input si "Otro" está seleccionado
              if (selectedLocations.contains(4)) ...[
                const SizedBox(height: 12),
                TextField(
                  enabled: !isProcessing,
                  decoration: const InputDecoration(
                    labelText: 'Especificar dirección',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onOtherLocationChanged,
                  controller: TextEditingController(text: otherLocationDetail ?? ''),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Información de ubicación actual (cuando está trabajando)
            if (isWorking) ...[
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFFE67D21),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trabajando desde: ${selectedLocations.map((key) {
                        if (key == 4 && (otherLocationDetail?.isNotEmpty ?? false)) {
                          return otherLocationDetail!;
                        }
                        return locations[key] ?? '';
                      }).where((s) => s.isNotEmpty).join(', ')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Botón principal (iniciar/terminar)
            CustomButton(
              text: dayCompleted
                  ? 'Jornada Completada'
                  : (isWorking ? 'Terminar Jornada' : 'Iniciar Jornada'),
              onPressed: isProcessing || dayCompleted
                  ? null
                  : (isWorking
                        ? () {
                            onStopWork();
                          }
                        : () {
                            onStartWork();
                          }),
              isLoading: isProcessing,
              type: dayCompleted ? ButtonType.secondary : ButtonType.primary,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
