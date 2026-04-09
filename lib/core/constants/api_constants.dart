import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Automatically switch between Android Emulator and iOS/Web/Physical Device
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:9090/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://192.168.1.7:9090/api/v1';
    } else {
      return 'http://localhost:9090/api/v1';
    }
  }

  static const String defaultUserId = '00000000-0000-0000-0000-000000000001';
  // On Android we prefer google-services.json package/SHA binding.
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
        '822869974213-0476p3thmqkj01fmr2d8irmjimvj5oaf.apps.googleusercontent.com',
  );
  // Web/server OAuth client id used by backend token audience verification.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '822869974213-n6t87vahi5jc198sdqtr3v1bgmio74d3.apps.googleusercontent.com',
  );
}
