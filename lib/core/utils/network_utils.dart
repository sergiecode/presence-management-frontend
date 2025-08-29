import 'dart:io';
import 'package:http/http.dart' as http;

/// **UTILIDAD: Verificación de Red**
/// 
/// Utilidades para verificar conectividad y diagnósticos de red
class NetworkUtils {
  /// Verifica si hay conectividad a internet
  static Future<bool> hasInternetConnection() async {
    try {
      
      // Intentar conectar a múltiples servicios con timeouts más cortos
      final futures = [
        _testConnection('https://www.google.com'),
        _testConnection('https://httpbin.org/status/200'),
        _testConnection('https://nominatim.openstreetmap.org'),
        _testConnection('https://1.1.1.1'), // DNS de Cloudflare
      ];
      
      // Si al menos uno responde, hay conexión
      final results = await Future.wait(futures, eagerError: false);
      final hasConnection = results.any((result) => result);
      
      
      return hasConnection;
    } catch (e) {
      // En caso de error, asumir que hay conexión para intentar las APIs
      return true;
    }
  }

  /// Verifica conectividad a un endpoint específico
  static Future<bool> _testConnection(String url) async {
    try {
      final response = await http.head(
        Uri.parse(url),
        headers: {'User-Agent': 'PresenceManagementApp/1.0'},
      ).timeout(const Duration(seconds: 2)); // Timeout más corto
      
      final success = response.statusCode >= 200 && response.statusCode < 400;
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Ejecuta diagnósticos de red detallados
  static Future<Map<String, dynamic>> runNetworkDiagnostics() async {
    final diagnostics = <String, dynamic>{};
    
    try {
      // Test de conectividad básica
      diagnostics['hasInternet'] = await hasInternetConnection();
      
      // Test de DNS
      diagnostics['dnsWorking'] = await _testDNS();
      
      // Test de APIs específicas
      diagnostics['nominatim'] = await _testAPIEndpoint('https://nominatim.openstreetmap.org/search?q=test&format=json&limit=1');
      diagnostics['photon'] = await _testAPIEndpoint('https://photon.komoot.io/api?q=test&limit=1');
      
      
    } catch (e) {
      diagnostics['error'] = e.toString();
    }
    
    return diagnostics;
  }

  /// Verifica si el DNS está funcionando
  static Future<bool> _testDNS() async {
    try {
      await InternetAddress.lookup('google.com');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verifica conectividad a un endpoint de API
  static Future<Map<String, dynamic>> _testAPIEndpoint(String url) async {
    final result = <String, dynamic>{};
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'PresenceManagementApp/1.0'},
      ).timeout(const Duration(seconds: 5));
      
      stopwatch.stop();
      
      result['success'] = response.statusCode == 200;
      result['statusCode'] = response.statusCode;
      result['responseTime'] = stopwatch.elapsedMilliseconds;
      result['error'] = null;
      
    } catch (e) {
      stopwatch.stop();
      result['success'] = false;
      result['statusCode'] = null;
      result['responseTime'] = stopwatch.elapsedMilliseconds;
      result['error'] = e.toString();
    }
    
    return result;
  }
}
