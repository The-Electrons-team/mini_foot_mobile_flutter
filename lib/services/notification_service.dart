import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../app_navigator.dart';
import '../matches_screen.dart';
import 'browser_notification_stub.dart'
    if (dart.library.html) 'browser_notification_web.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  static String _resolveBaseUrl() {
    try {
      return dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';
    } catch (_) {
      return 'http://localhost:3000/api/v1';
    }
  }

  /// Token d'authentification JWT courant, mis à jour à chaque connexion.
  String? _authToken;

  String get _base => _resolveBaseUrl();

  /// Initialise les notifications push pour l'utilisateur connecté.
  /// Doit être appelé dès la connexion (login / auto-login / register).
  Future<void> init(String? authToken) async {
    _authToken = authToken;

    try {
      // 1. Demander la permission (iOS + Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[NotifService] Statut permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[NotifService] Notifications refusées par l\'utilisateur.');
        return;
      }

      // 2. Enregistrer le token FCM courant
      final fcmToken = await _fcm.getToken();
      if (fcmToken != null && _authToken != null) {
        await _registerToken(fcmToken);
      }

      // 3. Écouter les renouvellements de token
      _fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('[NotifService] Token FCM renouvelé');
        if (_authToken != null) {
          await _registerToken(newToken);
        }
      });

      // 4. Cold-start : app lancée depuis une notification (app terminée)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        await Future.delayed(const Duration(milliseconds: 600));
        _handleNavigation(initialMessage.data);
      }

      // 5. Messages reçus en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[NotifService] Notification 1er plan: ${message.notification?.title}');
        if (kIsWeb && message.notification != null) {
          showBrowserNotification(
            message.notification!.title,
            message.notification!.body,
          );
        }
      });

      // 6. App en arrière-plan : tap sur la notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[NotifService] Tap notification: ${message.data}');
        _handleNavigation(message.data);
      });
    } catch (e) {
      debugPrint('[NotifService] Erreur init: $e');
    }
  }

  /// Met à jour le token d'auth (utile si la session est prolongée sans re-login).
  void updateAuthToken(String? token) {
    _authToken = token;
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  void _handleNavigation(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    final extra = normalized['extra'];
    if (extra is String && extra.isNotEmpty) {
      try {
        final decoded = jsonDecode(extra);
        if (decoded is Map<String, dynamic>) {
          normalized.addAll(decoded);
        }
      } catch (_) {
        debugPrint('[NotifService] Payload extra invalide: $extra');
      }
    }

    final screen = normalized['screen']?.toString();
    if (screen == 'matches') {
      final tabIndex = int.tryParse(normalized['tabIndex']?.toString() ?? '') ?? 2;
      _navigateToMatches(tabIndex);
    }
  }

  void _navigateToMatches(int tabIndex) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => MatchesScreen(initialTab: tabIndex)),
    );
  }

  // ── Enregistrement du token FCM ─────────────────────────────────────────

  Future<void> _registerToken(String fcmToken) async {
    try {
      final response = await http.patch(
        Uri.parse('$_base/users/me/fcm-token'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': fcmToken}),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('[NotifService] Token FCM enregistré sur le serveur');
      } else {
        debugPrint('[NotifService] Échec enregistrement token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[NotifService] Erreur enregistrement token FCM: $e');
    }
  }
}
