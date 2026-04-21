import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _api.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = res.data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('username', data['user']?['username'] ?? username);
    return data;
  }

  Future<Map<String, dynamic>?> getMe() async {
    final res = await _api.get('/auth/me');
    return res.data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
}
