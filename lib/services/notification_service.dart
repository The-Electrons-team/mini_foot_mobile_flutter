import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'web_notification_io.dart'
    if (dart.library.js) 'web_notification_web.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final String _base = dotenv.env['API_URL'] ?? 'http://127.0.0.1:3001/api/v1';

  // Conserve le dernier JWT vu pour que onTokenRefresh puisse PATCH
  // sans dépendre de l'AuthProvider.
  String? _authToken;
  bool _refreshListenerInstalled = false;

  Future<void> init(String? token) async {
    _authToken = token;
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Permission notifications accordée');
      }

      String? fcmToken = await _fcm.getToken();

      if (fcmToken != null && token != null) {
        debugPrint('FCM Token: $fcmToken');
        await _updateTokenOnServer(token, fcmToken);
      }

      _installTokenRefreshListener();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Notification reçue en premier plan: ${message.notification?.title}');

        if (kIsWeb && message.notification != null) {
          showBrowserNotification(
            message.notification!.title,
            message.notification!.body,
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App ouverte via notification: ${message.data}');
      });
    } catch (e) {
      debugPrint('Erreur initialisation Firebase Messaging: $e');
    }
  }

  void _installTokenRefreshListener() {
    if (_refreshListenerInstalled) return;
    _refreshListenerInstalled = true;
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      final authToken = _authToken;
      if (authToken != null) {
        await _updateTokenOnServer(authToken, newToken);
      }
    });
  }

  // Retry en backoff sur échec réseau ou code non-2xx. Trois tentatives
  // suffisent : au-delà, le prochain refresh ou login retentera.
  Future<void> _updateTokenOnServer(String authToken, String fcmToken) async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await http.patch(
          Uri.parse('$_base/users/me/fcm-token'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'token': fcmToken}),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }
        debugPrint(
          'PATCH /users/me/fcm-token → ${response.statusCode} (tentative $attempt)',
        );
      } catch (e) {
        debugPrint('Erreur PATCH fcm-token tentative $attempt: $e');
      }
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }
}
