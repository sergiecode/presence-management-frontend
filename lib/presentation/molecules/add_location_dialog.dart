import 'package:flutter/material.dart';
import '../../data/models/work_location.dart';
import '../../data/services/catalog_service.dart';
import '../../core/constants/location_types.dart';
import '../atoms/atoms.dart';
import 'address_search_field.dart';

/// Tipos de sugerencias para resolver conflictos de horarios
enum SuggestionType {
  modifyExisting,    // Modificar ubicación existente
  rescheduleNew,     // Reprogramar nueva ubicación
  splitExisting,     // Dividir ubicación existente
}

/// Análisis de conflictos de horarios
class ScheduleConflictAnalysis {
  final bool hasConflict;
  final WorkLocation? conflictingLocation;
  final TimeOfDay? newLocationStart;
  final TimeOfDay? newLocationEnd;
  final List<ScheduleSuggestion> suggestions;

  ScheduleConflictAnalysis({
    required this.hasConflict,
    this.conflictingLocation,
    this.newLocationStart,
    this.newLocationEnd,
    this.suggestions = const [],
  });
}

/// Sugerencia para resolver conflicto de horarios
class ScheduleSuggestion {
  final SuggestionType type;
  final String description;
  final WorkLocation? modifiedLocation;
  final TimeOfDay? newStartTime;
  final TimeOfDay? newEndTime;
  final bool needsAdditionalLocation;
  final TimeOfDay? additionalLocationStart;
  final TimeOfDay? additionalLocationEnd;

  ScheduleSuggestion({
    required this.type,
    required this.description,
    this.modifiedLocation,
    this.newStartTime,
    this.newEndTime,
    this.needsAdditionalLocation = false,
    this.additionalLocationStart,
    this.additionalLocationEnd,
  });
}

/// **MOLÉCULA: Diálogo para agregar ubicación adicional**
///
/// Diálogo que permite al usuario agregar una nueva ubicación
/// a su jornada laboral con horarios específicos.
///
/// **Características:**
/// - Selección de ubicación (catálogo, domicilio alternativo)
/// - Configuración de horarios de inicio y fin
/// - Validación de horarios
/// - Integración con ubicaciones del catálogo
class AddLocationDialog extends StatefulWidget {
  /// Ubicaciones del catálogo disponibles
  final List<CatalogLocation>? catalogLocations;
  
  /// Dirección del domicilio declarado del usuario
  final String? userDeclaredAddress;
  
  /// Ubicaciones adicionales existentes (para validar solapamientos de horarios)
  final List<WorkLocation> existingLocations;

  const AddLocationDialog({
    super.key,
    this.catalogLocations,
    this.userDeclaredAddress,
    this.existingLocations = const [],
  });

