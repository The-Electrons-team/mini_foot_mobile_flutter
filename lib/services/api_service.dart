import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Callback déclenché sur 401 — branché par AuthProvider au démarrage
  static void Function()? onUnauthorized;

  String get baseUrl {
    try {
      return dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';
    } catch (_) {
      return 'http://localhost:3000/api/v1';
    }
  }

  // --- Parse Error ---
  String parseApiError(String body, String defaultMsg) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final msg = data['message'];
      if (msg is List) return msg.join(', ');
      return msg?.toString() ?? defaultMsg;
    } catch (_) {
      return defaultMsg;
    }
  }

  // --- Headers Builder ---
  Map<String, String> _buildHeaders(String? token, {bool isMultipart = false}) {
    final headers = <String, String>{};
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- Handle Response ---
  dynamic _handleResponse(http.Response response, String defaultErrorMsg) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      // Flux login/OTP : on remonte l'erreur spécifique
      if (defaultErrorMsg == 'AUTH_INVALID') throw Exception('AUTH_INVALID');
      // Token expiré ou révoqué : déconnexion automatique
      onUnauthorized?.call();
      throw Exception('SESSION_EXPIREE');
    }

    throw Exception(parseApiError(response.body, defaultErrorMsg));
  }

  // --- HTTP Methods ---

  Future<dynamic> get(String endpoint, {String? token, String defaultErrorMsg = 'Erreur serveur'}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 12));
      return _handleResponse(response, defaultErrorMsg);
    } on TimeoutException {
      throw Exception('SERVER_UNAVAILABLE');
    } on http.ClientException {
      throw Exception('SERVER_UNAVAILABLE');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, String? token, String defaultErrorMsg = 'Erreur serveur'}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _buildHeaders(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 12));
      return _handleResponse(response, defaultErrorMsg);
    } on TimeoutException {
      throw Exception('SERVER_UNAVAILABLE');
    } on http.ClientException {
      throw Exception('SERVER_UNAVAILABLE');
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body, String? token, String defaultErrorMsg = 'Erreur serveur'}) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: _buildHeaders(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 12));
      return _handleResponse(response, defaultErrorMsg);
    } on TimeoutException {
      throw Exception('SERVER_UNAVAILABLE');
    } on http.ClientException {
      throw Exception('SERVER_UNAVAILABLE');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, String? token, String defaultErrorMsg = 'Erreur serveur'}) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _buildHeaders(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 12));
      return _handleResponse(response, defaultErrorMsg);
    } on TimeoutException {
      throw Exception('SERVER_UNAVAILABLE');
    } on http.ClientException {
      throw Exception('SERVER_UNAVAILABLE');
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body, String? token, String defaultErrorMsg = 'Erreur serveur'}) async {
    try {
      // Note: http.delete in dart supports body, but it's less common. We include it just in case.
      final request = http.Request('DELETE', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_buildHeaders(token));
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamedResponse = await request.send().timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, defaultErrorMsg);
    } on TimeoutException {
      throw Exception('SERVER_UNAVAILABLE');
    } on http.ClientException {
      throw Exception('SERVER_UNAVAILABLE');
    }
  }

  Future<dynamic> multipart(String endpoint, String method, List<int>? bytes, String? filename, String? fileField, {Map<String, String>? fields, String? token, String defaultErrorMsg = 'Erreur upload'}) async {
    try {
      final request = http.MultipartRequest(method, Uri.parse('$baseUrl$endpoint'))
        ..headers.addAll(_buildHeaders(token, isMultipart: true));
        
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      if (bytes != null && filename != null && fileField != null) {
        request.files.add(
          http.MultipartFile.fromBytes(fileField, bytes, filename: filename),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, defaultErrorMsg);
    } on TimeoutException {
      throw Exception('SERVER_UNAVAILABLE');
    } on http.ClientException {
      throw Exception('SERVER_UNAVAILABLE');
    }
  }
}
