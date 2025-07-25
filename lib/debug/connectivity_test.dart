import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// **UTILIDAD: Test de Conectividad**
/// 
/// Widget simple para probar conectividad directamente en la UI
class ConnectivityTest extends StatefulWidget {
  const ConnectivityTest({super.key});

  @override
  State<ConnectivityTest> createState() => _ConnectivityTestState();
}

class _ConnectivityTestState extends State<ConnectivityTest> {
  String _results = 'Presiona el botón para probar conectividad';
  bool _testing = false;

  Future<void> _testConnectivity() async {
    setState(() {
      _testing = true;
      _results = 'Probando conectividad...';
    });

    final results = <String>[];

    // Test 1: Google
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'User-Agent': 'PresenceApp/1.0'},
      ).timeout(const Duration(seconds: 5));
      results.add('✅ Google: ${response.statusCode}');
    } catch (e) {
      results.add('❌ Google: $e');
    }

    // Test 2: Nominatim
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=test&format=json&limit=1'),
        headers: {'User-Agent': 'PresenceApp/1.0'},
      ).timeout(const Duration(seconds: 8));
      results.add('✅ Nominatim: ${response.statusCode}');
    } catch (e) {
      results.add('❌ Nominatim: $e');
    }

    // Test 3: Photon
    try {
      final response = await http.get(
        Uri.parse('https://photon.komoot.io/api?q=test&limit=1'),
        headers: {'User-Agent': 'PresenceApp/1.0'},
      ).timeout(const Duration(seconds: 8));
      results.add('✅ Photon: ${response.statusCode}');
    } catch (e) {
      results.add('❌ Photon: $e');
    }

    setState(() {
      _testing = false;
      _results = results.join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Conectividad')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testing ? null : _testConnectivity,
              child: _testing 
                ? const CircularProgressIndicator()
                : const Text('Probar Conectividad'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _results,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
