import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';
class SocketService with ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    // Extraire la racine (sans /api/v1) pour le namespace WebSocket
    final String apiUrl = ApiService().baseUrl;
    final uri = Uri.parse(apiUrl);
    final String wsRoot = '${uri.scheme}://${uri.host}:${uri.port}';

    _socket = IO.io('$wsRoot/ws', IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .setExtraHeaders({'Authorization': 'Bearer $token'})
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('Socket connected');
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('Socket disconnected');
      notifyListeners();
    });

    _socket!.onConnectError((err) => debugPrint('Socket Connect Error: $err'));
    _socket!.onError((err) => debugPrint('Socket Error: $err'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void sendTypingStart(String conversationId) {
    _socket?.emit('typing_start', {'conversationId': conversationId});
  }

  void sendTypingStop(String conversationId) {
    _socket?.emit('typing_stop', {'conversationId': conversationId});
  }

  void markAsRead(String conversationId) {
    _socket?.emit('message_read', {'conversationId': conversationId});
  }

  void onMessageReceived(Function(dynamic) callback) {
    _socket?.on('message_received', callback);
  }

  void onMessageRead(Function(dynamic) callback) {
    _socket?.on('message_read', callback);
  }

  void onTypingStart(Function(dynamic) callback) {
    _socket?.on('typing_start', callback);
  }

  void onTypingStop(Function(dynamic) callback) {
    _socket?.on('typing_stop', callback);
  }

  void onNewConversation(Function(dynamic) callback) {
    _socket?.on('conversation:new', callback);
  }
}
