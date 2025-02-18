import 'dart:io';

class IpConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.1.21:3000';
      //return 'http://49.43.250.243:3000';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    } else {
      return 'http://192.168.29.36:3000';
    }
  }
}