import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String _parseApiError(String body, String defaultMsg) {
  try {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final msg = data['message'];
    if (msg is List) return msg.join(', ');
    return msg?.toString() ?? defaultMsg;
  } catch (_) {
    return defaultMsg;
  }
}

class AuthService {
  static String _resolveBaseUrl() {
    try {
      return dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';
    } catch (_) {
      return 'http://localhost:3000/api/v1';
    }
  }

  final String _baseUrl = _resolveBaseUrl();

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      if (response.statusCode == 401 || response.statusCode == 404) {
        throw Exception('AUTH_INVALID');
      }
      if (response.statusCode == 400) {
        throw Exception(_parseApiError(response.body, 'Requête invalide'));
      }
      if (response.statusCode >= 500) {
        throw Exception('SERVER_UNAVAILABLE');
      }
      throw Exception('SERVER_UNAVAILABLE');
    } on TimeoutException {
      throw Exception('SERVER_UNAVAILABLE');
    } on http.ClientException {
      throw Exception('SERVER_UNAVAILABLE');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String phone) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception(
      _parseApiError(response.body, 'Erreur lors de l\'envoi du code'),
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String code,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'code': code,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception(
      _parseApiError(response.body, 'Erreur lors de la réinitialisation'),
    );
  }

  Future<Map<String, dynamic>> startSignup(String phone) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        _parseApiError(response.body, 'Erreur lors de l\'inscription'),
      );
    }
  }

  Future<Map<String, dynamic>> resendOtp(String phone) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/resend-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        _parseApiError(response.body, 'Erreur lors de l\'envoi du code'),
      );
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'code': code}),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        _parseApiError(response.body, 'Code OTP invalide ou expiré'),
      );
    }
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'password': password,
            'firstName': firstName,
            'lastName': lastName,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        _parseApiError(response.body, 'Erreur lors de l\'inscription'),
      );
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/users/me'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur de récupération du profil: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/users/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        _parseApiError(
          response.body,
          'Erreur lors de la mise à jour du profil',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(
    String token,
    List<int> bytes,
    String filename,
  ) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/users/me/avatar'))
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename),
          );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur d\'upload avatar: ${response.body}');
    }
  }
}
