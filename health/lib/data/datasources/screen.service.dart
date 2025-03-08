import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/screen.dart';
import '../services/realmscreen_service.dart';

class ScreenService {
  late String baseUrl;
  bool useLocalMongo = true;

  ScreenService() {
    baseUrl = _getBaseUrl();
  }

  String _getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://192.168.1.21:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Screen>> getAllScreens() async {
    if (useLocalMongo) {
      try {
        // Use the MongoRealmScreenService
        final mongoRealmService = MongoRealmScreenService();
        await mongoRealmService.initialize();
        final screens = await mongoRealmService.getAllScreens();
        await mongoRealmService.dispose();
        return screens;
      } catch (e) {
        throw Exception('Failed to load screens from local MongoDB: $e');
      }
    } else {
      try {
        // Use the API
        final response = await http.get(
          Uri.parse('$baseUrl/screens'),
          headers: await _getHeaders(),
        );

        if (response.statusCode == 200) {
          final List<dynamic> screensJson = json.decode(response.body);
          return screensJson.map((json) => Screen.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load screens: ${response.body}');
        }
      } catch (e) {
        throw Exception('Error fetching screens: $e');
      }
    }
  }

  Future<Screen> createScreen(Screen screen) async {
    if (useLocalMongo) {
      try {
        final mongoRealmService = MongoRealmScreenService();
        await mongoRealmService.initialize();
        final createdScreen = await mongoRealmService.createScreen(screen);
        await mongoRealmService.dispose();
        return createdScreen;
      } catch (e) {
        throw Exception('Failed to create screen in MongoDB: $e');
      }
    } else {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/screens/create'),
          headers: await _getHeaders(),
          body: json.encode({
            'name': screen.name,
            'description': screen.description,
            'isActive': screen.isActive,
          }),
        );

        if (response.statusCode == 201) {
          return Screen.fromJson(
              json.decode(response.body)['screen']);
        } else {
          throw Exception('Failed to create screen: ${response.body}');
        }
      } catch (e) {
        throw Exception('Error creating screen: $e');
      }
    }
  }

  Future<Screen> updateScreen(String id, Screen screen) async {
    if (useLocalMongo) {
      try {
        final mongoRealmService = MongoRealmScreenService();
        await mongoRealmService.initialize();
        final updatedScreen = await mongoRealmService.updateScreen(id, screen);
        await mongoRealmService.dispose();
        return updatedScreen;
      } catch (e) {
        throw Exception('Failed to update screen in MongoDB: $e');
      }
    } else {
      try {
        final response = await http.put(
          Uri.parse('$baseUrl/screens/$id'),
          headers: await _getHeaders(),
          body: json.encode({
            'name': screen.name,
            'description': screen.description,
            'isActive': screen.isActive,
          }),
        );

        if (response.statusCode == 200) {
          return Screen.fromJson(
              json.decode(response.body)['screen']);
        } else {
          throw Exception('Failed to update screen: ${response.body}');
        }
      } catch (e) {
        throw Exception('Error updating screen: $e');
      }
    }
  }

  Future<void> deactivateScreen(String screenName) async {
    if (useLocalMongo) {
      try {
        final mongoRealmService = MongoRealmScreenService();
        await mongoRealmService.initialize();
        await mongoRealmService.deactivateScreen(screenName);
        await mongoRealmService.dispose();
      } catch (e) {
        throw Exception('Failed to deactivate screen in MongoDB: $e');
      }
    } else {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl/screens/$screenName'),
          headers: await _getHeaders(),
        );

        print("Response Code: ${response.statusCode}");
        print("Response Body: ${response.body}");

        if (response.statusCode != 200) {
          throw Exception('Failed to deactivate screen: ${response.body}');
        }
      } catch (e) {
        print("Error in API call: $e");
        throw Exception('Error deactivating screen: $e');
      }
    }
  }
}