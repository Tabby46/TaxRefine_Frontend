class AuthSession {
  static String? jwt;
  static String? userId;
  static String? email;
  static String? name;
  static bool showDashboardRefreshHint = false;

  static bool get isAuthenticated => jwt != null && jwt!.isNotEmpty;

  static void clear() {
    jwt = null;
    userId = null;
    email = null;
    name = null;
    showDashboardRefreshHint = false;
  }
}
