import 'package:flutter/foundation.dart';

import '../api_client.dart';
import '../models/app_user.dart';

class AuthProvider with ChangeNotifier {
  AppUser? _currentUser;
  String? _token;

  AppUser? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null && _token != null;

  Future<void> login(String username, String password) async {
    final Map<String, dynamic> body = {
      'username': username,
      'password': password,
    };

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

  Future<void> changePassword(String username, String oldPassword, String newPassword) async {
    final response = await ApiClient.post('/auth/change-password', {
      'username': username,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });

    if (response is! Map<String, dynamic>) {
      throw Exception('Unexpected response from server');
    }

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to change password');
    }
  }

  Future<void> changePhone(String username, String password, String newPhone) async {
    final response = await ApiClient.post('/auth/change-phone', {
      'username': username,
      'password': password,
      'newPhone': newPhone,
    });

    if (response is! Map<String, dynamic>) {
      throw Exception('Unexpected response from server');
    }

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to change phone number');
    }
  }
}
