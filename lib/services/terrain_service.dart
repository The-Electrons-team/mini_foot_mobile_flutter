import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../terrain_data.dart';

class TerrainService {
  static String _resolveBaseUrl() {
    try {
      return dotenv.env['API_URL'] ?? 'http://localhost:3000/api/v1';
    } catch (_) {
      return 'http://localhost:3000/api/v1';
    }
  }

  final String _base = _resolveBaseUrl();

  Future<List<Terrain>> fetchTerrains({String? search, String? zone, int page = 1, int limit = 20, double? lat, double? lng}) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (zone != null) params['zone'] = zone;
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();

    final uri = Uri.parse('$_base/terrains')
        .replace(queryParameters: params);

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List<dynamic>;
      return list.map((j) => Terrain.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur chargement terrains: ${response.statusCode}');
  }

  Future<Terrain> fetchTerrain(String id) async {
    final response = await http.get(Uri.parse('$_base/terrains/$id')).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      return Terrain.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Terrain introuvable');
  }

  Future<List<TerrainSlot>> fetchSlots(String terrainId, String date, {String? subTerrainId}) async {
    final uri = Uri.parse('$_base/terrains/$terrainId/slots').replace(
      queryParameters: {
        'date': date,
        if (subTerrainId != null) 'subTerrainId': subTerrainId,
      },
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => TerrainSlot.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur chargement créneaux');
  }

  Future<List<Terrain>> fetchFavoriteTerrains(String token) async {
    final response = await http.get(
      Uri.parse('$_base/users/me/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => Terrain.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur chargement favoris');
  }

  Future<bool> toggleFavorite(String token, String terrainId) async {
    final response = await http.post(
      Uri.parse('$_base/users/me/favorites/$terrainId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['favorited'] as bool;
    }
    throw Exception('Erreur toggle favori');
  }

  Future<List<TerrainReview>> fetchReviews(String terrainId) async {
    final response = await http.get(Uri.parse('$_base/terrains/$terrainId/reviews'));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => TerrainReview.fromJson(j as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<TerrainReview?> addReview(String token, String terrainId, int rating, String? comment) async {
    final response = await http.post(
      Uri.parse('$_base/terrains/$terrainId/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 201) {
      return TerrainReview.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Terrain>> fetchAvailableTerrains(String date, String startTime, int durationMin) async {
    final uri = Uri.parse('$_base/terrains/available').replace(
      queryParameters: {
        'date': date,
        'startTime': startTime,
        'durationMin': durationMin.toString(),
      },
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((j) => Terrain.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Erreur chargement terrains disponibles');
  }
}
