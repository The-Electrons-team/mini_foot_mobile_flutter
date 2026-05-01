import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TeamService {
  final String _baseUrl = dotenv.get('API_URL');

  Future<Map<String, dynamic>> createTeam({
    required String token,
    required String name,
    String? zone,
    String? address,
    String? color,
    List<int>? logoBytes,
    String? logoFilename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/teams'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name;
    
    if (zone != null) request.fields['zone'] = zone;
    if (address != null) request.fields['address'] = address;
    if (color != null) request.fields['color'] = color;
    
    if (logoBytes != null && logoFilename != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'logo',
        logoBytes,
        filename: logoFilename,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur création équipe: ${response.body}');
    }
  }

  Future<List<dynamic>> getMyTeams(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/teams/mine'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur récupération équipes: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTeamDetail(String token, String teamId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/teams/$teamId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur récupération détail équipe: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> joinTeam(String token, String inviteCode) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/teams/join/$inviteCode'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la tentative de rejoindre: ${response.body}');
    }
  }
}
