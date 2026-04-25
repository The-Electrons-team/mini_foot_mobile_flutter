import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../terrain_data.dart';

class TerrainService {
  final String _base = dotenv.get('API_URL');

  Future<List<Terrain>> fetchTerrains({String? search, String? zone}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (zone != null) params['zone'] = zone;

    final uri = Uri.parse('$_base/terrains')
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List<dynamic>;
      return list.map((j) => Terrain.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur chargement terrains: ${response.statusCode}');
  }

  Future<Terrain> fetchTerrain(String id) async {
    final response = await http.get(Uri.parse('$_base/terrains/$id'));
    if (response.statusCode == 200) {
      return Terrain.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Terrain introuvable');
  }

  Future<List<TerrainSlot>> fetchSlots(String terrainId, String date) async {
    final response = await http.get(
      Uri.parse('$_base/terrains/$terrainId/slots?date=$date'),
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => TerrainSlot.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur chargement créneaux');
  }
}
