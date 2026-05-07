import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';

class UserService {
  final String _base = dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';

  Future<Map<String, dynamic>?> updateAvatar(String token, Uint8List fileBytes, String fileName) async {
    final uri = Uri.parse('$_base/users/me/avatar');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'), // Ajuster selon le type si nécessaire
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }
}
