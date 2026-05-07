import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Mapping des types de paiement Flutter → enum backend
const _paymentTypeMap = {0: 'TOTAL', 1: 'DEPOSIT', 2: 'SHARED'};

/// Méthode de paiement unique — DexPay
const _paymentMethod = 'DEXPAY';

class ReservationService {
  final String _baseUrl;

  ReservationService([String? baseUrl])
      : _baseUrl = baseUrl ?? _resolveBaseUrl();

  static String _resolveBaseUrl() {
    try {
      return dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';
    } catch (_) {
      return 'http://localhost:3000/api/v1';
    }
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

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

    final response = await http.post(
      Uri.parse('$_baseUrl/reservations'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final error = _parseError(response.body);
    throw Exception(error);
  }

  /// Récupère le lien de paiement pour une réservation via POST /reservations/:id/payment-link
  Future<String> getPaymentLink({
    required String token,
    required String reservationId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reservations/$reservationId/payment-link'),
      headers: _authHeaders(token),
      body: jsonEncode({}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['link'] as String;
    }
    throw Exception(_parseError(response.body));
  }

  /// Récupère les réservations de l'utilisateur connecté
  Future<List<Map<String, dynamic>>> getMyReservations(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reservations'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(_parseError(response.body));
  }

  /// Récupère le détail d'une réservation
  Future<Map<String, dynamic>> getReservation(String token, String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reservations/$id'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_parseError(response.body));
  }

  /// Annule une réservation
  Future<Map<String, dynamic>> cancelReservation(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/reservations/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_parseError(response.body));
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final msg = data['message'];
      if (msg is List) return msg.join(', ');
      return msg?.toString() ?? 'Erreur serveur';
    } catch (_) {
      return 'Erreur serveur';
    }
  }
}
