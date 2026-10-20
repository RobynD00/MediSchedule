 
import 'dart:convert';
 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
 
class MedicationService {
  MedicationService({
    this.baseUrl = 'http://10.0.2.2:8080',
  });
 
  final String baseUrl;
  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();
 
  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'auth_token');
 
    if (token == null || token.isEmpty) {
      throw Exception(
        'You are not logged in. Please sign in first.',
      );
    }
 
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
 
  Future<List<Map<String, dynamic>>> getMedications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/medications'),
      headers: await _headers(),
    );
 
    if (response.statusCode != 200) {
      throw Exception(
        'Could not load medications (${response.statusCode}).',
      );
    }
 
    final List<dynamic> data = jsonDecode(response.body);
 
    return data
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
 
  Future<Map<String, dynamic>> createMedication({
    required String name,
    required String dosage,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/medications'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'dosage': dosage,
        'notes': notes,
      }),
    );
 
    if (response.statusCode != 201) {
      throw Exception(
        'Could not save medication (${response.statusCode}).',
      );
    }
 
    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
 
  Future<Map<String, dynamic>> updateMedication({
    required int id,
    required String name,
    required String dosage,
    String? notes,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/medications/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'dosage': dosage,
        'notes': notes,
      }),
    );
 
    if (response.statusCode != 200) {
      throw Exception(
        'Could not update medication (${response.statusCode}).',
      );
    }
 
    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
 
  Future<void> deleteMedication(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/medications/$id'),
      headers: await _headers(),
    );
 
    if (response.statusCode != 204) {
      throw Exception(
        'Could not delete medication (${response.statusCode}).',
      );
    }
  }
}
 
