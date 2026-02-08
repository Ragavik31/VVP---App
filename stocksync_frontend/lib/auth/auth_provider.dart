import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../models/app_user.dart';

class AuthProvider with ChangeNotifier {
  AppUser? _currentUser;
  String? _token;

  AppUser? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;

  Future<void> login(String password, {String? role, String? username}) async {
    final Map<String, dynamic> body = {'password': password};
    if (username != null) {
      body['username'] = username;
    } else if (role != null) {
      body['role'] = role;
    }

    final response = await ApiClient.post('/auth/login', body);

    if (response is! Map<String, dynamic>) {
      throw Exception('Unexpected response from server');
    }

    final success = response['success'] == true;
    if (!success) {
      throw Exception(response['message'] ?? 'Login failed');
    }

    final token = response['token'] as String?;
    final userData = response['user'] as Map<String, dynamic>?;

    if (token == null || userData == null) {
      throw Exception('Invalid login response');
    }

    _token = token;
    ApiClient.setToken(token);
    _currentUser = AppUser.fromJson(userData);

    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _token = null;
    ApiClient.setToken(null);
    notifyListeners();
  }
}
