import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MatchService {
  static String _resolveBaseUrl() {
    try {
      return dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';
    } catch (_) {
      return 'http://localhost:3000/api/v1';
    }
  }

  final String _baseUrl = _resolveBaseUrl();

  Future<List<dynamic>> getMatches({String? zone}) async {
    var url = '$_baseUrl/matches';
    if (zone != null) url += '?zone=$zone';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement matchs: ${response.body}');
  }

  Future<List<dynamic>> getMyTeamMatches(String token, String teamId, {String? status, String? opponentId, String? date, int? page, int? limit}) async {
    var url = '$_baseUrl/matches/team/$teamId';
    List<String> queries = [];
    if (status != null) queries.add('status=$status');
    if (opponentId != null) queries.add('opponentId=$opponentId');
    if (date != null) queries.add('date=$date');
    if (page != null) queries.add('page=$page');
    if (limit != null) queries.add('limit=$limit');
    
    if (queries.isNotEmpty) {
      url += '?' + queries.join('&');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement matchs équipe: ${response.body}');
  }

  Future<List<dynamic>> getPendingChallenges(String token, String teamId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/matches/challenges/pending/$teamId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement défis: ${response.body}');
  }

  Future<List<dynamic>> getTeamChallenges(String token, String teamId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/matches/challenges/team/$teamId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement défis: ${response.body}');
  }

  Future<void> sendChallenge({
    required String token,
    required String fromTeamId,
    required String opponentTeamId,
    required String date,
    required String time,
    required String zone,
    required String format,
    required String terrainId,
    String? subTerrainId,
    String? terrainName,
  }) async {
    final body = {
      'fromTeamId': fromTeamId,
      'toTeamId': opponentTeamId,
      'date': date,
      'time': time,
      'zone': zone,
      'format': format,
      'terrainId': terrainId,
      if (subTerrainId != null && subTerrainId.isNotEmpty) 'subTerrainId': subTerrainId,
      if (terrainName != null && terrainName.isNotEmpty) 'terrainName': terrainName,
    };
    debugPrint('[MatchService] sendChallenge payload: ${jsonEncode(body)}');
    final response = await http.post(
      Uri.parse('$_baseUrl/matches/challenge'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    debugPrint('[MatchService] sendChallenge response ${response.statusCode}: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur envoi défi (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> respondChallenge(String token, String challengeId, bool accept) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/matches/challenge/$challengeId/respond'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'accept': accept}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur réponse défi: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getChallengePaymentLink(String token, String challengeId, {String method = 'WAVE'}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/matches/challenge/$challengeId/payment-link'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'method': method}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erreur paiement défi: ${response.body}');
  }

  Future<void> updateScore(String token, String matchId, int homeScore, int awayScore) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/matches/$matchId/score'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'homeScore': homeScore, 'awayScore': awayScore}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour score: ${response.body}');
    }
  }
}
