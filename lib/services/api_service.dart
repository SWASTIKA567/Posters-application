import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Set to true for local testing, false for Render cloud deployment
  static const bool useLocalBackend = false;

  static const String liveBackendUrl = 'https://poster-backend-tjd5.onrender.com/api/v1';

  static String get baseUrl {
    if (!useLocalBackend) return liveBackendUrl;
    // Android emulator uses 10.0.2.2 to reach host PC localhost:5000
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    return 'http://localhost:5000/api/v1';
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

  // ── Clean Error Message Formatter ──────────────────────────────────────────
  /// Transforms any backend, network, database, or technical exception into a
  /// clean, polite, customer-facing message. No technical stack traces or
  /// developer jargon are ever shown to the user.
  static String cleanErrorMessage(
    dynamic error, {
    String defaultMessage = 'Something went wrong. Please try again.',
  }) {
    if (error == null) return defaultMessage;

    String msg = error.toString().trim();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring(11).trim();
    }

    final lower = msg.toLowerCase();

    // 1. Connection / Network / DNS / Timeout / Offline errors
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('network is unreachable') ||
        lower.contains('clientexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('timeoutexception') ||
        lower.contains('connection closed') ||
        lower.contains('network error') ||
        lower.contains('os error') ||
        lower.contains('backend is running') ||
        lower.contains('unable to connect') ||
        lower.contains('server unreachable')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    // 2. Server 500 / Bad Gateway / Cloud sleep / HTML responses
    if (lower.contains('formatexception') ||
        lower.contains('<!doctype') ||
        lower.contains('<html') ||
        lower.contains('502 bad gateway') ||
        lower.contains('503 service') ||
        lower.contains('504 gateway') ||
        lower.contains('internal server error') ||
        lower.contains('bad gateway') ||
        lower.contains('gateway time-out') ||
        lower.contains('service unavailable') ||
        lower.contains('an error occurred (50')) {
      return 'Our servers are temporarily busy. Please try again in a moment.';
    }

    // 3. Database / Technical stack trace errors
    if (lower.contains('e11000') ||
        lower.contains('mongo') ||
        lower.contains('cast to') ||
        lower.contains('referenceerror') ||
        lower.contains('typeerror') ||
        lower.contains('syntaxerror') ||
        lower.contains('null check operator') ||
        lower.contains('unhandled') ||
        lower.contains('stack trace') ||
        lower.contains('internal error')) {
      return 'Something went wrong. Please try again shortly.';
    }

    // 4. Session / JWT Token errors
    if (lower.contains('jwt expired') ||
        lower.contains('jwt malformed') ||
        lower.contains('invalid token') ||
        lower.contains('token has expired') ||
        lower.contains('not authorized')) {
      return 'Your session has expired. Please log in again.';
    }

    // 5. Firebase / Google Sign-in technical codes
    if (lower.contains('apiexception: 10') || lower.contains('sign_in_failed')) {
      return 'Google sign-in could not be completed. Please try again or use email.';
    }
    if (lower.contains('sign_in_canceled') || lower.contains('user cancelled')) {
      return 'Sign-in was cancelled.';
    }

    // If cleaned string is empty or looks like raw code
    if (msg.isEmpty || (msg.length > 150 && (lower.contains('{') || lower.contains('at ')))) {
      return defaultMessage;
    }

    return msg;
  }

  // ── GET Request ─────────────────────────────────────────────────────────────
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } catch (e) {
      throw Exception(cleanErrorMessage(e));
    }
  }

  // ── POST Request ────────────────────────────────────────────────────────────
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } catch (e) {
      throw Exception(cleanErrorMessage(e));
    }
  }

  // ── PUT Request ─────────────────────────────────────────────────────────────
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } catch (e) {
      throw Exception(cleanErrorMessage(e));
    }
  }

  // ── PATCH Request ────────────────────────────────────────────────────────────
  static Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } catch (e) {
      throw Exception(cleanErrorMessage(e));
    }
  }

  // ── DELETE Request ──────────────────────────────────────────────────────────
  static Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 35));
      return _processResponse(response);
    } catch (e) {
      throw Exception(cleanErrorMessage(e));
    }
  }

  // ── Multipart File Upload ───────────────────────────────────────────────────
  static Future<String?> uploadImage(File imageFile) async {
    try {
      if (_authToken == null || _authToken!.isEmpty) {
        await loadSavedToken();
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      final pathLower = imageFile.path.toLowerCase();
      String subType = 'jpeg';
      if (pathLower.endsWith('.png')) {
        subType = 'png';
      } else if (pathLower.endsWith('.webp')) {
        subType = 'webp';
      } else if (pathLower.endsWith('.gif')) {
        subType = 'gif';
      } else if (pathLower.endsWith('.heic')) {
        subType = 'heic';
      } else if (pathLower.endsWith('.heif')) {
        subType = 'heif';
      } else {
        subType = 'jpeg';
      }

      final fileName = 'poster_${DateTime.now().millisecondsSinceEpoch}.$subType';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: fileName,
          contentType: MediaType('image', subType),
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      final data = _processResponse(response);

      if (data['success'] == true && data['imageUrl'] != null) {
        return data['imageUrl'] as String;
      }
      throw Exception(cleanErrorMessage(data['message'] ?? 'Image upload failed.'));
    } catch (e) {
      debugPrint('Upload Image Notice: $e');
      throw Exception(cleanErrorMessage(e));
    }
  }

  // ── Helper Response Handler ─────────────────────────────────────────────────
  static dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 500) {
        throw Exception('Our servers are temporarily busy. Please try again shortly.');
      }
      throw Exception('Unable to complete request. Please try again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String? message;
      if (body is Map && body.containsKey('message')) {
        message = body['message']?.toString();
      }
      message ??= 'Request could not be completed (${response.statusCode})';
      throw Exception(cleanErrorMessage(message));
    }
  }
}
