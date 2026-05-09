import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String phone, String password) async {
    return await _api.post(
      '/auth/login',
      body: {'phone': phone, 'password': password},
      defaultErrorMsg: 'AUTH_INVALID', // To mimic the specific throw in original code, ApiService catches it
    );
  }

  Future<Map<String, dynamic>> forgotPassword(String phone) async {
    return await _api.post(
      '/auth/forgot-password',
      body: {'phone': phone},
      defaultErrorMsg: 'Erreur lors de l\'envoi du code',
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String code,
    required String password,
  }) async {
    return await _api.post(
      '/auth/reset-password',
      body: {'phone': phone, 'code': code, 'password': password},
      defaultErrorMsg: 'Erreur lors de la réinitialisation',
    );
  }

  Future<Map<String, dynamic>> startSignup(String phone) async {
    return await _api.post(
      '/auth/signup',
      body: {'phone': phone},
      defaultErrorMsg: 'Erreur lors de l\'inscription',
    );
  }

  Future<Map<String, dynamic>> resendOtp(String phone) async {
    return await _api.post(
      '/auth/resend-otp',
      body: {'phone': phone},
      defaultErrorMsg: 'Erreur lors de l\'envoi du code',
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    return await _api.post(
      '/auth/verify-otp',
      body: {'phone': phone, 'code': code},
      defaultErrorMsg: 'Code OTP invalide ou expiré',
    );
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return await _api.post(
      '/auth/register',
      body: {
        'phone': phone,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      },
      defaultErrorMsg: 'Erreur lors de l\'inscription',
    );
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    return await _api.get(
      '/users/me',
      token: token,
      defaultErrorMsg: 'Erreur de récupération du profil',
    );
  }

  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> data,
  ) async {
    return await _api.patch(
      '/users/me',
      token: token,
      body: data,
      defaultErrorMsg: 'Erreur lors de la mise à jour du profil',
    );
  }

  Future<Map<String, dynamic>> uploadAvatar(
    String token,
    List<int> bytes,
    String filename,
  ) async {
    return await _api.multipart(
      '/users/me/avatar',
      'POST',
      bytes,
      filename,
      'file',
      token: token,
      defaultErrorMsg: 'Erreur d\'upload avatar',
    );
  }
}
