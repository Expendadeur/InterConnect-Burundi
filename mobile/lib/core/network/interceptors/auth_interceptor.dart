import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/env_config.dart';
import '../../utils/logger.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage storage;
  bool _isRefreshing = false;

  AuthInterceptor({required this.dio, required this.storage});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    if (path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    final token = await storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final newToken = await storage.read(key: 'access_token');
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final clonedRequest = await dio.fetch(opts);
          _isRefreshing = false;
          return handler.resolve(clonedRequest);
        }
      } catch (e) {
        AppLogger.e('Token refresh failed', error: e);
      } finally {
        _isRefreshing = false;
      }

      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: '${EnvConfig.apiBaseUrl}/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await storage.write(key: 'access_token', value: data['access_token']);
        if (data['refresh_token'] != null) {
          await storage.write(key: 'refresh_token', value: data['refresh_token']);
        }
        return true;
      }
    } catch (e) {
      AppLogger.e('Token refresh error', error: e);
    }
    return false;
  }
}
