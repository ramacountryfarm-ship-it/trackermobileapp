import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _username;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get error => _error;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        _username = await _authService.getUsername();
      }
    } catch (_) {
      _isLoggedIn = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.login(username, password);
      _isLoggedIn = true;
      _username = username;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _username = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) return data['message'];
        if (e.response?.statusCode == 401) return 'Invalid username or password';
        return 'Server error: ${e.response?.statusCode}';
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Cannot connect to server. Check if backend is running.';
      }
      return 'Network error: ${e.message}';
    }
    return 'Error: $e';
  }
}
