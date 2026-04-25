import 'package:flutter/material.dart';
import '../terrain_data.dart';
import '../services/terrain_service.dart';

class TerrainProvider with ChangeNotifier {
  final TerrainService _service = TerrainService();

  List<Terrain> _terrains = [];
  bool _isLoading = false;
  String? _error;

  List<Terrain> get terrains => _terrains;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTerrains({String? search, String? zone}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _terrains = await _service.fetchTerrains(search: search, zone: zone);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
