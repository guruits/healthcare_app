import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../utils/config/ipconfig.dart';

class LoginController {
  FlutterTts flutterTts = FlutterTts();
  bool isMuted = false;
  String selectedLanguage = 'en-US';
  bool phoneReadOnly = false;
  bool showContinueButton = false;
  bool showUserDropdown = false;
  bool showLoginButton = false;
  bool isPhoneEntered = false;
  String selectedUser = '';
  String selectedCountry = "India";

  // Sample data for users
  Map<String, Map<String, String>> userData = {};
  String? storedPassword;

  TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Function to change language
  void changeLanguage(String langCode) async {
    selectedLanguage = langCode;
    await flutterTts.setLanguage(langCode);
    await flutterTts.speak("Language changed");
  }

  // Mute/Unmute the sound
  void toggleMute() {
    isMuted = !isMuted;
  }
  // Save user details in SharedPreferences
  Future<void> saveUserDetails(Map<String, dynamic> responseBody) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> permissions = responseBody['user']['role']['permissions'] ?? [];

    // Structured user details saving
    final userDetails = {
      'id': responseBody['user']['id'],
      'name': responseBody['user']['name'],
      'phone_number': responseBody['user']['phone_number'],

      'role': {
        'id': responseBody['user']['role']['id'],
        'rolename': responseBody['user']['role']['name'],
        'Permissions': permissions,
      }
    };

    await prefs.setString('userDetails', json.encode(userDetails));
    print("saved user details sf:$userDetails");
    await prefs.setString('userToken', responseBody['token'] ?? '');
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userDetails');
    return userJson != null ? json.decode(userJson) : null;
  }

  /*Future<Map<String, Map<String, dynamic>>> fetchUserDetails(
      String phoneNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${IpConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        await saveUserDetails(responseBody);

        print("saved user details fetch: $responseBody");
        final authService = Provider.of<AuthLogin>(navigatorKey.currentContext!, listen: false);

        // Login using AuthService
        await authService.login(responseBody['user'], responseBody['token']);

        return {
          responseBody['user']['name']: {
            'FullName': responseBody['user']['name'] ?? 'Not available',
            'Phone': responseBody['user']['phone_number'] ?? 'Not available',
            'Role': responseBody['user']['role']['rolename'] ?? 'Patient',
            'Token': responseBody['token'] ?? '',
            'Permissions': responseBody['user']['permissions'] ?? [],
          }
        };
      } else {
        throw Exception(responseBody['message'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      rethrow;
    }
  }
}*/

Future<Map<String, Map<String, dynamic>>> fetchUserDetails(
    String phoneNumber,
    String password,
    BuildContext context) async {
  try {
    final response = await http.post(
      Uri.parse('${IpConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phone_number': phoneNumber,
        'password': password,
      }),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      await saveUserDetails(responseBody);
      // Get the AuthLogin instance
      //final authLogin = Provider.of<AuthLogin>(context, listen: false);

      // Login using AuthLogin
     // await authLogin.login(responseBody['user'], responseBody['token']);

      return {
        responseBody['user']['name']: {
          'FullName': responseBody['user']['name'] ?? 'Not available',
          'Phone': responseBody['user']['phone_number'] ?? 'Not available',
          'Role': responseBody['user']['role']['rolename'] ?? 'Patient',
          'Token': responseBody['token'] ?? '',
          'Permissions': responseBody['user']['permissions'] ?? [],
        }
      };
    } else {
      throw Exception(responseBody['message'] ?? 'Login failed');
    }
  } catch (e) {
    debugPrint('Error fetching user details: $e');
    rethrow;
  }
}}

class AuthLogin extends ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get token => _token;

  // Initialize auth state
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userDetails');
    final storedToken = prefs.getString('userToken');

    if (userJson != null && storedToken != null) {
      _currentUser = json.decode(userJson);
      _token = storedToken;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // Login
  Future<void> login(Map<String, dynamic> userData, String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userDetails', json.encode(userData));
    await prefs.setString('userToken', token);

    _currentUser = userData;
    _token = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('userDetails');
    await prefs.remove('userToken');

    _currentUser = null;
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Check if token exists and is valid
  Future<bool> validateSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('userToken');

    if (storedToken == null) {
      await logout();
      return false;
    }

    return true;
  }
}