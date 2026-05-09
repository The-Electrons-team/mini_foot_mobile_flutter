import 'api_service.dart';

/// Mapping des types de paiement Flutter → enum backend
const _paymentTypeMap = {0: 'TOTAL', 1: 'DEPOSIT', 2: 'SHARED'};

/// Méthode de paiement unique — DexPay
const _paymentMethod = 'DEXPAY';

class ReservationService {
  final ApiService _api = ApiService();

  /// Crée une réservation en base via POST /reservations
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
    final body = <String, dynamic>{
      'terrainId': terrainId,
      'date': date,
      'startSlot': startSlot,
      'endSlot': endSlot,
      'intervals': intervals,
      'paymentType': _paymentTypeMap[paymentTypeIndex] ?? 'TOTAL',
      'paymentMethod': _paymentMethod,
    };
    if (subTerrainId != null) body['subTerrainId'] = subTerrainId;
    if (promoCode != null && promoCode.isNotEmpty) body['promoCode'] = promoCode;
    if (nbPersonnes != null) body['nbPersonnes'] = nbPersonnes;

    return await _api.post(
      '/reservations',
      body: body,
      token: token,
      defaultErrorMsg: 'Erreur création réservation',
    );
  }

  /// Récupère le lien de paiement pour une réservation via POST /reservations/:id/payment-link
  Future<String> getPaymentLink({
    required String token,
    required String reservationId,
  }) async {
    final response = await _api.post(
      '/reservations/$reservationId/payment-link',
      body: {},
      token: token,
      defaultErrorMsg: 'Erreur lien paiement',
    );
    return response['link'] as String;
  }

  /// Récupère les réservations de l'utilisateur connecté
  Future<List<Map<String, dynamic>>> getMyReservations(String token) async {
    final response = await _api.get(
      '/reservations',
      token: token,
      defaultErrorMsg: 'Erreur chargement réservations',
    );
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Récupère le détail d'une réservation
  Future<Map<String, dynamic>> getReservation(String token, String id) async {
    return await _api.get(
      '/reservations/$id',
      token: token,
      defaultErrorMsg: 'Erreur détail réservation',
    );
  }

  /// Annule une réservation
  Future<Map<String, dynamic>> cancelReservation(String token, String id) async {
    return await _api.delete(
      '/reservations/$id',
      token: token,
      defaultErrorMsg: 'Erreur annulation réservation',
    );
  }
}
