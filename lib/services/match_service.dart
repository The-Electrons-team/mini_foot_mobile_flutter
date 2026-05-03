import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MatchService {
  final String _baseUrl = dotenv.get('API_URL');

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

  Future<List<dynamic>> getPendingChallenges(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/matches/challenges/pending'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement défis: ${response.body}');
  }

  Future<void> sendChallenge({required String token, required String fromTeamId, required String opponentTeamId, required String date, required String format, required String terrainId}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/matches/challenge'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fromTeamId': fromTeamId,
        'opponentTeamId': opponentTeamId,
        'date': date,
        'format': format,
        'terrainId': terrainId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur envoi défi: ${response.body}');
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
