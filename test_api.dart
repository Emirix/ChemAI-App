import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://127.0.0.1:3005/api';
  final url = '$baseUrl/safety-data';
  print('Testing API at $url...');

  try {
    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'productName': 'Ethanol', 'language': 'Turkish'}),
        )
        .timeout(Duration(seconds: 30));

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
