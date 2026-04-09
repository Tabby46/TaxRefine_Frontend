class AuthSession {
  static String? jwt;
  static String? userId;
  static String? email;

  static bool get isAuthenticated => jwt != null && jwt!.isNotEmpty;

  static void clear() {
    jwt = null;
    userId = null;
    email = null;
  }
}
