import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class User {
  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? birthDate;

  User({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    this.birthDate,
  });


  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: json['birthDate'],
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
    debugPrint('Token found: ${token.substring(0, 10)}...');
    try {
      final userData = await _authService.getProfile(token);
      _token = token;
      _user = User.fromJson(userData);
      notifyListeners();
      debugPrint('Auto login successful for user: ${_user?.firstName}');
      return true;
    } catch (e) {
      debugPrint('Auto login failed: $e');
      prefs.remove('token');
      return false;
    }
  }

  Future<void> login(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.login(phone);
      _token = result['token'];
      _user = User.fromJson(result['user']);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', _token!);
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
    required String firstName,
    required String lastName,
    String? birthDate,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.register(
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
      );
      _token = result['token'];
      _user = User.fromJson(result['user']);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', _token!);
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
