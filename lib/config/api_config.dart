class ApiConfig {
  // Your machine's IP - phone must be on same WiFi
  static const String baseUrl = 'http://192.168.1.41:5000/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
