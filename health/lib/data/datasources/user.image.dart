//get a user image from Database
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/config/ipconfig.dart';

class UserImageService {

  UserImageService() {
  }



  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    if (token == null) {
      throw Exception('No authentication token found');
    }
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  String getUserImageUrl(String userId, {int quality = 50}) {
    return '${IpConfig.baseUrl}/api/auth/user/compressedimage/$userId/image?quality=$quality';
  }



  Future<bool> checkImageExists(String userId) async {
    try {
      final response = await http.head(
        Uri.parse(getUserImageUrl(userId)),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}