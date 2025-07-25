import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/network_utils.dart';

/// **SERVICIO: Búsqueda de Direcciones**
///
/// Servicio que se conecta a múltiples APIs de geocodificación
/// para buscar direcciones con respaldos en caso de fallas.
///
/// **Funcionalidades:**
/// - Búsqueda de direcciones por texto
/// - APIs de respaldo (Nominatim, Photon)
/// - Geocodificación (dirección -> coordenadas)
/// - Geocodificación inversa (coordenadas -> dirección)
/// - Manejo de errores y rate limiting
class AddressService {
  // API primaria - Nominatim (OpenStreetMap)
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  
  // API de respaldo - Photon
  static const String _photonUrl = 'https://photon.komoot.io';
  
  static const String _userAgent = 'PresenceManagementApp/1.0';

  /// Busca direcciones usando múltiples APIs con respaldo
  static Future<List<Map<String, dynamic>>> searchAddresses(String query) async {
    print('� AddressService: Iniciando búsqueda para "$query"');
    
    // Intentar con Nominatim primero (sin verificar conexión previamente)
    try {
      print('🔍 AddressService: Intentando con Nominatim...');
      return await _searchWithNominatim(query);
    } catch (e) {
      print('⚠️ AddressService: Nominatim falló: $e');
      
      // Si Nominatim falla, intentar con Photon
      try {
        print('🔍 AddressService: Intentando con Photon como respaldo...');
        return await _searchWithPhoton(query);
      } catch (e2) {
        print('❌ AddressService: Todas las APIs fallaron');
        print('❌ Nominatim: $e');
        print('❌ Photon: $e2');
        
        // Solo ejecutar diagnósticos si todas las APIs fallan
        _runNetworkDiagnosticsAsync();
        
        // Si todas fallan, devolver respuestas locales/mock
        print('🏠 AddressService: Usando sugerencias locales para "$query"');
        return _getLocalSuggestions(query);
      }
    }
  }

  /// Ejecuta diagnósticos de red de forma asíncrona (no bloquea la UI)
  static void _runNetworkDiagnosticsAsync() {
    NetworkUtils.runNetworkDiagnostics().then((diagnostics) {
      print('🔍 AddressService: Diagnósticos de red: $diagnostics');
    }).catchError((e) {
      print('❌ AddressService: Error en diagnósticos: $e');
    });
  }

