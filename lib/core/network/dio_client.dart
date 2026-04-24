import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/api_constants.dart';

class DioClient {
  DioClient({Dio? dio, String userId = ApiConstants.defaultUserId})
    : _userId = userId,
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final effectiveUserId = ApiConstants.resolveUserId(
            AuthSession.userId ?? _userId,
          );
          options.headers['X-User-Id'] = effectiveUserId;

          final jwt = AuthSession.jwt;
          if (jwt != null && jwt.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $jwt';
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode && _shouldLog(response.requestOptions)) {
            debugPrint(
              '[API] ${response.requestOptions.method} '
              '${response.requestOptions.path} -> ${response.statusCode}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode && _shouldLog(error.requestOptions)) {
            debugPrint(
              '[API][ERROR] ${error.requestOptions.method} '
              '${error.requestOptions.path} -> ${error.response?.statusCode ?? 'NO_STATUS'} '
              '(${error.type.name})',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final String _userId;

  bool _shouldLog(RequestOptions options) {
    return options.path.contains('/transactions') ||
        options.path.contains('/reports/');
  }
}
