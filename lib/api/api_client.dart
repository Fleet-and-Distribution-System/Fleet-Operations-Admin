import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiBaseUrl = 'https://fleet-and-distribution-system-production.up.railway.app';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class ApiClient {
  static const _tokenKey = 'accessToken';

  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> get isLoggedIn async => (await _token) != null;

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _token;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Future.value(body);
    }
    final message = body is Map && body['message'] != null
        ? body['message'].toString()
        : 'Request failed (${response.statusCode})';
    throw ApiException(message, response.statusCode);
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(Uri.parse('$apiBaseUrl$path'), headers: await _headers());
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> data, {bool auth = true}) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }
}
