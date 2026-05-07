
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TeamService {
  final String _baseUrl = dotenv.get('API_URL');

  // Créer une équipe sur le Backend
  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/teams'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur de création d\'équipe: ${response.body}');
    }
  }

  // Récupérer mon équipe
  Future<Map<String, dynamic>?> getMyTeam(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/teams/mine'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List teams = jsonDecode(response.body);
      if (teams.isNotEmpty) return teams[0];
      return null;
    }
    return null;
  }

  // Rejoindre une équipe via un code
  Future<Map<String, dynamic>> joinTeam(String code, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/teams/join/$code'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la tentative de rejoindre: ${response.body}');
    }
  }

  // Accepter un membre (Réservé au capitaine)
  Future<void> acceptMember(String teamId, String memberId, String token) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/teams/$teamId/members/$memberId/accept'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur lors de l\'acceptation du membre: ${response.body}');
    }
  }
}


