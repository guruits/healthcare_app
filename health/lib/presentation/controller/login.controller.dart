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

    List<dynamic> permissions = [];
    if (responseBody['user']['role'] != null && responseBody['user']['role']['permissions'] != null) {
      permissions = List<dynamic>.from(responseBody['user']['role']['permissions']);
    }


    // Ensure permissions are properly structured for easier retrieval
    // Structured user details saving
    final userDetails = {
      'id': responseBody['user']['id'],
      'name': responseBody['user']['name'],
      'phone_number': responseBody['user']['phone_number'],
      'role': {
        'id': responseBody['user']['role']['id'],
        'rolename': responseBody['user']['role']['name'],
        'permissions': responseBody['user']['role']['permissions'] ?? [],
      }
    };

    // Debug log to verify permissions are being saved
    print("Saving permissions: $permissions");

    await prefs.setString('userDetails', json.encode(userDetails));
    print("saved user details sf:$userDetails");
    await prefs.setString('userToken', responseBody['token'] ?? '');
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userDetails');

    if (userJson != null) {
      final userMap = json.decode(userJson);
      print("Retrieved user details: $userMap");
      return userMap;
    }
    return null;
  }

  Future<Map<String, Map<String, dynamic>>> fetchUserDetails(
      String phoneNumber,
      String password,
      ) async {
    try {
      print('Attempting login with phone: $phoneNumber');

      final response = await http.post(
        Uri.parse('${IpConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      //print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        // Explicitly debug permissions before saving
        print('API permissions: ${responseBody['user']['role']['permissions']}');

        await saveUserDetails(responseBody);

        // Verify permissions after saving
        final savedDetails = await getUserDetails();
        print('Saved permissions: ${savedDetails?['role']?['Permissions']}');

        return {
          responseBody['user']['name']: {
            'FullName': responseBody['user']['name'] ?? 'Not available',
            'Phone': responseBody['user']['phone_number'] ?? 'Not available',
            'Role': responseBody['user']['role']['name'] ?? 'Patient',
            'Token': responseBody['token'] ?? '',
            'Permissions': responseBody['user']['role']['permissions'] ?? [],
          }
        };
      } else {
        throw Exception(responseBody['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return {};
    }
  }
}


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
      // Load the user details first
      _currentUser = json.decode(userJson);

      // Debug the permissions
     // print("Initializing from storage - User data: $_currentUser");
      //print("Permissions: ${_currentUser?['role']?['Permissions']}");

      // Don't automatically set authenticated - validate the token first
      bool isValid = await validateToken(storedToken);

      if (isValid) {
        _token = storedToken;
        _isAuthenticated = true;
        notifyListeners();
      } else {
        // Clear invalid session data
        await logout();
      }
    }
  }

  // Login
  Future<void> login(Map<String, dynamic> userData, String token) async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure we have the complete user data with all necessary fields
    //print("Login permissions: ${userData['role']?['Permissions']}");

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

  // Send a request to validate the token with the backend
  Future<bool> validateToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${IpConfig.baseUrl}/api/auth/authenticate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        // Update user details with the latest from server
        final prefs = await SharedPreferences.getInstance();

        // Ensure we preserve the permission structure
        Map<String, dynamic> updatedUser = responseBody['user'];
        if (updatedUser.containsKey('role') && updatedUser['role'].containsKey('permissions')) {
         // print("Token validation - found permissions: ${updatedUser['role']['permissions']}");
        } else {
          //print("Token validation - permissions not found in response");
        }

        await prefs.setString('userDetails', json.encode(updatedUser));
        _currentUser = updatedUser;
        return true;
      }

      print('Token validation failed: ${responseBody['message']}');
      return false;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  // Check if token exists and is valid
  Future<bool> validateSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('userToken');

    if (storedToken == null) {
      await logout();
      return false;
    }

    // Actually validate the token with the backend
    bool isValid = await validateToken(storedToken);

    if (!isValid) {
      await logout();  // Clear invalid session data
      return false;
    }

    return true;
  }
}