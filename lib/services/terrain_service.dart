import '../terrain_data.dart';
import 'api_service.dart';

class TerrainService {
  final ApiService _api = ApiService();

  Future<List<Terrain>> fetchTerrains({String? token, String? search, String? zone, int page = 1, int limit = 20, double? lat, double? lng}) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (zone != null) params['zone'] = zone;
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();

    final queryString = Uri(queryParameters: params).query;
    final url = '/terrains?$queryString';

    final data = await _api.get(url, token: token, defaultErrorMsg: 'Erreur chargement terrains');
    final list = data['data'] as List<dynamic>;
    return list.map((j) => Terrain.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Terrain> fetchTerrain(String id, {String? token}) async {
    final data = await _api.get('/terrains/$id', token: token, defaultErrorMsg: 'Terrain introuvable');
    return Terrain.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TerrainSlot>> fetchSlots(String terrainId, String date, {String? token, String? subTerrainId}) async {
    final params = <String, String>{'date': date};
    if (subTerrainId != null) params['subTerrainId'] = subTerrainId;
    
    final queryString = Uri(queryParameters: params).query;
    final list = await _api.get('/terrains/$terrainId/slots?$queryString', token: token, defaultErrorMsg: 'Erreur chargement créneaux');
    
    return (list as List).map((j) => TerrainSlot.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Terrain>> fetchFavoriteTerrains(String token) async {
    final list = await _api.get('/users/me/favorites', token: token, defaultErrorMsg: 'Erreur chargement favoris');
    return (list as List).map((j) => Terrain.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<bool> toggleFavorite(String token, String terrainId) async {
    final data = await _api.post('/users/me/favorites/$terrainId', body: {}, token: token, defaultErrorMsg: 'Erreur toggle favori');
    return data['favorited'] as bool;
  }

  Future<List<TerrainReview>> fetchReviews(String terrainId, {String? token}) async {
    try {
      final list = await _api.get('/terrains/$terrainId/reviews', token: token);
      return (list as List).map((j) => TerrainReview.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<TerrainReview?> addReview(String token, String terrainId, int rating, String? comment) async {
    try {
      final data = await _api.post(
        '/terrains/$terrainId/reviews',
        body: {'rating': rating, 'comment': comment},
        token: token,
      );
      return TerrainReview.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<Terrain>> fetchAvailableTerrains(String date, String startTime, int durationMin, {String? token}) async {
    final params = {
      'date': date,
      'startTime': startTime,
      'durationMin': durationMin.toString(),
    };
    final queryString = Uri(queryParameters: params).query;
    
    final list = await _api.get('/terrains/available?$queryString', token: token, defaultErrorMsg: 'Erreur chargement terrains disponibles');
    return (list as List).map((j) => Terrain.fromJson(j as Map<String, dynamic>)).toList();
  }
}
