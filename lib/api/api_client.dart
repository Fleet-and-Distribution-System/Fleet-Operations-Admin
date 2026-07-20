import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
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
  static const _roleKey = 'userRole';

  Future<String?> get _token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token, {String? role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (role != null) await prefs.setString(_roleKey, role);
  }

  Future<String?> get role async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
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

  Future<Uint8List> getBytes(String path) async {
    final response = await http.get(Uri.parse('$apiBaseUrl$path'), headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Download failed (${response.statusCode})', response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<dynamic> uploadFile(String path, String fieldName, XFile file) async {
    final request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl$path'));
    final token = await _token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: file.name,
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}
