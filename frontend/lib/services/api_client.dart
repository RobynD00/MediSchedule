import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, {this.status});

  @override
  String toString() => message;
}

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static String? token;

  static final ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);

  static void setToken(String? value) {
    token = value;
    loggedIn.value = value != null;
  }

  static Future<dynamic> postPublic(String path, {Object? body}) =>
      _send('POST', path, body: body, requireToken: false);

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
    bool requireToken = true,
  }) async {
    if (requireToken && token == null) {
      throw const ApiException('Please log in to continue.', status: 401);
    }
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      final text = utf8.decode(response.bodyBytes);
      final json = text.isEmpty ? null : jsonDecode(text);

      if (response.statusCode >= 200 && response.statusCode < 300) return json;

      final message = json is Map && json['message'] is String
          ? json['message'] as String
          : 'Something went wrong. Please try again.';
      if (response.statusCode == 401 && requireToken) setToken(null);
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