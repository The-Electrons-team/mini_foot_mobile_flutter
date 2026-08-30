import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_navigator.dart';
import '../booking_confirmation_screen.dart';
import '../terrain_data.dart';
import '../providers/auth_provider.dart';
import 'reservation_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._();
  factory DeepLinkService() => _instance;
  DeepLinkService._();

  final _appLinks = AppLinks();
  final _reservationService = ReservationService();
  StreamSubscription<Uri>? _sub;

  /// Stream that emits payment references when a deep link is received.
  /// Used by PaymentScreen to interrupt polling.
  final _paymentRefController = StreamController<String>.broadcast();
  Stream<String> get onPaymentRef => _paymentRefController.stream;

  void init() {
    _sub = _appLinks.uriLinkStream.listen(_handleUri);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    debugPrint('[DeepLink] Received: $uri');

    // minifoot://reservation/success?ref=MF-xxx  → host=reservation, path=/success
    // https://minifootapp.com/reservation/success?ref=MF-xxx → path=/reservation/success
    final path = uri.host == 'reservation'
        ? '/${uri.host}${uri.path}'
        : uri.path;

    final ref = uri.queryParameters['ref'];
    if (ref == null || ref.isEmpty) return;

    _paymentRefController.add(ref);

    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (path.contains('success')) {
      _navigateToConfirmation(context, ref);
    } else if (path.contains('failure')) {
      _showPaymentFailure(context, ref);
    }
  }

  Future<void> _navigateToConfirmation(BuildContext context, String ref) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) return;

      final data = await _reservationService.getReservationByReference(token, ref);
      if (!context.mounted) return;

      final terrainData = data['terrain'];
      if (terrainData == null) return;

      final terrain = Terrain.fromJson(terrainData as Map<String, dynamic>);
      final subTerrainData = data['subTerrain'];
      final subTerrain = subTerrainData != null
          ? SubTerrain.fromJson(subTerrainData as Map<String, dynamic>)
          : null;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            terrain: terrain,
            subTerrain: subTerrain,
            date: DateTime.parse(data['date']),
            startSlot: data['startSlot'] ?? '',
            endSlot: data['endSlot'] ?? '',
            finalPrice: data['finalPrice'] ?? 0,
            reference: ref,
            qrData: data['qrData'],
            fromReservations: true,
            isDepositOnly: data['depositPaidAt'] != null &&
                data['status'] != 'CONFIRMED',
            depositAmount: data['depositAmount'],
          ),
        ),
      );
    } catch (e) {
      debugPrint('[DeepLink] Error navigating to confirmation: $e');
    }
  }

  void _showPaymentFailure(BuildContext context, String ref) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paiement echoue pour $ref. Veuillez reessayer.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void dispose() {
    _sub?.cancel();
    _paymentRefController.close();
  }
}
