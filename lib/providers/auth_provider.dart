import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class User {
  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? birthDate;
  final String? position;
  final String? teamName;
  final int matchesCount;
  final int goalsCount;
  final int assistsCount;
  final List<dynamic> upcomingMatches;
  final String? avatarUrl;

  User({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.position,
    this.teamName,
    this.matchesCount = 0,
    this.goalsCount = 0,
    this.assistsCount = 0,
    this.upcomingMatches = const [],
    this.avatarUrl,
  });


  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: json['birthDate'],
      position: json['position'],
      teamName: json['team']?['name'],
      matchesCount: json['stats']?['matches'] ?? 0,
      goalsCount: json['stats']?['goals'] ?? 0,
      assistsCount: json['stats']?['assists'] ?? 0,
      upcomingMatches: json['upcomingMatches'] ?? [],
      avatarUrl: json['avatarUrl'],
    );
  }
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<bool> tryAutoLogin() async {
    debugPrint('Checking auto login...');
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      debugPrint('No token found in storage.');
      return false;
    }

    final token = prefs.getString('token')!;
    final tokenPreview = token.length > 10 ? '${token.substring(0, 10)}...' : token;
    debugPrint('Token found: $tokenPreview');
    try {
      final userData = await _authService.getProfile(token);
      _token = token;
      _user = User.fromJson(userData);
      NotificationService().init(token);
      notifyListeners();
      debugPrint('Auto login successful for user: ${_user?.firstName}');
      return true;
    } catch (e) {
      debugPrint('Auto login failed: $e');
      prefs.remove('token');
      return false;
    }
  }

  Future<void> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('Tentative de connexion pour $phone...');
      final result = await _authService.login(phone, password);
      debugPrint('Réponse login reçue: ${result.keys}');
      
      _token = result['token'];
      if (result['user'] == null) {
        debugPrint('Erreur: L\'objet user est manquant dans la réponse');
        throw Exception('Données utilisateur manquantes');
      }
      
      try {
        _user = User.fromJson(result['user']);
        debugPrint('Utilisateur parsé avec succès: ${_user?.firstName}');
      } catch (e) {
        debugPrint('Erreur lors du parsing de l\'utilisateur: $e');
        rethrow;
      }

      NotificationService().init(_token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      debugPrint('Connexion finalisée et token enregistré.');
    } catch (e) {
      debugPrint('Échec de la connexion dans AuthProvider: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> signup(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.startSignup(phone);
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.resendOtp(phone);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.verifyOtp(phone, code);
      return result['verified'] == true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.register(
        phone: phone,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      _token = result['token'];
      _user = User.fromJson(result['user']);
      NotificationService().init(_token);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', _token!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadAvatar(List<int> bytes, String filename) async {
    if (_token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final userData = await _authService.uploadAvatar(_token!, bytes, filename);
      _user = User.fromJson(userData);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final userData = await _authService.updateProfile(_token!, data);
      _user = User.fromJson(userData);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    notifyListeners();
  }
}
