import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TournamentService {
  final String _baseUrl = dotenv.get('API_URL');

  Future<List<dynamic>> getAll({String? status}) async {
    var url = '$_baseUrl/tournaments';
    if (status != null) url += '?status=$status';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement tournois: ${response.body}');
  }

  Future<Map<String, dynamic>> getOne(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/tournaments/$id'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement tournoi: ${response.body}');
  }

  Future<Map<String, dynamic>> getBracket(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/tournaments/$id/bracket'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement bracket: ${response.body}');
  }

  Future<Map<String, dynamic>> register(String token, String tournamentId, String teamId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tournaments/$tournamentId/register'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'teamId': teamId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Erreur inscription');
  }

  Future<Map<String, dynamic>> forfeit(String token, String tournamentId, String teamId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tournaments/$tournamentId/forfeit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'teamId': teamId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Erreur forfait');
  }
}
