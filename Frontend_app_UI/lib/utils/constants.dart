import 'package:flutter/foundation.dart';

class AppConstants {
  static const String baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://192.168.29.230:3000';
  static const String socketUrl = kIsWeb ? 'http://localhost:3000' : 'http://192.168.29.230:3000';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
