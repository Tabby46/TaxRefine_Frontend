import 'package:dio/dio.dart';
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
          options.headers.putIfAbsent('X-User-Id', () => _userId);
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final String _userId;
}
