import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../terrain_data.dart';
import '../services/terrain_service.dart';

class TerrainProvider with ChangeNotifier {
  final TerrainService _service = TerrainService();

  List<Terrain> _terrains = [];
  bool _isLoading = false;
  String? _error;

  int _page = 1;
  bool _hasMore = true;
  final int _limit = 10;

  List<Terrain> _favorites = [];
  bool _isFavLoading = false;
  
  Position? _userPosition;

  List<Terrain> get terrains => _terrains;
  List<Terrain> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isFavLoading => _isFavLoading;
  String? get error => _error;
  Position? get userPosition => _userPosition;
  bool get hasMore => _hasMore;

  Future<void> updateLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      _userPosition = await Geolocator.getCurrentPosition();
      notifyListeners();
      
      // Reload terrains with the new position to get proximity-sorted results from backend
      loadTerrains(refresh: true);
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  double distanceTo(Terrain t) {
    if (_userPosition == null) return 999999;
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      t.lat,
      t.lng,
    );
  }

  Future<void> loadTerrains({String? search, String? zone, bool refresh = true}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    
    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fetched = await _service.fetchTerrains(
        search: search,
        zone: zone,
        page: _page,
        limit: _limit,
        lat: _userPosition?.latitude,
        lng: _userPosition?.longitude,
      );
      
      if (refresh) {
        _terrains = fetched;
      } else {
        _terrains.addAll(fetched);
      }
      
      _hasMore = fetched.length >= _limit;
      if (fetched.isNotEmpty) _page++;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTerrains({String? search, String? zone}) async {
    await loadTerrains(search: search, zone: zone, refresh: false);
  }

  Future<void> loadFavorites(String token) async {
    if (_isFavLoading) return;
    _isFavLoading = true;
    _error = null;
    notifyListeners();
    final tokenPreview = token.length > 10 ? '${token.substring(0, 10)}...' : token;
    debugPrint('Loading favorites with token: $tokenPreview');
    try {
      _favorites = await _service.fetchFavoriteTerrains(token);
      debugPrint('Loaded ${_favorites.length} favorites');
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _error = e.toString();
    } finally {
      _isFavLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String token, String terrainId) async {
    try {
      final isFav = await _service.toggleFavorite(token, terrainId);
      // Refresh local list if needed, or reload
      await loadFavorites(token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
