import 'package:flutter/material.dart';

/// Snackbars standardisés pour l'app mobile.
///
/// Usage :
///   AppSnackbar.error(context, 'Impossible de charger les terrains.');
///   AppSnackbar.success(context, 'Réservation annulée avec succès.');
class AppSnackbar {
  AppSnackbar._();

  static const _kError   = Color(0xFFDC2626);
  static const _kSuccess = Color(0xFF16A34A);
  static const _kInfo    = Color(0xFF1565C0);
  static const _kWarning = Color(0xFFD97706);

  static void error(BuildContext context, String message) => _show(
    context,
    message: message,
    background: _kError,
    icon: Icons.error_rounded,
    duration: const Duration(seconds: 4),
  );

  static void success(BuildContext context, String message) => _show(
    context,
    message: message,
    background: _kSuccess,
    icon: Icons.check_circle_rounded,
    duration: const Duration(seconds: 3),
  );

  static void info(BuildContext context, String message) => _show(
    context,
    message: message,
    background: _kInfo,
    icon: Icons.info_rounded,
    duration: const Duration(seconds: 3),
  );

  static void warning(BuildContext context, String message) => _show(
    context,
    message: message,
    background: _kWarning,
    icon: Icons.warning_rounded,
    duration: const Duration(seconds: 4),
  );

  static void _show(
    BuildContext context, {
    required String message,
    required Color background,
    required IconData icon,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
      ),
    );
  }
}
