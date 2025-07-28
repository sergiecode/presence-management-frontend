import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/services/address_service.dart';

/// **MOLÉCULA: Campo de Búsqueda de Direcciones**
///
/// Componente que permite buscar direcciones usando una API de geocodificación
/// y mostrar sugerencias en tiempo real.
///
/// **Características:**
/// - Búsqueda en tiempo real con debounce
/// - Lista de sugerencias
/// - Selección de dirección completa
/// - Manejo de estados de carga y error
class AddressSearchField extends StatefulWidget {
  final bool enabled;
  final Function(String)? onAddressSelected;
  final String? initialValue;

  const AddressSearchField({
    super.key,
    this.enabled = true,
    this.onAddressSelected,
    this.initialValue,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _onTextChanged(String value) {
    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoading = false;
      });
      return;
    }

    // Establecer un nuevo timer con debounce de 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchAddresses(value.trim());
    });
  }

  Future<void> _searchAddresses(String query) async {
    if (!mounted || query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });

    try {
      final suggestions = await AddressService.searchAddresses(query);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        
        // Mostrar error discreto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Buscando direcciones sin conexión: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange.shade600,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  _searchAddresses(_controller.text.trim());
                }
              },
            ),
          ),
        );
      }
    }
  }

  void _onSuggestionSelected(Map<String, dynamic> suggestion) {
    final displayName = suggestion['display_name'] ?? suggestion['formatted'] ?? '';
    
    setState(() {
      _controller.text = displayName;
      _showSuggestions = false;
      _suggestions = [];
    });

    // Quitar el foco del campo
    _focusNode.unfocus();

    // Notificar al padre
    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(displayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: 'Buscar dirección',
            border: const OutlineInputBorder(),
            hintText: 'Escriba para buscar...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isLoading
                ? Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(12),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          onChanged: _onTextChanged,
          onTap: () {
            if (_suggestions.isNotEmpty) {
              setState(() {
                _showSuggestions = true;
              });
            }
          },
        ),

        // Lista de sugerencias
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                final displayName = suggestion['display_name'] ?? suggestion['formatted'] ?? 'Dirección no disponible';
                final source = suggestion['source'] ?? 'online';
                
                return ListTile(
                  dense: true,
                  leading: Icon(
                    source == 'local' ? Icons.home : Icons.location_on, 
                    size: 20,
                    color: source == 'local' ? Colors.orange : Colors.blue,
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: source == 'local' 
                    ? const Text(
                        'Sugerencia sin conexión',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      )
                    : null,
                  onTap: () => _onSuggestionSelected(suggestion),
                );
              },
            ),
          ),

        // Indicador de no resultados
        if (_showSuggestions && !_isLoading && _suggestions.isEmpty && _controller.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'No se encontraron direcciones',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
