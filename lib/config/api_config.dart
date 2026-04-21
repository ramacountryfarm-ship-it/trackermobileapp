class ApiConfig {
  // Your machine's IP - phone must be on same WiFi
  static const String baseUrl = 'https://backend-1hn7.onrender.com/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
