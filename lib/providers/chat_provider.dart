import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SocketService _socketService;
  final AuthProvider _authProvider;

  List<dynamic> _conversations = [];
  Map<String, List<dynamic>> _messages = {};
  bool _isLoading = false;

  ChatProvider(this._authProvider, this._socketService) {
    if (_authProvider.isAuthenticated) {
      _init();
    }
  }

  List<dynamic> get conversations => _conversations;
  bool get isLoading => _isLoading;

  List<dynamic> getMessages(String conversationId) => _messages[conversationId] ?? [];

  void _init() {
    final token = _authProvider.token;
    if (token == null || token.isEmpty) return;
    _socketService.connect(token);
    _socketService.onMessageReceived((data) {
      final String convId = data['conversationId'];
      if (_messages.containsKey(convId)) {
        _messages[convId]!.add(data);
      }
      _updateLastMessage(convId, data);
      notifyListeners();
    });
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();
    try {
      _conversations = await _chatService.getConversations(_authProvider.token!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    try {
      final msgs = await _chatService.getMessages(conversationId, _authProvider.token!);
      _messages[conversationId] = msgs;
      _socketService.joinConversation(conversationId);
      _socketService.markAsRead(conversationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<void> sendMessage(String conversationId, String text) async {
    try {
      final msg = await _chatService.sendMessage(conversationId, text, _authProvider.token!);
      // Le message sera reçu via socket, mais on peut l'ajouter localement pour plus de réactivité
      if (_messages.containsKey(conversationId)) {
         // Vérifier si pas déjà ajouté par le socket
         if (!_messages[conversationId]!.any((m) => m['id'] == msg['id'])) {
           _messages[conversationId]!.add(msg);
         }
      } else {
        _messages[conversationId] = [msg];
      }
      _updateLastMessage(conversationId, msg);
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<Map<String, dynamic>> getOrCreateDirectConversation(String targetId) async {
    final conv = await _chatService.getOrCreateDirectConversation(targetId, _authProvider.token!);
    // Refresh conversations list to include new one
    await fetchConversations();
    return conv;
  }

  void _updateLastMessage(String conversationId, dynamic message) {
    final index = _conversations.indexWhere((c) => c['id'] == conversationId);
    if (index != -1) {
      final conv = _conversations.removeAt(index);
      conv['messages'] = [message];
      conv['updatedAt'] = message['createdAt'];
      _conversations.insert(0, conv);
    } else {
      // Re-fetch conversations if new one
      fetchConversations();
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
