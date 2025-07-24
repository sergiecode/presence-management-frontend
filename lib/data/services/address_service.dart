import 'dart:convert';
import 'package:http/http.dart' as http;

/// **SERVICIO: Búsqueda de Direcciones**
///
/// Servicio que se conecta a la API de Nominatim (OpenStreetMap)
/// para buscar direcciones de forma gratuita.
///
/// **Funcionalidades:**
/// - Búsqueda de direcciones por texto
/// - Geocodificación (dirección -> coordenadas)
/// - Geocodificación inversa (coordenadas -> dirección)
/// - Manejo de errores y rate limiting
class AddressService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'PresenceManagementApp/1.0';

  /// Busca direcciones basado en un texto de consulta
  /// 
  /// Retorna una lista de sugerencias con la información completa
  /// de cada dirección encontrada.
  static Future<List<Map<String, dynamic>>> searchAddresses(String query) async {
    try {
      // Construir URL con parámetros
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '5',
          'countrycodes': 'ar', // Limitar a Argentina, cambiar según necesidad
          'accept-language': 'es', // Preferir respuestas en español
        },
      );

      print('AddressService: Buscando direcciones para "$query"');
      print('AddressService: URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        print('AddressService: Encontradas ${data.length} direcciones');

        return data.map((item) => {
          'display_name': item['display_name'],
          'formatted': _formatAddress(item),
          'lat': item['lat'],
          'lon': item['lon'],
          'address': item['address'] ?? {},
          'place_id': item['place_id'],
          'osm_type': item['osm_type'],
          'osm_id': item['osm_id'],
        }).toList();

      } else if (response.statusCode == 429) {
        throw Exception('Demasiadas solicitudes. Intente nuevamente en unos segundos.');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('AddressService: Error buscando direcciones: $e');
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Obtiene la dirección basada en coordenadas (geocodificación inversa)
  static Future<Map<String, dynamic>?> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'format': 'json',
          'addressdetails': '1',
          'accept-language': 'es',
        },
      );

      print('AddressService: Geocodificación inversa para ($lat, $lon)');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

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
      print('AddressService: Error en geocodificación inversa: $e');
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
