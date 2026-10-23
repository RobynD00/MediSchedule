import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Error shown to the user. The message is always simple, non-technical language.
class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, {this.status});

  @override
  String toString() => message;
}

// Thin wrapper around the backend REST API.
// After login, set ApiClient.token = <jwt from POST /api/auth/login> so every call is authenticated.
class ApiClient {
  // 10.0.2.2 reaches the laptop from the Android emulator. For a real phone use the laptop IP:
  // flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  // JWT of the logged-in user. Null means nobody is logged in.
  static String? token;

  static Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  static Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  static Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  static Future<dynamic> delete(String path) => _send('DELETE', path);

  static Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    if (token == null) {
      throw const ApiException('Please log in to continue.', status: 401);
    }
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      final text = utf8.decode(response.bodyBytes);
      final json = text.isEmpty ? null : jsonDecode(text);

      if (response.statusCode >= 200 && response.statusCode < 300) return json;

      // Backend errors look like {"status":404,"message":"Medication not found."}
      final message = json is Map && json['message'] is String
          ? json['message'] as String
          : 'Something went wrong. Please try again.';
      throw ApiException(message, status: response.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('The server took too long to answer. Please try again.');
    } on Exception {
      throw const ApiException(
        'We could not reach the server. Check your internet connection and try again.',
      );
    }
  }
}
