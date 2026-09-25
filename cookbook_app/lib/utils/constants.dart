import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else {
      return 'http://10.27.249.28:5000/api';
    }
  }
}