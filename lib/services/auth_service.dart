import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String _baseUrl = Platform.isAndroid ? "http://10.0.2.2:8080/auth" : "http://localhost:8080/auth";

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login');
    }
  }
}
