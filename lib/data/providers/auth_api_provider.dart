import 'package:dio/dio.dart';
import 'package:taxrefine/core/constants/api_constants.dart';

class AuthApiProvider {
  AuthApiProvider({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
            ),
          );

  final Dio _dio;

  Future<Response<dynamic>> exchangeGoogleIdToken({required String idToken}) {
    return _dio.post('/auth/google', data: {'idToken': idToken});
  }
}
