import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final String _base = dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';

  Future<void> init(String? token) async {
    try {
      // 1. Demander la permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Permission notifications accordée');
      }

      // 2. Récupérer le token FCM
      String? fcmToken = await _fcm.getToken();

      if (fcmToken != null && token != null) {
        debugPrint('FCM Token: $fcmToken');
        await _updateTokenOnServer(token, fcmToken);
      }

      // 3. Écouter les messages en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Notification reçue en premier plan: ${message.notification?.title}');
        
        if (kIsWeb && message.notification != null) {
          js.context.callMethod('showBrowserNotification', [
            message.notification!.title,
            message.notification!.body,
          ]);
        }
      });

      // 4. Écouter quand l'utilisateur clique sur la notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App ouverte via notification: ${message.data}');
      });
    } catch (e) {
      debugPrint('Erreur initialisation Firebase Messaging: $e');
    }
  }

  Future<void> _updateTokenOnServer(String authToken, String fcmToken) async {
    try {
      await http.patch(
        Uri.parse('$_base/users/me/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': fcmToken}),
      );
    } catch (e) {
      debugPrint('Erreur mise à jour FCM Token: $e');
    }
  }
}
