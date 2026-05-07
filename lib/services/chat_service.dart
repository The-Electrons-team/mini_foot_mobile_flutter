import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  final String _baseUrl = dotenv.get('API_URL');

  Future<List<dynamic>> getConversations(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/conversations'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur de récupération des conversations: ${response.body}');
    }
  }

  Future<List<dynamic>> getMessages(String conversationId, String token, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages?page=$page'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur de récupération des messages: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String text, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'text': text,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur d\'envoi du message: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getOrCreateDirectConversation(String targetId, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/direct/$targetId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur création conversation: ${response.body}');
    }
  }
}
