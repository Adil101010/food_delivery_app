import 'package:dio/dio.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,               
      connectTimeout: ApiConfig.connectTimeout, 
      receiveTimeout: ApiConfig.receiveTimeout, 
      sendTimeout: ApiConfig.sendTimeout,       
      headers: {'Content-Type': 'application/json'},
    ));

    
    if (ApiConfig.isDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

    //  Auth interceptor — token attach + silent refresh
    dio.interceptors.add(AuthInterceptor(dio: dio));
  }
}
