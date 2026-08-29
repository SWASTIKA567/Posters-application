import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Set to your laptop's local network Wi-Fi IP so phones on the same Wi-Fi can connect.
  // For production / deployment, replace with your cloud backend URL (e.g. Render, Railway, AWS).
  static const String serverHost = '192.168.1.4'; // Your PC's Wi-Fi IPv4 address
  static const String serverPort = '5000';

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$serverPort/api/v1';
    return 'http://$serverHost:$serverPort/api/v1';
  }

  static const String _tokenKey = 'auth_token';
  static String? _authToken;

  static Future<void> setAuthToken(String? token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_tokenKey, token);
      } else {
        await prefs.remove(_tokenKey);
      }
    } catch (e) {
      debugPrint('Storage notice: $e');
    }
  }

  static Future<String?> loadSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenKey);
      return _authToken;
    } catch (e) {
      debugPrint('Storage notice: $e');
      return _authToken;
    }
  }

  static bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  static String? get authToken => _authToken;

  static Map<String, String> _headers({bool isJson = true}) {
    final headers = <String, String>{};
    if (isJson) headers['Content-Type'] = 'application/json';
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ── GET Request ─────────────────────────────────────────────────────────────
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception: ')) {
        rethrow;
      }
      throw Exception('Server unreachable. Please check if the backend is running.');
    }
  }

  // ── POST Request ────────────────────────────────────────────────────────────
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception: ')) {
        final str = e.toString().replaceFirst('Exception: ', '');
        if (!str.startsWith('Network error') && !str.startsWith('ClientException')) {
          throw Exception(str);
        }
      }
      throw Exception('Unable to connect to server. Please check your connection.');
    }
  }

  // ── PUT Request ─────────────────────────────────────────────────────────────
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception: ')) {
        final str = e.toString().replaceFirst('Exception: ', '');
        if (!str.startsWith('Network error') && !str.startsWith('ClientException')) {
          throw Exception(str);
        }
      }
      throw Exception('Unable to connect to server. Please check your connection.');
    }
  }

  // ── PATCH Request ────────────────────────────────────────────────────────────
  static Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception: ')) {
        final str = e.toString().replaceFirst('Exception: ', '');
        if (!str.startsWith('Network error') && !str.startsWith('ClientException')) {
          throw Exception(str);
        }
      }
      throw Exception('Unable to connect to server. Please check your connection.');
    }
  }

  // ── DELETE Request ──────────────────────────────────────────────────────────
  static Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception: ')) {
        final str = e.toString().replaceFirst('Exception: ', '');
        if (!str.startsWith('Network error') && !str.startsWith('ClientException')) {
          throw Exception(str);
        }
      }
      throw Exception('Unable to connect to server. Please check your connection.');
    }
  }

  // ── Multipart File Upload ───────────────────────────────────────────────────
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _processResponse(response);

      if (data['success'] == true && data['imageUrl'] != null) {
        return data['imageUrl'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Upload Image Exception: $e');
      return null;
    }
  }

  // ── Helper Response Handler ─────────────────────────────────────────────────
  static dynamic _processResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final message = body['message'] ?? 'An error occurred (${response.statusCode})';
      throw Exception(message);
    }
  }
}
