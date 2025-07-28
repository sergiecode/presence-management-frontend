import 'package:flutter/material.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';
import '../../core/constants/location_types.dart';

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

  /// Ubicación seleccionada para trabajar (selección única)
  final int selectedLocation;

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

  /// Función que se ejecuta al cambiar ubicación (selección única)
  final Function(int) onLocationChanged;

  final String? otherLocationDetail;
  final Function(String)? onOtherLocationChanged;

  // Nuevos campos para dirección completa
  final String? otherLocationFloor;
  final String? otherLocationApartment;
  final Function(String)? onOtherLocationFloorChanged;
  final Function(String)? onOtherLocationApartmentChanged;

  // Campo para el location_detail cuando la jornada está completada
  final String? completedLocationDetail;

  // Historial de ubicaciones durante la jornada
  final List<Map<String, dynamic>>? locationHistory;

  const WorkStatusPanel({
    super.key,
    required this.isWorking,
    this.workStartTime,
    required this.workDuration,
    required this.totalDayTime,
    required this.selectedLocation,
    required this.locations,
    this.isProcessing = false,
    this.dayCompleted = false,
    required this.onStartWork,
    required this.onStopWork,
    required this.onLocationChanged,
    this.otherLocationDetail,
    this.onOtherLocationChanged,
    this.otherLocationFloor,
    this.otherLocationApartment,
    this.onOtherLocationFloorChanged,
    this.onOtherLocationApartmentChanged,
    this.completedLocationDetail,
    this.locationHistory,
  });

  /// Formatea una duración como "HH:MM:SS"
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  /// Formatea timestamp para el historial de ubicaciones
  String _formatHistoryTime(String timestamp) {
    try {
      DateTime dateTime;
      
      // Si el timestamp contiene 'T', es un formato ISO completo
      if (timestamp.contains('T')) {
        dateTime = DateTime.parse(timestamp);
      } else {
        // Si es solo hora (HH:MM:SS), combinar con fecha de hoy
        final today = DateTime.now();
        final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        dateTime = DateTime.parse('$todayStr $timestamp');
      }
      
      // Formatear como HH:MM
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return timestamp;
    }
  }

  /// Construye el texto de ubicación completo incluyendo piso y departamento
  String _buildLocationText() {
    // Si la jornada está completada, usar el completedLocationDetail del backend
    if (dayCompleted && completedLocationDetail != null) {
      return completedLocationDetail!;
    }
    
    // Si no está completada, usar la lógica normal
    if (selectedLocation == LocationTypes.REMOTE_ALTERNATIVE && (otherLocationDetail?.isNotEmpty ?? false)) {
      String locationText = otherLocationDetail!;
      
      // Agregar piso si está disponible
      if (otherLocationFloor?.isNotEmpty ?? false) {
        locationText += ', Piso ${otherLocationFloor!}';
      }
      
      // Agregar departamento si está disponible
      if (otherLocationApartment?.isNotEmpty ?? false) {
        locationText += ', Dpto ${otherLocationApartment!}';
      }
      
      return locationText;
    }
    return locations[selectedLocation] ?? '';
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

            // Mensaje motivacional durante la jornada o total trabajado al finalizar
            if (isWorking || dayCompleted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dayCompleted 
                    ? const Color(0xFFE67D21).withValues(alpha: 0.1)
                    : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dayCompleted 
                      ? const Color(0xFFE67D21).withValues(alpha: 0.3)
                      : Colors.blue.shade200,
                  ),
                ),
                child: dayCompleted 
                  ? // Mostrar total trabajado cuando la jornada está completada
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: const Color(0xFFE67D21),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total trabajado hoy:',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                    )
                  : // Mostrar mensaje motivacional solo cuando está trabajando
                    Column(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¡ABSTI te desea una excelente jornada!',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Que tengas un día productivo y exitoso 🚀',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
              ),

            const SizedBox(height: 20),

            // Selector de ubicación (solo cuando no está trabajando Y no está completado)
             if (!isWorking && !dayCompleted) ...[
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
              // Radio buttons para selección única de ubicación
              Column(
                children: locations.entries.map((entry) {
                  return RadioListTile<int>(
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: selectedLocation,
                    onChanged: isProcessing
                        ? null
                        : (int? value) {
                            if (value != null) {
                              onLocationChanged(value);
                            }
                          },
                    activeColor: const Color(0xFFE67D21),
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
              // Mostrar input si "Domicilio Alternativo" está seleccionado
              if (selectedLocation == LocationTypes.REMOTE_ALTERNATIVE) ...[ // REMOTE_ALTERNATIVE (Domicilio Alternativo)
                const SizedBox(height: 12),
                AddressSearchField(
                  enabled: !isProcessing,
                  onAddressSelected: onOtherLocationChanged,
                  initialValue: otherLocationDetail,
                ),
                const SizedBox(height: 12),
                // Campos adicionales para piso y departamento
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enabled: !isProcessing,
                        decoration: const InputDecoration(
                          labelText: 'Piso (opcional)',
                          border: OutlineInputBorder(),
                          hintText: 'Ej: 3°',
                        ),
                        onChanged: onOtherLocationFloorChanged,
                        controller: TextEditingController(text: otherLocationFloor ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        enabled: !isProcessing,
                        decoration: const InputDecoration(
                          labelText: 'Dpto (opcional)',
                          border: OutlineInputBorder(),
                          hintText: 'Ej: A, 201',
                        ),
                        onChanged: onOtherLocationApartmentChanged,
                        controller: TextEditingController(text: otherLocationApartment ?? ''),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Mostrar ubicación final cuando la jornada está completada
            if (dayCompleted) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jornada finalizada en:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _buildLocationText(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Historial de ubicaciones durante la jornada
              if (locationHistory != null && locationHistory!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timeline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recorrido durante la jornada:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Timeline de ubicaciones
                      ...locationHistory!.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final Map<String, dynamic> location = entry.value;
                        final bool isLast = index == locationHistory!.length - 1;
                        
                        return Stack(
                          children: [
                            // Línea conectora (excepto para el último elemento)
                            if (!isLast)
                              Positioned(
                                left: 5,
                                top: 20,
                                child: Container(
                                  width: 2,
                                  height: 35,
                                  color: Colors.blue.shade200,
                                ),
                              ),
                            // Contenido del elemento
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: location['event'] == 'check_in' 
                                        ? Colors.green.shade600
                                        : location['event'] == 'check_out'
                                          ? Colors.red.shade600
                                          : Colors.orange.shade600,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (location['event'] == 'check_in' 
                                            ? Colors.green.shade600
                                            : location['event'] == 'check_out'
                                              ? Colors.red.shade600
                                              : Colors.orange.shade600).withAlpha(100),
                                          blurRadius: 3,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          location['description'] ?? 'Ubicación',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (location['location_detail'] != null && 
                                            location['location_detail'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              location['location_detail'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatHistoryTime(location['timestamp'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
                      'Trabajando desde: ${_buildLocationText()}',
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
