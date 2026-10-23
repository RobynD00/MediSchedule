import 'package:medischedule/services/api_client.dart';

class AuthService {
  static String fullName = '';
  static String role = '';
  static int? userId;

  static bool get isCaregiver => role == 'CAREGIVER';

  Future<bool> register({
    required String fullName,
    required String dateOfBirth,
    required String email,
    required String password,
    required String role,
    required bool acceptedTerms,
  }) async {
    await ApiClient.postPublic('/api/auth/register', body: {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'email': email,
      'password': password,
      'role': role,
      'acceptedTerms': acceptedTerms,
    });
    return true;
  }

  Future<bool> verifyOtp({required String email, required String code}) async {
    await ApiClient.postPublic('/api/auth/verify', body: {
      'identifier': email,
      'code': code,
    });
    return true;
  }

  Future<bool> resendOtp({required String email}) async {
    await ApiClient.postPublic('/api/auth/resend-code', body: {
      'identifier': email,
    });
    return true;
  }

  Future<bool> login({required String email, required String password}) async {
    final json = await ApiClient.postPublic('/api/auth/login', body: {
      'identifier': email,
      'password': password,
    });
    final data = json as Map<String, dynamic>;
    fullName = (data['fullName'] ?? '') as String;
    role = (data['role'] ?? '') as String;
    userId = (data['userId'] as num?)?.toInt();
    ApiClient.setToken(data['token'] as String);
    return true;
  }

  Future<bool> requestPasswordReset({required String email}) async {
    await ApiClient.postPublic('/api/auth/forgot-password', body: {
      'identifier': email,
    });
    return true;
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await ApiClient.postPublic('/api/auth/reset-password', body: {
      'identifier': email,
      'code': code,
      'newPassword': newPassword,
    });
    return true;
  }

  Future<bool> logout() async {
    try {
      await ApiClient.post('/api/auth/logout');
    } on ApiException catch (_) {}
    fullName = '';
    role = '';
    userId = null;
    ApiClient.setToken(null);
    return true;
  }
}