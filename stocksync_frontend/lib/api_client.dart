import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static String get _baseUrl {
  if (kReleaseMode) {
    return 'http://10.76.214.48:5000/api/v1';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.76.214.48:5000/api/v1';
  }
  return 'http://localhost:5000/api/v1';
}

  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> _headers({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  static Uri _uri(String path) {
    return Uri.parse('$_baseUrl$path');
  }

  static Future<dynamic> get(String path) async {
    final response = await http.get(_uri(path), headers: _headers());
    return _handleResponse(response);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> delete(String path) async {
    final response = await http.delete(
      _uri(path),
      headers: _headers(),
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final dynamic data = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    final message = (data is Map && data['message'] is String)
        ? data['message'] as String
        : 'Request failed with status $statusCode';

    throw Exception(message);
  }
}
