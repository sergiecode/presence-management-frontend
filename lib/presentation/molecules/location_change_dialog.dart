import 'package:flutter/material.dart';
import '../../core/constants/location_types.dart';
import '../molecules/address_search_field.dart';

/// Diálogo para cambiar ubicación durante la jornada laboral
class LocationChangeDialog extends StatefulWidget {
  final List<int> currentLocations; // Cambio a lista para múltiples ubicaciones
  final Map<int, String> locations;
  final Function(int, {String? address, String? floor, String? apartment}) onLocationChanged;

  const LocationChangeDialog({
    super.key,
    required this.currentLocations,
    required this.locations,
    required this.onLocationChanged,
  });

  @override
  State<LocationChangeDialog> createState() => _LocationChangeDialogState();
}

class _LocationChangeDialogState extends State<LocationChangeDialog> {
  int? _selectedLocation;
  String _otherLocationDetail = '';
  String _otherLocationFloor = '';
  String _otherLocationApartment = '';

  @override
  void initState() {
    super.initState();
    // Inicializar con la primera ubicación de la lista como selección por defecto
    _selectedLocation = widget.currentLocations.isNotEmpty ? widget.currentLocations.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFFE67D21),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cambiar Ubicación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subtitle
            Text(
              'Selecciona tu nueva ubicación de trabajo:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),

            // Current locations info
            if (widget.currentLocations.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.currentLocations.length == 1 
                            ? 'Ubicación actual:' 
                            : 'Ubicaciones actuales:',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...widget.currentLocations.map((locationId) => Padding(
                      padding: const EdgeInsets.only(left: 28, top: 2),
                      child: Text(
                        '• ${widget.locations[locationId] ?? "No especificada"}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Location options
            ...widget.locations.entries.map((entry) {
              final id = entry.key;
              final name = entry.value;
              
              return Column(
                children: [
                  RadioListTile<int>(
                    value: id,
                    groupValue: _selectedLocation,
                    activeColor: const Color(0xFFE67D21),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                        // Limpiar campos cuando no es "Domicilio Alternativo"
                        if (value != LocationTypes.REMOTE_ALTERNATIVE) {
                          _otherLocationDetail = '';
                          _otherLocationFloor = '';
                          _otherLocationApartment = '';
                        }
                      });
                    },
                  ),
                  
                  // Mostrar campos adicionales si es "Domicilio Alternativo"
                  if (_selectedLocation == LocationTypes.REMOTE_ALTERNATIVE && id == LocationTypes.REMOTE_ALTERNATIVE) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 32, right: 16, bottom: 16),
                      child: Column(
                        children: [
                          // Campo de búsqueda de dirección
                          AddressSearchField(
                            onAddressSelected: (address) {
                              setState(() {
                                _otherLocationDetail = address;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Campos de Piso y Depto
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Piso (opcional)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _otherLocationFloor = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Depto (opcional)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _otherLocationApartment = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }).toList(),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedLocation != null && !widget.currentLocations.contains(_selectedLocation)
                      ? _handleLocationChange
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67D21),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cambiar Ubicación',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleLocationChange() {
    if (_selectedLocation == null) return;

    // Validar que si es "Domicilio Alternativo" tenga dirección
    if (_selectedLocation == LocationTypes.REMOTE_ALTERNATIVE && _otherLocationDetail.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una dirección para el domicilio alternativo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onLocationChanged(
      _selectedLocation!,
      address: _selectedLocation == LocationTypes.REMOTE_ALTERNATIVE ? _otherLocationDetail : null,
      floor: _selectedLocation == LocationTypes.REMOTE_ALTERNATIVE ? _otherLocationFloor : null,
      apartment: _selectedLocation == LocationTypes.REMOTE_ALTERNATIVE ? _otherLocationApartment : null,
    );

    Navigator.of(context).pop();
  }
}
