import 'package:flutter/material.dart';
import '../services/team_service.dart';

class TeamProvider with ChangeNotifier {
  final TeamService _service = TeamService();
  List<dynamic> _myTeams = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<dynamic> get myTeams => _myTeams;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<void> loadMyTeams(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _myTeams = await _service.getMyTeams(token);
    } catch (e) {
      debugPrint('Error loading teams: $e');
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

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
    _isLoading = true;
    notifyListeners();
    try {
      final team = await _service.createTeam(
        token: token,
        name: name,
        zone: zone,
        address: address,
        color: color,
        lat: lat,
        lng: lng,
        logoBytes: logoBytes,
        logoFilename: logoFilename,
      );
      _myTeams.add(team);
      return team;
    } finally {
      _isLoading = false;
      notifyListeners();
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
    _isLoading = true;
    notifyListeners();
    try {
      final team = await _service.updateTeam(
        token: token,
        teamId: teamId,
        name: name,
        zone: zone,
        address: address,
        color: color,
        lat: lat,
        lng: lng,
        logoBytes: logoBytes,
        logoFilename: logoFilename,
      );
      final index = _myTeams.indexWhere(
        (item) => item['id']?.toString() == teamId,
      );
      if (index >= 0) {
        _myTeams[index] = team;
      } else {
        _myTeams.add(team);
      }
      return team;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinTeam(String token, String inviteCode) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.joinTeam(token, inviteCode);
      await loadMyTeams(token);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
