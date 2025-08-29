import 'package:flutter/material.dart';
import '../../core/constants/location_types.dart';
import '../molecules/address_search_field.dart';
import '../../data/models/work_location.dart';
import '../../data/services/catalog_service.dart';

/// Diálogo para cambiar ubicación durante la jornada laboral
class LocationChangeDialog extends StatefulWidget {
  /// Ubicaciones del catálogo disponibles
  final List<CatalogLocation> catalogLocations;
  
  /// Dirección del domicilio declarado del usuario
  final String? userDeclaredAddress;
  
  /// Lista de ubicaciones actualmente seleccionadas (para excluir)
  final List<int> currentLocations;
  
  /// Callback que se ejecuta cuando se selecciona una nueva ubicación
  final Function(WorkLocation) onLocationSelected;

  const LocationChangeDialog({
    super.key,
    required this.catalogLocations,
    this.userDeclaredAddress,
    required this.currentLocations,
    required this.onLocationSelected,
  });

  @override
  State<LocationChangeDialog> createState() => _LocationChangeDialogState();
}

class _LocationChangeDialogState extends State<LocationChangeDialog> {
  int? _selectedLocationId;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _endTime;
  String _alternativeAddress = '';
  String _alternativeFloor = '';
  String _alternativeApartment = '';

  // Lista de opciones disponibles (excluyendo las ya seleccionadas)
  List<Map<String, dynamic>> get _availableOptions {
    List<Map<String, dynamic>> options = [];
    
    // Domicilio Declarado (si está disponible)
    if (widget.userDeclaredAddress != null && 
        !widget.currentLocations.contains(LocationTypes.REMOTE_DECLARED)) {
      options.add({
        'id': LocationTypes.REMOTE_DECLARED,
        'name': 'Domicilio Declarado',
        'address': widget.userDeclaredAddress,
        'isBuiltIn': true,
      });
    }
    
    // Domicilio Alternativo
    if (!widget.currentLocations.contains(LocationTypes.REMOTE_ALTERNATIVE)) {
      options.add({
        'id': LocationTypes.REMOTE_ALTERNATIVE,
        'name': 'Domicilio Alternativo',
        'address': 'Dirección a especificar',
        'isBuiltIn': true,
      });
    }
    
    // Ubicaciones del catálogo (excluyendo las ya seleccionadas)
    for (final catalogLocation in widget.catalogLocations) {
      if (!widget.currentLocations.contains(catalogLocation.id)) {
        options.add({
          'id': catalogLocation.id,
          'name': catalogLocation.name,
          'address': catalogLocation.address ?? 'Dirección no especificada',
          'isBuiltIn': false,
        });
      }
    }
    
    return options;
  }

  void _handleLocationChange() {
    if (_selectedLocationId == null) return;
    
    String locationDetail = '';
    
    if (_selectedLocationId == LocationTypes.REMOTE_DECLARED) {
      locationDetail = widget.userDeclaredAddress ?? '';
    } else if (_selectedLocationId == LocationTypes.REMOTE_ALTERNATIVE) {
      final addressParts = <String>[
        _alternativeAddress.trim(),
        if (_alternativeFloor.isNotEmpty) 'Piso ${_alternativeFloor.trim()}',
        if (_alternativeApartment.isNotEmpty) 'Dpto ${_alternativeApartment.trim()}',
      ].where((part) => part.isNotEmpty);
      locationDetail = addressParts.join(', '); // Usar ', ' para consistencia con el resto del código
    } else {
      // Buscar en catálogo
      final catalogLocation = widget.catalogLocations.firstWhere(
        (cat) => cat.id == _selectedLocationId,
        orElse: () => CatalogLocation(
          id: _selectedLocationId!,
          name: 'Ubicación $_selectedLocationId',
          address: '',
          isActive: true,
        ),
      );
      locationDetail = catalogLocation.name;
    }
    
    final workLocation = WorkLocation(
      locationTypeId: _selectedLocationId!,
      locationDetail: locationDetail,
      startTime: _startTime,
      endTime: _endTime,
    );
    
    widget.onLocationSelected(workLocation);
  }

  Widget _buildAvailableOptions() {
    final options = _availableOptions;
    
    if (options.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No hay ubicaciones adicionales disponibles',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Column(
      children: options.map((option) {
        final isSelected = _selectedLocationId == option['id'];
        
        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Colors.blue.shade50 : null,
          child: RadioListTile<int>(
            value: option['id'],
            groupValue: _selectedLocationId,
            onChanged: (value) {
              setState(() {
                _selectedLocationId = value;
              });
            },
            title: Text(
              option['name'],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade800 : null,
              ),
            ),
            subtitle: Text(option['address'] ?? ''),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Cambiar Ubicación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Selecciona una nueva ubicación para continuar trabajando:',
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 16),
            
            // Lista de ubicaciones disponibles
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildAvailableOptions(),
                    const SizedBox(height: 16),
                    
                    // Campo de dirección alternativa si está seleccionada
                    if (_selectedLocationId == LocationTypes.REMOTE_ALTERNATIVE) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      AddressSearchField(
                        onAddressSelected: (address) {
                          setState(() {
                            _alternativeAddress = address;
                          });
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Selectores de tiempo
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Horario',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Hora de inicio
                            Row(
                              children: [
                                const Text('Desde: '),
                                TextButton(
                                  onPressed: () async {
                                    final newTime = await showTimePicker(
                                      context: context,
                                      initialTime: _startTime,
                                    );
                                    if (newTime != null) {
                                      setState(() {
                                        _startTime = newTime;
                                      });
                                    }
                                  },
                                  child: Text(
                                    _startTime.format(context),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Hora de fin (opcional)
                            Row(
                              children: [
                                const Text('Hasta: '),
                                TextButton(
                                  onPressed: () async {
                                    final newTime = await showTimePicker(
                                      context: context,
                                      initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
                                    );
                                    setState(() {
                                      _endTime = newTime;
                                    });
                                  },
                                  child: Text(
                                    _endTime?.format(context) ?? 'Fin de jornada',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                if (_endTime != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _endTime = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _selectedLocationId != null ? () {
                    _handleLocationChange();
                    Navigator.of(context).pop();
                  } : null,
                  child: const Text('Cambiar Ubicación'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
