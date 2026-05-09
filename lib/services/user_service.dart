import 'dart:typed_data';
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>?> updateAvatar(String token, Uint8List fileBytes, String fileName) async {
    try {
      final data = await _api.multipart(
        '/users/me/avatar',
        'POST',
        fileBytes,
        fileName,
        'file',
        token: token,
      );
      return data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
