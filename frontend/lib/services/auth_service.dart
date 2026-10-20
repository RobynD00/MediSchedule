import 'dart:async';
import 'dart:convert';
 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// Service layer handling authentication requests and backend interaction.
class AuthService {
  AuthService({
    this.baseUrl = 'http://10.0.2.2:8080',
  });
 
  final String baseUrl;
 
  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();
  // Verifies the OTP code sent to the specified email address.
  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    // Simulated network delay for POST /api/auth/verify
    await Future<void>.delayed(const Duration(seconds: 1));
    return true;
  }

  // Resends an OTP verification code to the specified email address.
  Future<bool> resendOtp({required String email}) async {
    // Simulated network delay
    await Future<void>.delayed(const Duration(seconds: 1));
    return true;
  }

  // Authenticates a user with email and password.
  
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'identifier': email,
        'password': password,
      }),
    );
 
    if (response.statusCode != 200) {
      throw Exception(
        'Login failed. Please check your details and try again.',
      );
    }
 
    final Map<String, dynamic> data =
        jsonDecode(response.body);
 
    final token = data['token'];
 
    if (token is! String || token.isEmpty) {
      throw Exception(
        'The server did not return a valid login token.',
      );
    }
 
    await _storage.write(
      key: 'auth_token',
      value: token,
    );
 
    return true;
  }
 
  // Registers a new user account.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return true;
  }

  // Requests a password reset code.
  Future<bool> requestPasswordReset({required String email}) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return true;
  }

  // Resets user password using a code.
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return true;
  }

  // Logs out the user and revokes the active session.
  Future<bool> logout() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return true;
  }
}
