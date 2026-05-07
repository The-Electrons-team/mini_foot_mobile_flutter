import 'package:flutter/material.dart';
import '../services/reservation_service.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationService _service = ReservationService();

  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get reservations => List.unmodifiable(_reservations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Map<String, dynamic>> get upcoming => _reservations
      .where((r) => r['status'] == 'PENDING_PAYMENT' || r['status'] == 'CONFIRMED')
      .toList();

  List<Map<String, dynamic>> get past => _reservations
      .where((r) => r['status'] == 'CANCELLED' || r['status'] == 'COMPLETED')
      .toList();

  Future<void> loadReservations(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reservations = await _service.getMyReservations(token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée une réservation et met à jour la liste locale.
  /// Retourne la réservation créée (avec id, reference, etc.)
  Future<Map<String, dynamic>> createReservation({
    required String token,
    required String terrainId,
    String? subTerrainId,
    required String date,
    required String startSlot,
    required String endSlot,
    required int intervals,
    required int paymentTypeIndex,
    String? promoCode,
    int? nbPersonnes,
  }) async {
    final reservation = await _service.createReservation(
      token: token,
      terrainId: terrainId,
      subTerrainId: subTerrainId,
      date: date,
      startSlot: startSlot,
      endSlot: endSlot,
      intervals: intervals,
      paymentTypeIndex: paymentTypeIndex,
      promoCode: promoCode,
      nbPersonnes: nbPersonnes,
    );
    _reservations.insert(0, reservation);
    notifyListeners();
    return reservation;
  }

  /// Récupère le lien de paiement DexPay pour une réservation existante.
  Future<String> getPaymentLink({
    required String token,
    required String reservationId,
  }) async {
    return _service.getPaymentLink(
      token: token,
      reservationId: reservationId,
    );
  }

  /// Annule une réservation et recharge la liste.
  Future<Map<String, dynamic>> cancelReservation(String token, String id) async {
    final result = await _service.cancelReservation(token, id);
    await loadReservations(token);
    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
