import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/api_constants.dart';
import 'package:taxrefine/data/providers/auth_api_provider.dart';

class AuthRepository {
  AuthRepository(this._apiProvider, {GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const List<String> _authScopes = ['openid', 'email', 'profile'];

  final AuthApiProvider _apiProvider;
  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  Future<void> signInWithGoogle() async {
    await _ensureInitialized();

    final account = await _googleSignIn.authenticate(scopeHint: _authScopes);
    final auth = account.authentication;
    final idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('Google ID token not available');
    }

    final response = await _apiProvider.exchangeGoogleIdToken(idToken: idToken);
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw const AuthException('Invalid auth response from server');
    }

    final jwt = (payload['jwt'] as String?) ?? '';
    final userId = (payload['userId'] as String?) ?? '';
    final email = (payload['email'] as String?) ?? '';

    if (jwt.isEmpty || userId.isEmpty) {
      throw const AuthException('Server auth response is missing JWT/user id');
    }

    AuthSession.jwt = jwt;
    AuthSession.userId = userId;
    AuthSession.email = email;
  }

  Future<void> signOut() async {
    AuthSession.clear();
    await _googleSignIn.signOut();
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }

    final serverClientId = ApiConstants.googleServerClientId.trim();
    if (serverClientId.isEmpty) {
      throw const AuthException(
        'Google server client ID is missing. Set GOOGLE_SERVER_CLIENT_ID.',
      );
    }

    if (Platform.isAndroid) {
      await _googleSignIn.initialize(serverClientId: serverClientId);
    } else {
      final androidClientId = ApiConstants.googleAndroidClientId.trim();
      await _googleSignIn.initialize(
        clientId: androidClientId.isEmpty ? null : androidClientId,
        serverClientId: serverClientId,
      );
    }
    _isInitialized = true;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
