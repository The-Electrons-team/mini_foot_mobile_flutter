import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TeamService {
  static String _resolveBaseUrl() {
    try {
      return dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';
    } catch (_) {
      return 'http://localhost:3000/api/v1';
    }
  }

  final String _baseUrl = _resolveBaseUrl();

  Future<Map<String, dynamic>> createTeam({
    required String token,
    required String name,
    String? zone,
    String? address,
    String? color,
    double? lat,
    double? lng,
    List<int>? logoBytes,
    String? logoFilename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/teams'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name;

    if (zone != null) request.fields['zone'] = zone;
    if (address != null) request.fields['address'] = address;
    if (color != null) request.fields['color'] = color;
    if (lat != null) request.fields['lat'] = lat.toString();
    if (lng != null) request.fields['lng'] = lng.toString();

    if (logoBytes != null && logoFilename != null) {
      request.files.add(
        http.MultipartFile.fromBytes('logo', logoBytes, filename: logoFilename),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur création équipe: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateTeam({
    required String token,
    required String teamId,
    required String name,
    String? zone,
    String? address,
    String? color,
    double? lat,
    double? lng,
    List<int>? logoBytes,
    String? logoFilename,
  }) async {
    final request =
        http.MultipartRequest('PATCH', Uri.parse('$_baseUrl/teams/$teamId'))
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['name'] = name;

    if (zone != null) request.fields['zone'] = zone;
    if (address != null) request.fields['address'] = address;
    if (color != null) request.fields['color'] = color;
    if (lat != null) request.fields['lat'] = lat.toString();
    if (lng != null) request.fields['lng'] = lng.toString();

    if (logoBytes != null && logoFilename != null) {
      request.files.add(
        http.MultipartFile.fromBytes('logo', logoBytes, filename: logoFilename),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur modification équipe: ${response.body}');
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

  Future<Map<String, dynamic>> getTeamDetail(
    String token,
    String teamId,
  ) async {
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
      throw Exception(
        'Erreur lors de la tentative de rejoindre: ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> getComposition(
    String token,
    String teamId,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/teams/$teamId/composition'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement composition: ${response.body}');
  }

  Future<List<dynamic>> getCompositions(String token, String teamId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/teams/$teamId/compositions'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement compositions: ${response.body}');
  }

  Future<Map<String, dynamic>> saveComposition(
    String token,
    String teamId,
    String formation,
    List<Map<String, dynamic>> lineup, {
    String format = '5v5',
    int playerCount = 5,
    String? name,
    bool? isDefault,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/teams/$teamId/composition'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'format': format,
        'playerCount': playerCount,
        'formation': formation,
        'lineup': lineup,
        if (name != null) 'name': name,
        if (isDefault != null) 'isDefault': isDefault,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201)
      return jsonDecode(response.body);
    throw Exception('Erreur sauvegarde composition: ${response.body}');
  }

  Future<List<dynamic>> searchTeams({
    String? zone,
    String? query,
    String? excludeId,
  }) async {
    final params = <String, String>{};
    if (zone != null && zone.isNotEmpty && zone != 'Toutes')
      params['zone'] = zone;
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (excludeId != null) params['excludeId'] = excludeId;

    final uri = Uri.parse(
      '$_baseUrl/teams/search',
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur recherche équipes: ${response.body}');
  }

  Future<List<dynamic>> getZones() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/teams/zones'))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [
      'Dakar',
      'Guédiawaye',
      'Pikine',
      'Rufisque',
      'Thiès',
      'Saint-Louis',
    ];
  }
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
