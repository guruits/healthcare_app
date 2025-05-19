import 'dart:io';

class IpConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://drtirupathy.xyz:3000';
      return 'http://192.168.0.219:3000'; //gits wifi
    } else {
      return 'http://106.51.2.179:3000';
    }
  }
}
