import 'package:flutter/material.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';
import '../molecules/add_location_dialog.dart';
import '../../core/constants/location_types.dart';
import '../../data/models/work_location.dart';
import '../../data/services/catalog_service.dart';

/// Resultado de validación de jornada laboral
class WorkdayValidation {
  bool isValid = false;
  double totalHours = 0.0;
  double requiredHours = 9.0;
  double missingHours = 0.0;
  String message = '';
  List<String> suggestions = [];
}

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

  /// Ubicaciones seleccionadas para trabajar (selección múltiple)
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

  /// Función que se ejecuta al cambiar ubicaciones (selección múltiple)
  final Function(List<int>) onLocationChanged;
  
  /// Modo de selección: 'single' para una ubicación, 'multiple' para varias
  final String selectionMode;
  
  /// Función que se ejecuta al cambiar el modo de selección
  final Function(String) onSelectionModeChanged;
  
  /// Función que se ejecuta al seleccionar una ubicación única
  final Function(int)? onSingleLocationChanged;
  
  /// Ubicación única seleccionada (cuando está en modo 'single')
  final int? selectedSingleLocation;
  
  /// Mapa de horarios para ubicaciones múltiples
  final Map<int, TimeOfDay>? locationSchedule;
  
  /// Función que se ejecuta al cambiar horarios de ubicaciones
  final Function(Map<int, TimeOfDay>)? onScheduleChanged;

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

  // Nuevas propiedades para la funcionalidad mejorada de ubicaciones
  /// Ubicaciones del catálogo (oficinas, clientes, etc.)
  final List<CatalogLocation>? catalogLocations;
  
  /// Dirección del domicilio declarado del usuario
  final String? userDeclaredAddress;
  
  /// Lista de ubicaciones adicionales agregadas durante el día
  final List<WorkLocation> additionalLocations;
  
  /// Función para agregar una nueva ubicación adicional
  final Function(WorkLocation)? onAddAdditionalLocation;
  
  /// Función para remover una ubicación adicional
  final Function(int)? onRemoveAdditionalLocation;
  
  /// Función para actualizar una ubicación adicional
  final Function(int, WorkLocation)? onUpdateAdditionalLocation;

  /// Horarios habituales del usuario
  final TimeOfDay? userStartTime;
  final TimeOfDay? userEndTime;
  
  /// Horarios habituales ORIGINALES del backend (para validación)
  final TimeOfDay? originalStartTime;
  final TimeOfDay? originalEndTime;
  
  /// Funciones para modificar horarios
  final Function(TimeOfDay)? onStartTimeChanged;
  final Function(TimeOfDay)? onEndTimeChanged;

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
    required this.onLocationChanged,
    required this.selectionMode,
    required this.onSelectionModeChanged,
    this.onSingleLocationChanged,
    this.selectedSingleLocation,
    this.locationSchedule,
    this.onScheduleChanged,
    this.otherLocationDetail,
    this.onOtherLocationChanged,
    this.otherLocationFloor,
    this.otherLocationApartment,
    this.onOtherLocationFloorChanged,
    this.onOtherLocationApartmentChanged,
    this.completedLocationDetail,
    this.locationHistory,
    // Nuevas propiedades
    this.catalogLocations,
    this.userDeclaredAddress,
    this.additionalLocations = const [],
    this.onAddAdditionalLocation,
    this.onRemoveAdditionalLocation,
    this.onUpdateAdditionalLocation,
    // Horarios habituales
    this.userStartTime,
    this.userEndTime,
    this.originalStartTime,
    this.originalEndTime,
    this.onStartTimeChanged,
    this.onEndTimeChanged,
  });

  /// Formatea una duración como "HH:MM:SS"
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  /// Construye el texto de ubicación completo incluyendo piso y departamento
  String _buildLocationText() {
    // Si la jornada está completada, usar el completedLocationDetail del backend
    if (dayCompleted && completedLocationDetail != null) {
      return completedLocationDetail!;
    }
    
    // Si no está completada, usar la ubicación principal seleccionada
    if (selectedSingleLocation != null) {
      if (selectedSingleLocation == LocationTypes.REMOTE_ALTERNATIVE && (otherLocationDetail?.isNotEmpty ?? false)) {
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
      return _getLocationDisplayName(selectedSingleLocation!);
    }
    return '';
  }

  /// Construye las opciones de ubicación basadas en catálogos y domicilio declarado
  /// Convierte el ID de la UI al location_type que espera el backend
  int _getLocationTypeForBackend(int uiId) {
    final locationOptions = _buildLocationOptions();
    final option = locationOptions.firstWhere(
      (opt) => opt.id == uiId,
      orElse: () => LocationOption(
        id: uiId,
        name: 'Unknown',
        source: LocationSource.catalog,
      ),
    );
    
    // Si es una ubicación de catálogo, usar el mapeo
    if (option.source == LocationSource.catalog && option.catalogId != null) {
      return _mapCatalogIdToLocationType(option.catalogId!);
    }
    
    // Para domicilio declarado y alternativo, usar el ID directamente
    return uiId;
  }

  /// Mapea el ID del catálogo al location_type que espera el backend
  int _mapCatalogIdToLocationType(int catalogId) {
    switch (catalogId) {
      case 1: return 101; // Oficina ABSTI
      case 2: return 102; // Swiss Medical
      case 3: return 104; // Allianz 
      case 4: return 103; // Galicia
      default: return catalogId + 100; // Fallback genérico
    }
  }
  
  /// Mapea el location_type del backend al ID de la UI
  int _getUIIdFromLocationTypeFromBackend(int backendLocationTypeId) {
    // Para tipos básicos (1, 2), usar directamente
    if (backendLocationTypeId == LocationTypes.REMOTE_DECLARED || 
        backendLocationTypeId == LocationTypes.REMOTE_ALTERNATIVE) {
      return backendLocationTypeId;
    }
    
    // Para tipos de catálogo (101, 102, 103, 104), mapear a IDs únicos
    final catalogId = _mapLocationTypeToCatalogId(backendLocationTypeId);
    return 1000 + catalogId; // Convertir a ID único de UI
  }

  /// Mapea el location_type del backend al ID del catálogo
  int _mapLocationTypeToCatalogId(int locationType) {
    switch (locationType) {
      case 101: return 1; // Oficina ABSTI
      case 102: return 2; // Swiss Medical
      case 104: return 3; // Allianz
      case 103: return 4; // Galicia
      default: return locationType > 100 ? locationType - 100 : locationType;
    }
  }

  List<LocationOption> _buildLocationOptions() {
    List<LocationOption> options = [];

    // 1. Domicilio Declarado (siempre disponible) - usa ID único para UI
    options.add(LocationOption(
      id: LocationTypes.REMOTE_DECLARED, // ID 1
      name: 'Domicilio Declarado',
      description: userDeclaredAddress?.isNotEmpty == true 
          ? userDeclaredAddress 
          : 'Trabajar desde domicilio registrado',
      source: LocationSource.declaredAddress,
    ));

    // 2. Domicilio Alternativo (siempre disponible) - usa ID único para UI
    options.add(LocationOption(
      id: LocationTypes.REMOTE_ALTERNATIVE, // ID 2
      name: 'Domicilio Alternativo',
      description: 'Trabajar desde una dirección alternativa',
      source: LocationSource.alternativeAddress,
    ));

    // 3. Ubicaciones del catálogo - usa IDs únicos empezando desde 1000
    if (catalogLocations != null) {
      for (final catalogLocation in catalogLocations!) {
        if (catalogLocation.isActive) {
          options.add(LocationOption(
            id: 1000 + catalogLocation.id, // ID único: 1001, 1002, 1003, 1004
            name: catalogLocation.name,
            description: catalogLocation.description ?? catalogLocation.address,
            source: LocationSource.catalog,
            address: catalogLocation.address,
            catalogId: catalogLocation.id, // Guardamos el ID original del catálogo
          ));
        }
      }
    }

    return options;
  }

  /// Valida la coherencia de los horarios cuando se hacen cambios
  void _validateScheduleCoherence(BuildContext context, TimeOfDay newTime, bool isStartTime) {
    if (additionalLocations.isNotEmpty) {
      final conflicts = _findScheduleConflicts(context, newTime, isStartTime);
      if (conflicts.isNotEmpty) {
        _showScheduleWarning(context, conflicts, newTime, isStartTime);
      }
    }
  }

  /// Encuentra conflictos potenciales con ubicaciones adicionales
  List<String> _findScheduleConflicts(BuildContext context, TimeOfDay newTime, bool isStartTime) {
    final conflicts = <String>[];
    final newTimeMinutes = newTime.hour * 60 + newTime.minute;
    
    final currentStartMinutes = userStartTime != null 
        ? (userStartTime!.hour * 60 + userStartTime!.minute)
        : (9 * 60); // Default 9 AM
    final currentEndMinutes = userEndTime != null 
        ? (userEndTime!.hour * 60 + userEndTime!.minute)
        : (17 * 60); // Default 5 PM

    // Determinar el nuevo rango completo
    final effectiveStartMinutes = isStartTime ? newTimeMinutes : currentStartMinutes;
    final effectiveEndMinutes = isStartTime ? currentEndMinutes : newTimeMinutes;

    // Verificar conflictos con ubicaciones adicionales
    for (final location in additionalLocations) {
      final locationStart = location.startTime.hour * 60 + location.startTime.minute;
      final locationEnd = location.endTime != null
          ? (location.endTime!.hour * 60 + location.endTime!.minute)
          : effectiveEndMinutes; // Si no tiene fin, usar el fin de jornada

      // Verificar si la ubicación adicional queda fuera del nuevo horario habitual
      if (locationStart < effectiveStartMinutes || locationEnd > effectiveEndMinutes) {
        final locationName = _getLocationDisplayNameFromBackendType(location.locationTypeId);
        final timeRange = location.endTime != null
            ? '${location.startTime.format(context)} - ${location.endTime!.format(context)}'
            : 'desde ${location.startTime.format(context)}';
        conflicts.add('$locationName ($timeRange)');
      }
    }

    return conflicts;
  }

  /// Muestra advertencia sobre conflictos de horarios
  void _showScheduleWarning(BuildContext context, List<String> conflicts, TimeOfDay newTime, bool isStartTime) {
    final timeType = isStartTime ? 'inicio' : 'fin';
    final timeText = newTime.format(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Advertencia de Horarios'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Al cambiar el horario de $timeType a $timeText, las siguientes ubicaciones quedarán fuera del horario habitual:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...conflicts.map((conflict) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, 
                    color: Colors.red.shade600, 
                    size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      conflict,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, 
                        color: Colors.blue.shade600, 
                        size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Recomendación:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Revisa y ajusta manualmente los horarios de estas ubicaciones o modifica tu horario habitual para que sea consistente.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Modificar Manualmente'),
          ),
        ],
      ),
    );
  }

  /// Calcula la hora de inicio efectiva que se debe mostrar (considerando si llego tarde)
  TimeOfDay _getEffectiveStartTime() {
    if (originalStartTime == null) return userStartTime ?? const TimeOfDay(hour: 9, minute: 0);
    
    final currentTime = TimeOfDay.now();
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final habitualStartMinutes = originalStartTime!.hour * 60 + originalStartTime!.minute;
    
    // Lógica clara y simple:
    // - Si es ANTES del horario habitual: mostrar horario habitual
    // - Si es DESPUÉS del horario habitual: mostrar hora actual (NOW)
    if (currentMinutes > habitualStartMinutes) {
      // Es más tarde que el horario habitual → mostrar hora actual
      return currentTime;
    } else {
      // Es más temprano o igual → mostrar horario habitual
      return originalStartTime!;
    }
  }

  /// Muestra un time picker con validaciones inteligentes basadas en horarios habituales y hora actual
  Future<TimeOfDay?> _showValidatedTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    required bool isStartTime,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked == null) return null;
    
    final pickedMinutes = picked.hour * 60 + picked.minute;
    
    if (isStartTime) {
      // Para hora de INICIO: lógica basada en horario habitual vs hora actual
      final currentTime = TimeOfDay.now();
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      
      if (originalStartTime != null) {
        final habitualStartMinutes = originalStartTime!.hour * 60 + originalStartTime!.minute;
        
        int minimumStartMinutes;
        String reason;
        
        if (currentMinutes > habitualStartMinutes) {
          // Si llego tarde: usar hora del celular como mínimo
          minimumStartMinutes = currentMinutes;
          reason = 'Estás llegando tarde. Tu horario habitual era ${originalStartTime!.format(context)}, pero ya son las ${currentTime.format(context)}';
        } else {
          // Si llegué temprano o a tiempo: usar horario habitual como mínimo
          minimumStartMinutes = habitualStartMinutes;
          reason = 'No puedes iniciar antes de tu horario habitual (${originalStartTime!.format(context)})';
        }
        
        if (pickedMinutes < minimumStartMinutes) {
          final limitTime = TimeOfDay(
            hour: minimumStartMinutes ~/ 60,
            minute: minimumStartMinutes % 60,
          );
          
          _showTimeValidationError(
            context: context,
            message: 'No puedes iniciar antes de las ${limitTime.format(context)}',
            subtitle: reason,
          );
          return null;
        }
      }
    } else {
      // Para hora de FIN: NO puede ser después del horario habitual del backend
      if (originalEndTime != null) {
        final habitualEndMinutes = originalEndTime!.hour * 60 + originalEndTime!.minute;
        if (pickedMinutes > habitualEndMinutes) {
          _showTimeValidationError(
            context: context,
            message: 'No puedes terminar después de tu horario habitual (${originalEndTime!.format(context)})',
            subtitle: 'Solo puedes modificar hacia atrás tu horario de fin',
          );
          return null;
        }
      }
      
      // También validar que sea después de la hora de inicio actual
      if (userStartTime != null) {
        final startMinutes = userStartTime!.hour * 60 + userStartTime!.minute;
        if (pickedMinutes <= startMinutes) {
          _showTimeValidationError(
            context: context,
            message: 'La hora de fin debe ser posterior a tu hora de inicio (${userStartTime!.format(context)})',
            subtitle: 'Selecciona una hora posterior para terminar tu jornada',
          );
          return null;
        }
      }
    }
    
    return picked;
  }

  /// Muestra diálogo de error de validación de horarios
  void _showTimeValidationError({
    required BuildContext context,
    required String message,
    required String subtitle,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.access_time_filled, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Expanded(child: Text('Horario no permitido')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de horarios habituales
  Widget _buildScheduleSection(BuildContext context) {
    return Container(
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
                Icons.schedule,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Horarios:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Horarios en fila
          Row(
            children: [
              // Horario de inicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicio:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: isProcessing ? null : () async {
                        if (onStartTimeChanged != null) {
                          final TimeOfDay? picked = await _showValidatedTimePicker(
                            context: context, 
                            initialTime: _getEffectiveStartTime(),
                            isStartTime: true,
                          );
                          if (picked != null) {
                            // Validar coherencia de horarios antes de aplicar cambios
                            _validateScheduleCoherence(context, picked, true);
                            onStartTimeChanged!(picked);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isProcessing ? Colors.grey.shade100 : Colors.white,
                          border: Border.all(
                            color: isProcessing ? Colors.grey.shade300 : Colors.blue.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time, 
                              size: 16, 
                              color: isProcessing ? Colors.grey.shade400 : Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getEffectiveStartTime().format(context),
                              style: TextStyle(
                                fontSize: 16,
                                color: isProcessing ? Colors.grey.shade600 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Horario de fin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fin:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: isProcessing ? null : () async {
                        if (onEndTimeChanged != null && userEndTime != null) {
                          final TimeOfDay? picked = await _showValidatedTimePicker(
                            context: context, 
                            initialTime: userEndTime!,
                            isStartTime: false,
                          );
                          if (picked != null) {
                            // Validar coherencia de horarios antes de aplicar cambios
                            _validateScheduleCoherence(context, picked, false);
                            onEndTimeChanged!(picked);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isProcessing ? Colors.grey.shade100 : Colors.white,
                          border: Border.all(
                            color: isProcessing ? Colors.grey.shade300 : Colors.blue.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time, 
                              size: 16, 
                              color: isProcessing ? Colors.grey.shade400 : Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userEndTime?.format(context) ?? '18:00',
                              style: TextStyle(
                                fontSize: 16,
                                color: isProcessing ? Colors.grey.shade600 : Colors.black87,
                              ),
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
          
          const SizedBox(height: 12),
          
          // Información adicional
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Puedes modificar tus horarios si necesitas trabajar en horarios diferentes hoy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el selector de ubicación renovado
  Widget _buildNewLocationSelector(BuildContext context) {
    final locationOptions = _buildLocationOptions();
    
    // Validar que el valor seleccionado esté disponible en las opciones
    final availableIds = locationOptions.map((opt) => opt.id).toSet();
    final validSelectedLocation = (selectedSingleLocation != null && 
        availableIds.contains(selectedSingleLocation)) 
        ? selectedSingleLocation 
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown principal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: validSelectedLocation,
              hint: const Text('Selecciona ubicación'),
              onChanged: isProcessing ? null : (int? value) {
                if (value != null) {
                  onSingleLocationChanged?.call(value);
                }
              },
              items: locationOptions.map((option) {
                return DropdownMenuItem<int>(
                  value: option.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      if (option.description != null && option.description!.isNotEmpty)
                        Text(
                          option.description!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Sección de horarios habituales (solo si hay una ubicación seleccionada)
        if (validSelectedLocation != null && (userStartTime != null || userEndTime != null)) ...[
          const SizedBox(height: 20),
          _buildScheduleSection(context),
        ],
        
        // Campo de dirección si se selecciona "Domicilio Alternativo"
        if (validSelectedLocation == LocationTypes.REMOTE_ALTERNATIVE) ...[
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
        
        // Sección de ubicaciones adicionales
        if (additionalLocations.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildAdditionalLocationsSection(context),
        ],
        
        // Botón/Link para agregar más ubicaciones
        const SizedBox(height: 16),
        _buildAddLocationButton(context),
        
        const SizedBox(height: 20),
      ],
    );
  }

  /// Construye la sección de ubicaciones adicionales
  Widget _buildAdditionalLocationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_location_alt, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ubicaciones adicionales para hoy:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...additionalLocations.asMap().entries.map((entry) {
          final int index = entry.key;
          final WorkLocation location = entry.value;
          final locationOptions = _buildLocationOptions();
          
          // Mapear el backend location_type al UI ID correcto
          final uiLocationId = _getUIIdFromLocationTypeFromBackend(location.locationTypeId);
          final locationOption = locationOptions.firstWhere(
            (opt) => opt.id == uiLocationId,
            orElse: () => LocationOption(
              id: uiLocationId,
              name: 'Ubicación ${location.locationTypeId}',
              source: LocationSource.catalog,
            ),
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationOption.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${location.startTime.format(context)} - ${location.endTime?.format(context) ?? "Fin de jornada"}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade600),
                  onPressed: isProcessing ? null : () {
                    onRemoveAdditionalLocation?.call(index);
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Construye el botón para agregar más ubicaciones
  Widget _buildAddLocationButton(BuildContext context) {
    return InkWell(
      onTap: isProcessing ? null : () {
        _showAddLocationDialog(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE67D21)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              color: const Color(0xFFE67D21),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Agregar más ubicaciones',
              style: TextStyle(
                color: const Color(0xFFE67D21),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra el diálogo para agregar una nueva ubicación
  void _showAddLocationDialog(BuildContext context) async {
    if (onAddAdditionalLocation == null) return;
    
    // Crear lista de ubicaciones existentes incluyendo la jornada principal
    List<WorkLocation> allExistingLocations = List.from(additionalLocations);
    
    // Agregar la ubicación principal como ubicación existente si está seleccionada
    if (selectedSingleLocation != null && userStartTime != null && userEndTime != null) {
      final locationName = _getLocationDisplayName(selectedSingleLocation!);
      final backendLocationTypeId = _getLocationTypeForBackend(selectedSingleLocation!);
      final mainWorkLocation = WorkLocation(
        locationTypeId: backendLocationTypeId, // Usar el location_type correcto para el backend
        locationDetail: locationName, // Usar el nombre como detail
        startTime: userStartTime!,
        endTime: userEndTime!,
      );
      allExistingLocations.insert(0, mainWorkLocation); // Insertar al principio
      
      print('DEBUG: Agregando ubicación principal para validación:');
      print('  - UI ID: $selectedSingleLocation');
      print('  - Backend Location Type: $backendLocationTypeId');
      print('  - Detail: $locationName');
      print('  - Horario: ${userStartTime!.format(context)} - ${userEndTime!.format(context)}');
    }

    print('DEBUG: Total ubicaciones existentes para validación: ${allExistingLocations.length}');
    for (int i = 0; i < allExistingLocations.length; i++) {
      final loc = allExistingLocations[i];
      print('  ${i + 1}. ID: ${loc.locationTypeId}, Horario: ${loc.startTime.format(context)} - ${loc.endTime?.format(context) ?? 'Sin fin'}');
    }

    final WorkLocation? newLocation = await AddLocationDialog.show(
      context: context,
      catalogLocations: catalogLocations,
      userDeclaredAddress: userDeclaredAddress,
      existingLocations: allExistingLocations, // Incluir ubicación principal + adicionales
    );

    if (newLocation != null) {
      onAddAdditionalLocation!(newLocation);
    }
  }

  /// Construye el mensaje que muestra las ubicaciones donde se está trabajando
  String _buildWorkingLocationMessage(BuildContext context) {
    // Si hay historial de ubicaciones, usarlo directamente
    if (locationHistory != null && locationHistory!.isNotEmpty) {
      return _buildWorkingLocationMessageFromHistory(context);
    }
    
    // Fallback al método anterior si no hay historial
    List<String> locationParts = [];

    // Agregar la ubicación principal
    if (selectedSingleLocation != null) {
      String primaryLocationName = _getLocationDisplayName(selectedSingleLocation!);
      locationParts.add(primaryLocationName);
    }

    // Agregar ubicaciones adicionales con horarios
    for (final additionalLocation in additionalLocations) {
      String additionalLocationName = _getLocationDisplayNameFromBackendType(additionalLocation.locationTypeId);
      String timeRange = additionalLocation.startTime.format(context);
      if (additionalLocation.endTime != null) {
        timeRange += ' - ${additionalLocation.endTime!.format(context)}';
      }
      locationParts.add('$additionalLocationName ($timeRange)');
    }

    if (locationParts.length == 1) {
      return 'TRABAJANDO DESDE: ${locationParts.first}';
    } else {
      return 'HOY TRABAJARÁS DESDE:\n\n${locationParts.map((part) => '• $part').join('\n')}';
    }
  }

  /// Construye el mensaje usando directamente el historial de ubicaciones
  String _buildWorkingLocationMessageFromHistory(BuildContext context) {
    if (locationHistory == null || locationHistory!.isEmpty) return '';
    
    List<String> locationParts = [];
    
    // Mapear correctamente cada ubicación del historial
    for (int i = 0; i < locationHistory!.length; i++) {
      final location = locationHistory![i];
      final backendLocationDetail = location['location_detail'] as String? ?? '';
      final locationTypeId = location['location_type'] as int?;
      final startTime = location['start_time'] as String?;
      final endTime = location['end_time'] as String?;
      
      // MAPEO CORRECTO: No usar directamente el backend, sino mapear
      String locationText = '';
      
      if (locationTypeId != null) {
        // Usar nuestro mapeo para obtener el nombre correcto
        switch (locationTypeId) {
          case 101:
            locationText = 'Oficina ABSTI';
            break;
          case 102:
            locationText = 'Oficina de Swiss Medical Group';
            break;
          case 103:
            locationText = 'Oficina Galicia';
            break;
          case 104:
            locationText = 'Oficina Allianz';
            break;
          case 1:
            locationText = 'Domicilio Declarado';
            break;
          case 2:
            locationText = 'Domicilio Alternativo';
            break;
          default:
            // Para otros tipos, usar backend detail si no está vacío/desconocido
            if (backendLocationDetail.isNotEmpty && 
                !backendLocationDetail.toLowerCase().contains('desconocido')) {
              locationText = backendLocationDetail;
            } else {
              locationText = 'Ubicación $locationTypeId';
            }
            break;
        }
      } else {
        // Si no hay locationTypeId, usar backend como fallback
        locationText = backendLocationDetail.isNotEmpty ? backendLocationDetail : 'Ubicación';
      }
      
      // Agregar horarios si están disponibles (convertir de UTC a local)
      if (startTime != null) {
        try {
          final startDateTime = DateTime.parse(startTime);
          final localStartTime = startDateTime.toLocal();
          String timeRange = '${localStartTime.hour.toString().padLeft(2, '0')}:${localStartTime.minute.toString().padLeft(2, '0')}';
          
          if (endTime != null) {
            final endDateTime = DateTime.parse(endTime);
            final localEndTime = endDateTime.toLocal();
            timeRange += ' - ${localEndTime.hour.toString().padLeft(2, '0')}:${localEndTime.minute.toString().padLeft(2, '0')}';
          }
          
          locationText += ' ($timeRange)';
        } catch (e) {
          print('Error formateando horarios para ubicación: $e');
          // Si hay error formateando horarios, mostrar solo la ubicación
        }
      }
      
      locationParts.add(locationText);
    }
    
    if (locationParts.isEmpty) {
      return 'Trabajando desde ubicación no especificada';
    } else if (locationParts.length == 1) {
      return 'Trabajando desde: ${locationParts.first}';
    } else {
      return 'Hoy trabajarás desde:\n\n${locationParts.map((part) => '• $part').join('\n')}';
    }
  }

  /// Obtiene el nombre a mostrar de una ubicación por su ID
  String _getLocationDisplayName(int locationId) {
    if (locationId == LocationTypes.REMOTE_DECLARED) {
      return userDeclaredAddress?.isNotEmpty == true 
          ? userDeclaredAddress! 
          : 'Domicilio Declarado';
    } else if (locationId == LocationTypes.REMOTE_ALTERNATIVE) {
      return 'Domicilio Alternativo';
    } else {
      // Si es un ID de la UI del catálogo (1001, 1002, 1003, 1004), convertirlo al ID real del catálogo
      int realCatalogId = locationId;
      if (locationId >= 1001 && locationId <= 1004) {
        realCatalogId = locationId - 1000; // 1001 -> 1, 1002 -> 2, etc.
      }
      
      // Buscar en el catálogo con el ID real
      if (catalogLocations != null) {
        try {
          final catalogLocation = catalogLocations!.firstWhere(
            (cat) => cat.id == realCatalogId,
          );
          return catalogLocation.name;
        } catch (e) {
          // Si no se encuentra en el catálogo, intentar con nombres hardcodeados
        }
      }
      
      // Fallback con nombres hardcodeados para IDs del backend
      switch (locationId) {
        case 101:
          return 'Oficina ABSTI';
        case 102:
          return 'Oficina de Swiss Medical Group';
        case 103:
          return 'Oficina Galicia';
        case 104:
          return 'Oficina Allianz';
      }
      
      return 'Ubicación Desconocida ($locationId)';
    }
  }

  /// Obtiene el nombre de la ubicación desde el location_type del backend
  String _getLocationDisplayNameFromBackendType(int backendLocationTypeId) {
    if (backendLocationTypeId == LocationTypes.REMOTE_DECLARED) {
      return userDeclaredAddress?.isNotEmpty == true 
          ? userDeclaredAddress! 
          : 'Domicilio Declarado';
    } else if (backendLocationTypeId == LocationTypes.REMOTE_ALTERNATIVE) {
      return 'Domicilio Alternativo';
    } else {
      // Primero intentar con nombres hardcodeados para IDs del backend más comunes
      switch (backendLocationTypeId) {
        case 101:
          return 'Oficina ABSTI';
        case 102:
          return 'Oficina de Swiss Medical Group';
        case 103:
          return 'Oficina Galicia';
        case 104:
          return 'Oficina Allianz';
      }
      
      // Para tipos de catálogo, mapear al ID del catálogo
      final catalogId = _mapLocationTypeToCatalogId(backendLocationTypeId);
      if (catalogLocations != null) {
        try {
          final catalogLocation = catalogLocations!.firstWhere(
            (cat) => cat.id == catalogId,
          );
          return catalogLocation.name;
        } catch (e) {
          // Si no se encuentra en el catálogo
        }
      }
      return 'Ubicación Desconocida (Type: $backendLocationTypeId)';
    }
  }

  /// Formatea el tiempo de una entrada del historial de ubicaciones
  String _formatLocationTime(Map<String, dynamic> location) {
    try {
      // Priorizar el start_time (horario elegido por usuario) sobre timestamp del servidor
      final timeValue = location['start_time'] ?? location['timestamp'] ?? location['time'] ?? location['created_at'];
      
      if (timeValue == null) return 'Hora no disponible';
      
      DateTime dateTime;
      
      // Parsing del timestamp
      if (timeValue is String) {
        // Si contiene 'T', es formato ISO (UTC)
        if (timeValue.contains('T')) {
          dateTime = DateTime.parse(timeValue).toLocal(); // ⭐ CONVERTIR A HORA LOCAL
        } else {
          // Asumir que es solo hora en formato HH:mm:ss (ya está en hora local)
          final today = DateTime.now();
          final timeParts = timeValue.split(':');
          if (timeParts.length >= 2) {
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            dateTime = DateTime(today.year, today.month, today.day, hour, minute);
          } else {
            return 'Formato de hora inválido';
          }
        }
      } else {
        return 'Tipo de hora inválido';
      }
      
      // Formatear a hora local (mostrar el horario que eligió el usuario)
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      
    } catch (e) {
      print('Error formateando tiempo de ubicación: $e');
      return 'Error en horario';
    }
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
                            : 'No estás trabajando',
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
              // Selector de ubicación renovado con catálogos
              _buildNewLocationSelector(context),
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
              if ((isWorking || dayCompleted) && locationHistory != null && locationHistory!.isNotEmpty) ...[
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
                                      color: location['is_planned'] == true
                                        ? Colors.purple.shade600 // Color para ubicaciones planificadas
                                        : location['event'] == 'check_in' 
                                          ? Colors.green.shade600
                                          : location['event'] == 'check_out'
                                            ? Colors.red.shade600
                                            : Colors.orange.shade600,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (location['is_planned'] == true
                                            ? Colors.purple.shade600
                                            : location['event'] == 'check_in' 
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
                                        // Agregar información de horario
                                        if (location['timestamp'] != null || location['time'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              _formatLocationTime(location),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        
                                      ],
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildWorkingLocationMessage(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                          height: 1.2, // Menos espacio entre líneas normales
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Indicador de jornada completa - OCULTO POR SOLICITUD DEL USUARIO
            // if (!isWorking && !dayCompleted && (userStartTime != null && userEndTime != null)) ...[
            //   Container(
            //     margin: const EdgeInsets.only(bottom: 12),
            //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //     decoration: BoxDecoration(
            //       color: _isWorkdayComplete(context) ? Colors.green.shade50 : Colors.orange.shade50,
            //       borderRadius: BorderRadius.circular(8),
            //       border: Border.all(
            //         color: _isWorkdayComplete(context) ? Colors.green.shade200 : Colors.orange.shade200,
            //       ),
            //     ),
            //     child: Row(
            //       children: [
            //         Icon(
            //           _isWorkdayComplete(context) ? Icons.check_circle : Icons.access_time,
            //           size: 16,
            //           color: _isWorkdayComplete(context) ? Colors.green.shade600 : Colors.orange.shade600,
            //         ),
            //         const SizedBox(width: 8),
            //         Expanded(
            //           child: Text(
            //             _getWorkdayStatusText(context),
            //             style: TextStyle(
            //               fontSize: 12,
            //               fontWeight: FontWeight.w500,
            //               color: _isWorkdayComplete(context) ? Colors.green.shade700 : Colors.orange.shade700,
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ],

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
                            // Iniciar directamente - el nuevo diálogo maneja las advertencias
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
