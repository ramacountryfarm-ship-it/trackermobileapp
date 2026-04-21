import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // GET
  Future<Response> get(String path, {Map<String, dynamic>? query}) {
    return dio.get(path, queryParameters: query);
  }

  // POST
  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  // PUT
  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  // PATCH
  Future<Response> patch(String path, {dynamic data}) {
    return dio.patch(path, data: data);
  }

  // DELETE
  Future<Response> delete(String path) {
    return dio.delete(path);
  }
}
