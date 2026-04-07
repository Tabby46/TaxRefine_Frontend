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
  static const String googleAndroidClientId =
      '212600925319-ov0ks3nqnt7ao8tmhfr4p0k0ahkbpsv2.apps.googleusercontent.com';
}
