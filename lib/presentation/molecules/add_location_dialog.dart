import 'package:flutter/material.dart';
import '../../data/models/work_location.dart';
import '../../data/services/catalog_service.dart';
import '../../core/constants/location_types.dart';
import '../atoms/atoms.dart';
import 'address_search_field.dart';

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
  
  /// Ubicaciones ya seleccionadas (para evitar duplicados)
  final List<int> excludedLocationIds;

  const AddLocationDialog({
    super.key,
    this.catalogLocations,
    this.userDeclaredAddress,
    this.excludedLocationIds = const [],
  });

  /// Muestra el diálogo y retorna la ubicación adicional creada
  static Future<WorkLocation?> show({
    required BuildContext context,
    List<CatalogLocation>? catalogLocations,
    String? userDeclaredAddress,
    List<int> excludedLocationIds = const [],
  }) {
    return showDialog<WorkLocation>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddLocationDialog(
        catalogLocations: catalogLocations,
        userDeclaredAddress: userDeclaredAddress,
        excludedLocationIds: excludedLocationIds,
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

  /// Construye la lista de opciones de ubicación disponibles
  List<LocationOption> _buildAvailableOptions() {
    List<LocationOption> options = [];

    // Domicilio Declarado (siempre disponible si no está excluido)
    if (!widget.excludedLocationIds.contains(LocationTypes.REMOTE_DECLARED)) {
      options.add(LocationOption(
        id: LocationTypes.REMOTE_DECLARED,
        name: 'Domicilio Declarado',
        description: widget.userDeclaredAddress?.isNotEmpty == true 
            ? widget.userDeclaredAddress!
            : 'Trabajar desde domicilio registrado',
        source: LocationSource.declaredAddress,
      ));
    }

    // Domicilio Alternativo (solo si no está excluido)
    if (!widget.excludedLocationIds.contains(LocationTypes.REMOTE_ALTERNATIVE)) {
      options.add(LocationOption(
        id: LocationTypes.REMOTE_ALTERNATIVE,
        name: 'Domicilio Alternativo',
        description: 'Trabajar desde una dirección alternativa',
        source: LocationSource.alternativeAddress,
      ));
    }

    // Ubicaciones del catálogo (excluyendo las ya seleccionadas)
    if (widget.catalogLocations != null) {
      for (final catalogLocation in widget.catalogLocations!) {
        if (catalogLocation.isActive && 
            !widget.excludedLocationIds.contains(catalogLocation.id)) {
          options.add(LocationOption(
            id: catalogLocation.id,
            name: catalogLocation.name,
            description: catalogLocation.description ?? catalogLocation.address,
            source: LocationSource.catalog,
            address: catalogLocation.address,
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
        // Ubicación del catálogo
        final catalogLocation = widget.catalogLocations?.firstWhere(
          (cat) => cat.id == _selectedLocationId!,
          orElse: () => CatalogLocation(id: _selectedLocationId!, name: 'Ubicación', isActive: true),
        );
        return catalogLocation?.name ?? 'Ubicación del catálogo';
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

  /// Crea la WorkLocation con los datos ingresados
  WorkLocation _createWorkLocation() {
    return WorkLocation(
      locationTypeId: _selectedLocationId!,
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
