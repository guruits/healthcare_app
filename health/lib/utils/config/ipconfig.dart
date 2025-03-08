import 'dart:io';

class IpConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.177.55:3000';
      return 'http://192.168.29.36:3000';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    } else {
      return 'http://192.168.29.36:3000';
    }
  }
}