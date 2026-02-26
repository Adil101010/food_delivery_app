import 'package:dio/dio.dart';
import 'api_config.dart';      
import 'token_manager.dart';   

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _queue = [];

  AuthInterceptor({required this.dio});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenManager.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final path = err.requestOptions.path;
    if (path.contains('/auth/refresh-token') ||
        path.contains('/auth/login')) {
      await _logout();
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      _queue.add(_PendingRequest(err.requestOptions, handler));
      return;
    }

    _isRefreshing = true;

    try {
      final newToken = await _doRefresh();

      if (newToken == null) {
        await _logout();
        _flushQueue(null);
        handler.next(err);
        return;
      }

      await TokenManager.updateAccessToken(newToken);
      final response = await _retry(err.requestOptions, newToken);
      handler.resolve(response);
      _flushQueue(newToken);
    } catch (e) {
      await _logout();
      _flushQueue(null);
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<String?> _doRefresh() async {
    try {
      final refreshToken = await TokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return null;

      
      final freshDio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      ));

      final response = await freshDio.post(
        '/api/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data['data']['accessToken'] as String?;
      }
      return null;
    } catch (e) {
      if (ApiConfig.isDebugMode) {
        print(' Token refresh failed: $e');
      }
      return null;
    }
  }

  Future<Response> _retry(RequestOptions options, String token) {
    options.headers['Authorization'] = 'Bearer $token';
    return dio.fetch(options);
  }

  void _flushQueue(String? newToken) {
    for (final pending in _queue) {
      if (newToken != null) {
        _retry(pending.options, newToken).then((res) {
          pending.handler.resolve(res);
        }).catchError((e) {
          pending.handler.next(e as DioException);
        });
      } else {
        pending.handler.next(DioException(
          requestOptions: pending.options,
          error: 'Session expired. Please login again.',
          type: DioExceptionType.badResponse,
        ));
      }
    }
    _queue.clear();
  }

  Future<void> _logout() async {
    await TokenManager.clearAuthData();
    if (ApiConfig.isDebugMode) {
      print(' Session expired — user logged out');
    }
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
  _PendingRequest(this.options, this.handler);
}