  /// Busca direcciones usando la API de Nominatim
  static Future<List<Map<String, dynamic>>> _searchWithNominatim(String query) async {
    final uri = Uri.parse('$_nominatimUrl/search').replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
        'countrycodes': 'ar',
        'accept-language': 'es',
      },
    );

    print('🌐 AddressService: URL Nominatim: $uri');

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
      },
    ).timeout(const Duration(seconds: 8)); // Aumentar timeout

    print('📡 AddressService: Nominatim Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ AddressService: Nominatim - ${data.length} direcciones');

      return data.map((item) => {
        'display_name': item['display_name'],
        'formatted': _formatAddress(item),
        'lat': item['lat'],
        'lon': item['lon'],
        'address': item['address'] ?? {},
        'source': 'nominatim',
      }).toList();
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit - demasiadas solicitudes');
    } else {
      throw Exception('Error HTTP ${response.statusCode}');
    }
  }

  /// Busca direcciones usando la API de Photon
  static Future<List<Map<String, dynamic>>> _searchWithPhoton(String query) async {
    final uri = Uri.parse('$_photonUrl/api').replace(
      queryParameters: {
        'q': query,
        'limit': '5',
        'lang': 'es',
      },
    );

    print('🌐 AddressService: URL Photon: $uri');

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 8));

    print('📡 AddressService: Photon Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> features = data['features'] ?? [];
      
      print('✅ AddressService: Photon - ${features.length} direcciones');

      return features.map((feature) {
        final properties = feature['properties'] ?? {};
        final geometry = feature['geometry'] ?? {};
        final coordinates = geometry['coordinates'] ?? [];
        
        return {
          'display_name': properties['name'] ?? properties['street'] ?? 'Dirección',
          'formatted': _formatPhotonAddress(properties),
          'lat': coordinates.length > 1 ? coordinates[1].toString() : '0',
          'lon': coordinates.length > 0 ? coordinates[0].toString() : '0',
          'address': properties,
          'source': 'photon',
        };
      }).toList();
    } else {
      throw Exception('Error HTTP ${response.statusCode}');
    }
  }

  /// Obtiene sugerencias locales cuando las APIs fallan
  static List<Map<String, dynamic>> _getLocalSuggestions(String query) {
    print('🏠 AddressService: Usando sugerencias locales para "$query"');
    
    final suggestions = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();

    // Sugerencias basadas en ubicaciones comunes de Argentina
    final commonPlaces = [
      // Buenos Aires - Avenidas principales
      'Av. Corrientes, Buenos Aires',
      'Av. 9 de Julio, Buenos Aires', 
      'Av. Santa Fe, Buenos Aires',
      'Av. Rivadavia, Buenos Aires',
      'Av. Cabildo, Buenos Aires',
      'Av. Juan B. Justo, Buenos Aires',
      
      // Buenos Aires - Barrios
      'Plaza de Mayo, Buenos Aires',
      'Puerto Madero, Buenos Aires',
      'Palermo, Buenos Aires',
      'Recoleta, Buenos Aires',
      'San Telmo, Buenos Aires',
      'Belgrano, Buenos Aires',
      'Villa Crespo, Buenos Aires',
      'Caballito, Buenos Aires',
      'Barracas, Buenos Aires',
      'La Boca, Buenos Aires',
      
      // GBA - Zona Oeste
      'Morón, Buenos Aires',
      'Hurlingham, Buenos Aires', 
      'Ituzaingó, Buenos Aires',
      'Merlo, Buenos Aires',
      'Moreno, Buenos Aires',
      'Tres de Febrero, Buenos Aires',
      'San Martín, Buenos Aires',
      'Vicente López, Buenos Aires',
      
      // GBA - Zona Norte
      'San Isidro, Buenos Aires',
      'Tigre, Buenos Aires',
      'San Fernando, Buenos Aires',
      'Olivos, Buenos Aires',
      'Martínez, Buenos Aires',
      'Acassuso, Buenos Aires',
      
      // GBA - Zona Sur
      'Avellaneda, Buenos Aires',
      'Quilmes, Buenos Aires',
      'Berazategui, Buenos Aires',
      'Florencio Varela, Buenos Aires',
      'Almirante Brown, Buenos Aires',
      'Lomas de Zamora, Buenos Aires',
      
      // Otras provincias importantes
      'Córdoba, Córdoba',
      'Rosario, Santa Fe',
      'La Plata, Buenos Aires',
      'Mendoza, Mendoza',
      'Tucumán, Tucumán',
      'Mar del Plata, Buenos Aires',
    ];

    // Filtrar sugerencias relevantes
    for (final place in commonPlaces) {
      final placeLower = place.toLowerCase();
      
      // Buscar coincidencias exactas o parciales
      if (placeLower.contains(queryLower) || 
          queryLower.split(' ').any((word) => 
            word.length > 2 && placeLower.contains(word))) {
        suggestions.add({
          'display_name': place,
          'formatted': place,
          'lat': _getCoordinatesForPlace(place)['lat']!,
          'lon': _getCoordinatesForPlace(place)['lon']!,
          'address': {
            'city': place.split(', ').length > 1 ? place.split(', ')[1] : 'Buenos Aires', 
            'country': 'Argentina'
          },
          'source': 'local',
        });
        
        // Limitar a 5 sugerencias
        if (suggestions.length >= 5) break;
      }
    }

    // Si no hay coincidencias, agregar sugerencia genérica
    if (suggestions.isEmpty) {
      suggestions.add({
        'display_name': '$query (búsqueda sin conexión)',
        'formatted': query,
        'lat': '-34.6037',
        'lon': '-58.3816',
        'address': {'search_term': query, 'country': 'Argentina'},
        'source': 'local',
      });
    }

    print('🏠 AddressService: ${suggestions.length} sugerencias locales encontradas');
    return suggestions;
  }

  /// Obtiene coordenadas aproximadas para lugares conocidos
  static Map<String, String> _getCoordinatesForPlace(String place) {
    final placeLower = place.toLowerCase();
    
    // Coordenadas aproximadas para diferentes zonas
    if (placeLower.contains('morón')) {
      return {'lat': '-34.6532', 'lon': '-58.6198'};
    } else if (placeLower.contains('palermo')) {
      return {'lat': '-34.5772', 'lon': '-58.4125'};
    } else if (placeLower.contains('recoleta')) {
      return {'lat': '-34.5875', 'lon': '-58.3974'};
    } else if (placeLower.contains('tigre')) {
      return {'lat': '-34.4264', 'lon': '-58.5799'};
    } else if (placeLower.contains('córdoba')) {
      return {'lat': '-31.4201', 'lon': '-64.1888'};
    } else if (placeLower.contains('rosario')) {
      return {'lat': '-32.9442', 'lon': '-60.6505'};
    } else {
      // Coordenadas por defecto (Centro de Buenos Aires)
      return {'lat': '-34.6037', 'lon': '-58.3816'};
    }
  }

  /// Formatea dirección de Photon
  static String _formatPhotonAddress(Map<String, dynamic> properties) {
    final parts = <String>[];
    
    if (properties['name'] != null) parts.add(properties['name']);
    if (properties['street'] != null) parts.add(properties['street']);
    if (properties['city'] != null) parts.add(properties['city']);
    if (properties['state'] != null) parts.add(properties['state']);
    
    return parts.isNotEmpty ? parts.join(', ') : 'Dirección encontrada';
  }

  /// Obtiene la dirección basada en coordenadas (geocodificación inversa)
  static Future<Map<String, dynamic>?> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    try {
      final uri = Uri.parse('$_nominatimUrl/reverse').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'format': 'json',
          'addressdetails': '1',
          'accept-language': 'es',
        },
      );

      print('🔍 AddressService: Geocodificación inversa para ($lat, $lon)');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'display_name': data['display_name'],
          'formatted': _formatAddress(data),
          'address': data['address'] ?? {},
        };
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 AddressService: Error en geocodificación inversa: $e');
      return null;
    }
  }

  /// Formatea una dirección para mostrar de forma más legible
  static String _formatAddress(Map<String, dynamic> addressData) {
    final address = addressData['address'] as Map<String, dynamic>? ?? {};
    
    // Extraer componentes principales
    final houseNumber = address['house_number'] ?? '';
    final road = address['road'] ?? '';
    final neighbourhood = address['neighbourhood'] ?? '';
    final suburb = address['suburb'] ?? '';
    final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
    final state = address['state'] ?? '';
    final country = address['country'] ?? '';
    final postcode = address['postcode'] ?? '';

    // Construir dirección formateada
    List<String> parts = [];

    // Dirección principal (calle y número)
    if (road.isNotEmpty) {
      if (houseNumber.isNotEmpty) {
        parts.add('$road $houseNumber');
      } else {
        parts.add(road);
      }
    }

    // Barrio o área
    if (neighbourhood.isNotEmpty) {
      parts.add(neighbourhood);
    } else if (suburb.isNotEmpty) {
      parts.add(suburb);
    }

    // Ciudad
    if (city.isNotEmpty) {
      parts.add(city);
    }

    // Provincia/Estado
    if (state.isNotEmpty) {
      parts.add(state);
    }

    // Código postal
    if (postcode.isNotEmpty) {
      parts.add('($postcode)');
    }

    // País (solo si no es Argentina o si no hay otros datos)
    if (country.isNotEmpty && (country != 'Argentina' || parts.isEmpty)) {
      parts.add(country);
    }

    final formatted = parts.join(', ');
    
    // Fallback al display_name si no se pudo formatear
    return formatted.isNotEmpty ? formatted : (addressData['display_name'] ?? '');
  }

  /// Valida si una dirección es válida (tiene información suficiente)
  static bool isValidAddress(String address) {
    if (address.trim().isEmpty) return false;
    
    // Verificar que tenga al menos algunos caracteres y no sea solo espacios
    final trimmed = address.trim();
    return trimmed.length >= 5 && trimmed.contains(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]'));
  }
}
