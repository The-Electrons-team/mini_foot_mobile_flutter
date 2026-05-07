import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum NotifType {
  RESERVATION_CONFIRMED,
  RESERVATION_CANCELLED,
  MATCH_REMINDER,
  TEAM_INVITATION,
  TEAM_JOIN_REQUEST,
  TEAM_MEMBER_JOINED,
  CHALLENGE_RECEIVED,
  CHALLENGE_RESPONSE,
  SCORE_SUBMITTED,
  SOCIAL_LIKE,
  SOCIAL_COMMENT,
  CHAT_MESSAGE,
  PROMO,
  SYSTEM,
  // Anciens
  RESERVATION,
  MATCH,
  CHAT,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotifType type;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: _parseType(json['type']),
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      data: json['data'],
    );
  }

  static NotifType _parseType(String type) {
    return NotifType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotifType.SYSTEM,
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final String _base = dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isMarkingAllRead = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isMarkingAllRead => _isMarkingAllRead;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_base/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('Charge notifications: ${response.statusCode}');
      debugPrint('Corps réponse: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];
        _notifications = data
            .map((n) => NotificationModel.fromJson(n))
            .toList();
        _unreadCount = decoded['unreadCount'] is int
            ? decoded['unreadCount']
            : _notifications.where((n) => !n.read).length;
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String token, String id) async {
    try {
      await http.patch(
        Uri.parse('$_base/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          body: _notifications[index].body,
          type: _notifications[index].type,
          read: true,
          createdAt: _notifications[index].createdAt,
          data: _notifications[index].data,
        );
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String token) async {
    if (_isMarkingAllRead || _unreadCount == 0) return;
    _isMarkingAllRead = true;
    notifyListeners();

    final previousNotifications = List<NotificationModel>.from(_notifications);
    final previousUnreadCount = _unreadCount;

    try {
      final response = await http.patch(
        Uri.parse('$_base/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erreur lecture notifications: ${response.body}');
      }

      _notifications = _notifications
          .map(
            (n) => NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              read: true,
              createdAt: n.createdAt,
              data: n.data,
            ),
          )
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _notifications = previousNotifications;
      _unreadCount = previousUnreadCount;
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    } finally {
      _isMarkingAllRead = false;
      notifyListeners();
    }
  }

  Future<void> sendTestNotification(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_base/notifications/test'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Rafraîchir la liste uniquement si l'envoi a réussi
        await loadNotifications(token);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
