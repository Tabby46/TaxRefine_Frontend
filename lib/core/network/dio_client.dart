import 'package:dio/dio.dart';
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
          final effectiveUserId = AuthSession.userId ?? _userId;
          options.headers['X-User-Id'] = _isValidUuid(effectiveUserId)
              ? effectiveUserId
              : ApiConstants.defaultUserId;

          final jwt = AuthSession.jwt;
          if (jwt != null && jwt.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $jwt';
          }

          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final String _userId;

  static bool _isValidUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }
}