  /// Muestra el diálogo y retorna la ubicación adicional creada
  static Future<WorkLocation?> show({
    required BuildContext context,
    List<CatalogLocation>? catalogLocations,
    String? userDeclaredAddress,
    List<WorkLocation> existingLocations = const [],
  }) {
    return showDialog<WorkLocation>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddLocationDialog(
        catalogLocations: catalogLocations,
        userDeclaredAddress: userDeclaredAddress,
        existingLocations: existingLocations,
      ),
    );
  }

  @override
  State<AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  int? _selectedLocationId;
  TimeOfDay _startTime = TimeOfDay(hour: DateTime.now().hour + 1, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: DateTime.now().hour + 2, minute: 0);
  
  // Campos para domicilio alternativo
  String? _alternativeAddress;
  String? _alternativeFloor;
  String? _alternativeApartment;

  /// Mapea el ID del catálogo al location_type que espera el backend
  int _mapCatalogIdToLocationType(int catalogId) {
    switch (catalogId) {
      case 1: return 101; // Oficina ABSTI
      case 2: return 102; // Swiss Medical
      case 3: return 104; // Allianz (103 era Galicia)
      case 4: return 103; // Galicia (104 era Allianz)
      default: return catalogId + 100; // Fallback genérico
    }
  }

  /// Convierte el ID de la UI al location_type que espera el backend
  int _getLocationTypeForBackend(int uiId) {
    if (uiId == LocationTypes.REMOTE_DECLARED || uiId == LocationTypes.REMOTE_ALTERNATIVE) {
      return uiId; // Los tipos básicos van directo
    }
    
    // Para ubicaciones del catálogo, buscar el catalog ID y mapearlo
    if (uiId >= 1000 && widget.catalogLocations != null) {
      final catalogIndex = uiId - 1000;
      final activeLocations = widget.catalogLocations!.where((loc) => loc.isActive).toList();
      if (catalogIndex < activeLocations.length) {
        final catalogLocation = activeLocations[catalogIndex];
        return _mapCatalogIdToLocationType(catalogLocation.id);
      }
    }
    
    return uiId; // Fallback
  }

  /// Construye la lista de opciones de ubicación disponibles
  List<LocationOption> _buildAvailableOptions() {
    List<LocationOption> options = [];

    // Domicilio Declarado (siempre disponible - CAMBIO: ya no verificar excludedLocationIds)
    options.add(LocationOption(
      id: LocationTypes.REMOTE_DECLARED,
      name: 'Domicilio Declarado',
      description: widget.userDeclaredAddress?.isNotEmpty == true 
          ? widget.userDeclaredAddress!
          : 'Trabajar desde domicilio registrado',
      source: LocationSource.declaredAddress,
    ));

    // Domicilio Alternativo (siempre disponible - CAMBIO: ya no verificar excludedLocationIds)
    options.add(LocationOption(
      id: LocationTypes.REMOTE_ALTERNATIVE,
      name: 'Domicilio Alternativo',
      description: 'Trabajar desde una dirección alternativa',
      source: LocationSource.alternativeAddress,
    ));

    // Ubicaciones del catálogo - usar IDs únicos empezando desde 1000
    if (widget.catalogLocations != null) {
      int uiIdCounter = 1000;
      for (final catalogLocation in widget.catalogLocations!) {
        if (catalogLocation.isActive) {
          options.add(LocationOption(
            id: uiIdCounter++, // ID único: 1000, 1001, 1002, 1003
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

  /// Construye el location_detail basado en la ubicación seleccionada
  String _buildLocationDetail() {
    if (_selectedLocationId == null) return '';

    switch (_selectedLocationId!) {
      case LocationTypes.REMOTE_DECLARED:
        return widget.userDeclaredAddress ?? 'Domicilio Declarado';
      
      case LocationTypes.REMOTE_ALTERNATIVE:
        String detail = _alternativeAddress ?? '';
        if (_alternativeFloor?.isNotEmpty == true) {
          detail += ', Piso $_alternativeFloor';
        }
        if (_alternativeApartment?.isNotEmpty == true) {
          detail += ', Dpto $_alternativeApartment';
        }
        return detail;
      
      default:
        // Ubicación del catálogo - buscar por UI ID
        if (_selectedLocationId! >= 1000 && widget.catalogLocations != null) {
          final catalogIndex = _selectedLocationId! - 1000;
          final activeLocations = widget.catalogLocations!.where((loc) => loc.isActive).toList();
          if (catalogIndex < activeLocations.length) {
            return activeLocations[catalogIndex].name;
          }
        }
        return 'Ubicación del catálogo';
    }
  }

  /// Valida que los datos ingresados sean correctos
  bool _validateForm() {
    if (_selectedLocationId == null) {
      _showError('Selecciona una ubicación');
      return false;
    }

    if (_selectedLocationId == LocationTypes.REMOTE_ALTERNATIVE &&
        (_alternativeAddress?.isEmpty ?? true)) {
      _showError('Ingresa la dirección del domicilio alternativo');
      return false;
    }

    // Validar que el horario de fin sea después del de inicio
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    if (endMinutes <= startMinutes) {
      _showError('La hora de fin debe ser posterior a la de inicio');
      return false;
    }

    // Validar que los horarios no estén en el pasado
    if (!_validateTimeNotInPast()) {
      return false;
    }

    // Validar que no haya solapamiento con ubicaciones existentes
    if (!_validateNoTimeOverlap()) {
      return false;
    }

    return true;
  }

  /// Valida que los horarios no estén en el pasado
  bool _validateTimeNotInPast() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final startDateTime = DateTime(
      today.year,
      today.month, 
      today.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    if (startDateTime.isBefore(now)) {
      _showError('La hora de inicio no puede ser en el pasado');
      return false;
    }
    
    return true;
  }

  /// Valida que no haya solapamiento de horarios con ubicaciones existentes
  bool _validateNoTimeOverlap() {
    final result = _analyzeTimeConflicts();
    
    if (result.hasConflict) {
      _showScheduleSuggestion(result);
      return false;
    }
    
    return true;
  }

  /// Analiza conflictos de horarios y genera sugerencias
  ScheduleConflictAnalysis _analyzeTimeConflicts() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    print('DEBUG AddLocationDialog: Analizando conflictos...');
    print('  - Nueva ubicación: ${_startTime.format(context)} - ${_endTime.format(context)} ($startMinutes - $endMinutes minutos)');
    print('  - Ubicaciones existentes para validar: ${widget.existingLocations.length}');

    for (int i = 0; i < widget.existingLocations.length; i++) {
      final existingLocation = widget.existingLocations[i];
      print('  - Existente $i: ID ${existingLocation.locationTypeId}, ${existingLocation.startTime.format(context)} - ${existingLocation.endTime?.format(context) ?? "Sin fin"}');
      
      final existingStartMinutes = existingLocation.startTime.hour * 60 + existingLocation.startTime.minute;
      final existingEndMinutes = existingLocation.endTime != null 
          ? (existingLocation.endTime!.hour * 60 + existingLocation.endTime!.minute)
          : null;
      
      // Si la ubicación existente no tiene hora de fin, consideramos que va hasta el final del día
      final effectiveEndMinutes = existingEndMinutes ?? (23 * 60 + 59);
      
      print('    Minutos existentes: $existingStartMinutes - $effectiveEndMinutes');
      
      // Verificar solapamiento
      bool hasOverlap = (startMinutes < effectiveEndMinutes) && (endMinutes > existingStartMinutes);
      
      print('    ¿Hay solapamiento? $hasOverlap');
      print('    Lógica: ($startMinutes < $effectiveEndMinutes) && ($endMinutes > $existingStartMinutes)');
      print('           ${startMinutes < effectiveEndMinutes} && ${endMinutes > existingStartMinutes}');
      
      if (hasOverlap) {
        print('  *** CONFLICTO DETECTADO ***');
        return ScheduleConflictAnalysis(
          hasConflict: true,
          conflictingLocation: existingLocation,
          newLocationStart: _startTime,
          newLocationEnd: _endTime,
          suggestions: _generateScheduleSuggestions(existingLocation),
        );
      }
    }
    
    print('  - No se detectaron conflictos');
    return ScheduleConflictAnalysis(hasConflict: false);
  }

  /// Genera sugerencias para resolver conflictos de horarios
  List<ScheduleSuggestion> _generateScheduleSuggestions(WorkLocation conflictingLocation) {
    print('DEBUG: Generando sugerencias para resolver conflicto...');
    
    final suggestions = <ScheduleSuggestion>[];
    final newStart = _startTime.hour * 60 + _startTime.minute;
    final newEnd = _endTime.hour * 60 + _endTime.minute;
    final existingStart = conflictingLocation.startTime.hour * 60 + conflictingLocation.startTime.minute;
    final existingEnd = conflictingLocation.endTime != null
        ? (conflictingLocation.endTime!.hour * 60 + conflictingLocation.endTime!.minute)
        : (17 * 60); // Default 5 PM si no hay hora de fin

    final conflictingLocationName = _getLocationNameById(conflictingLocation.locationTypeId);

    print('  - Nueva ubicación: $newStart - $newEnd minutos');
    print('  - Ubicación existente ($conflictingLocationName): $existingStart - $existingEnd minutos');

    // Sugerencia 1: Ajustar ubicación existente para que termine antes
    if (newStart < existingEnd && newStart > existingStart) {
      final suggestedEndTime = TimeOfDay(
        hour: (newStart - 1) ~/ 60,
        minute: (newStart - 1) % 60,
      );
      
      final suggestion = ScheduleSuggestion(
        type: SuggestionType.modifyExisting,
        description: 'Modificar $conflictingLocationName para que termine a las ${suggestedEndTime.format(context)}',
        modifiedLocation: conflictingLocation,
        newStartTime: conflictingLocation.startTime,
        newEndTime: suggestedEndTime,
        needsAdditionalLocation: newEnd > existingEnd,
        additionalLocationStart: newEnd > existingEnd ? _timeFromMinutes(existingEnd) : null,
      );
      
      suggestions.add(suggestion);
      print('  + Sugerencia 1: ${suggestion.description}');
    }

    // Sugerencia 2: Dividir la ubicación existente
    if (newStart > existingStart && newEnd < existingEnd) {
      final suggestion = ScheduleSuggestion(
        type: SuggestionType.splitExisting,
        description: 'Dividir $conflictingLocationName en dos períodos: antes y después de la nueva ubicación',
        modifiedLocation: conflictingLocation,
        newStartTime: conflictingLocation.startTime,
        newEndTime: TimeOfDay(hour: (newStart - 1) ~/ 60, minute: (newStart - 1) % 60),
        needsAdditionalLocation: true,
        additionalLocationStart: TimeOfDay(hour: (newEnd + 1) ~/ 60, minute: (newEnd + 1) % 60),
        additionalLocationEnd: conflictingLocation.endTime,
      );
      
      suggestions.add(suggestion);
      print('  + Sugerencia 2: ${suggestion.description}');
    }

    // Sugerencia 3: Programar nueva ubicación después
    final nextAvailableSlot = existingEnd + 1;
    if (nextAvailableSlot < 18 * 60) { // Antes de las 6 PM
      final suggestedStartTime = _timeFromMinutes(nextAvailableSlot);
      final duration = newEnd - newStart;
      final suggestedEndTime = _timeFromMinutes(nextAvailableSlot + duration);
      
      final suggestion = ScheduleSuggestion(
        type: SuggestionType.rescheduleNew,
        description: 'Programar nueva ubicación después de $conflictingLocationName (${suggestedStartTime.format(context)} - ${suggestedEndTime.format(context)})',
        newStartTime: suggestedStartTime,
        newEndTime: suggestedEndTime,
      );
      
      suggestions.add(suggestion);
      print('  + Sugerencia 3: ${suggestion.description}');
    }

    print('  - Total sugerencias generadas: ${suggestions.length}');
    return suggestions;
  }

  TimeOfDay _timeFromMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return TimeOfDay(hour: hours.clamp(0, 23), minute: minutes.clamp(0, 59));
  }

  /// Muestra diálogo con sugerencias para resolver conflictos
  void _showScheduleSuggestion(ScheduleConflictAnalysis analysis) {
    final conflictingLocationName = _getLocationNameById(analysis.conflictingLocation!.locationTypeId);
    final conflictingTimeRange = analysis.conflictingLocation!.endTime != null
        ? '${analysis.conflictingLocation!.startTime.format(context)} - ${analysis.conflictingLocation!.endTime!.format(context)}'
        : 'desde ${analysis.conflictingLocation!.startTime.format(context)}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Expanded(child: Text('Conflicto de Horarios')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El horario seleccionado (${_startTime.format(context)} - ${_endTime.format(context)}) se solapa con:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                '$conflictingLocationName\n$conflictingTimeRange',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sugerencias para resolver el conflicto:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...analysis.suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, 
                      color: Colors.blue.shade600, 
                      size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion.description,
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Modificar Manualmente'),
          ),
        ],
      ),
    );
  }

  /// Obtiene el nombre de una ubicación por su ID
  String _getLocationNameById(int locationId) {
    print('DEBUG: _getLocationNameById called with locationId: $locationId');
    
    // Primero verificar si es un tipo de ubicación especial (1-4)
    switch (locationId) {
      case LocationTypes.REMOTE_DECLARED:
        print('DEBUG: Mapped to Domicilio Declarado');
        return 'Domicilio Declarado';
      case LocationTypes.REMOTE_ALTERNATIVE:
        print('DEBUG: Mapped to Domicilio Alternativo');
        return 'Domicilio Alternativo';
      case LocationTypes.CLIENT:
        print('DEBUG: Mapped to Cliente');
        return 'Cliente';
      case LocationTypes.OFFICE:
        print('DEBUG: Mapped to Oficina');
        return 'Oficina';
    }
    
    // Si no es un tipo especial, buscar en ubicaciones del catálogo
    if (widget.catalogLocations != null) {
      print('DEBUG: Searching in catalogLocations, count: ${widget.catalogLocations!.length}');
      for (var loc in widget.catalogLocations!) {
        print('  - Catalog location: id=${loc.id}, name="${loc.name}"');
      }
      
      final catalogLocation = widget.catalogLocations!.firstWhere(
        (loc) => loc.id == locationId,
        orElse: () => CatalogLocation(id: -1, name: '', description: '', isActive: false),
      );
      if (catalogLocation.id != -1) {
        print('DEBUG: Found in catalog: ${catalogLocation.name}');
        return catalogLocation.name;
      }
    } else {
      print('DEBUG: catalogLocations is null');
    }
    
    // Fallback para IDs desconocidos
    print('DEBUG: Using fallback name for locationId: $locationId');
    return 'Ubicación #$locationId';
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

  /// Crea la WorkLocation con los datos ingresados
  WorkLocation _createWorkLocation() {
    return WorkLocation(
      locationTypeId: _getLocationTypeForBackend(_selectedLocationId!), // Usar el mapeo correcto para backend
      locationDetail: _buildLocationDetail(),
      startTime: _startTime,
      endTime: _endTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableOptions = _buildAvailableOptions();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Icon(Icons.add_location_alt, color: const Color(0xFFE67D21)),
                const SizedBox(width: 12),
                const Text(
                  'Agregar ubicación adicional',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Selector de ubicación
            const Text(
              'Ubicación:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedLocationId,
                  hint: const Text('Selecciona una ubicación'),
                  isExpanded: true,
                  onChanged: (int? value) {
                    setState(() {
                      _selectedLocationId = value;
                      // Limpiar campos de domicilio alternativo al cambiar
                      if (value != LocationTypes.REMOTE_ALTERNATIVE) {
                        _alternativeAddress = null;
                        _alternativeFloor = null;
                        _alternativeApartment = null;
                      }
                    });
                  },
                  items: availableOptions.map((option) {
                    return DropdownMenuItem<int>(
                      value: option.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(option.displayName),
                          if (option.description != null)
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

            // Campos para domicilio alternativo
            if (_selectedLocationId == LocationTypes.REMOTE_ALTERNATIVE) ...[
              const SizedBox(height: 16),
              AddressSearchField(
                onAddressSelected: (address) {
                  setState(() {
                    _alternativeAddress = address;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Piso (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: 3°',
                      ),
                      onChanged: (value) {
                        _alternativeFloor = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Dpto (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: A, 201',
                      ),
                      onChanged: (value) {
                        _alternativeApartment = value;
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Configuración de horarios
            const Text(
              'Horarios:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Desde:', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Text(_startTime.format(context)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hasta:', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Text(_endTime.format(context)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Botones
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(),
                    type: ButtonType.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Agregar',
                    onPressed: () {
                      if (_validateForm()) {
                        final workLocation = _createWorkLocation();
                        Navigator.of(context).pop(workLocation);
                      }
                    },
                    type: ButtonType.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
