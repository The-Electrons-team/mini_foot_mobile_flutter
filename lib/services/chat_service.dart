import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getConversations(String token) async {
    return await _api.get(
      '/chat/conversations',
      token: token,
      defaultErrorMsg: 'Erreur de récupération des conversations',
    );
  }

  Future<List<dynamic>> getMessages(String conversationId, String token, {int page = 1}) async {
    return await _api.get(
      '/chat/conversations/$conversationId/messages?page=$page',
      token: token,
      defaultErrorMsg: 'Erreur de récupération des messages',
    );
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String text, String token) async {
    return await _api.post(
      '/chat/conversations/$conversationId/messages',
      body: {'text': text},
      token: token,
      defaultErrorMsg: 'Erreur d\'envoi du message',
    );
  }

  Future<Map<String, dynamic>> getOrCreateDirectConversation(String targetId, String token) async {
    return await _api.post(
      '/chat/conversations/direct/$targetId',
      token: token,
      defaultErrorMsg: 'Erreur création conversation',
    );
  }
}
