import 'package:flutter/material.dart';

/// Clé globale pour la navigation depuis les notifications push.
/// Utilisée par [NotificationService] pour naviguer sans contexte BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
