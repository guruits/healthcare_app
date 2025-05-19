import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/role.dart';
import '../models/permission.dart';
import '../models/screen.dart';
import '../services/realmrole_service.dart';

class RoleService {
  //final String apiUrl = 'your_api_url_here';

  Future<List<Role>> getAllRoles() async {
    try {
      // For now, we'll directly use the MongoRealmRoleService
      final mongoRealmService = MongoRealmRoleService();
      await mongoRealmService.initialize();
      final roles = await mongoRealmService.getAllRoles();
      await mongoRealmService.dispose();
      return roles;
    } catch (e) {
      throw Exception('Failed to load roles: $e');
    }
  }

  Future<Role> createRole(Role role) async {
    try {
      final mongoRealmService = MongoRealmRoleService();
      await mongoRealmService.initialize();
      final createdRole = await mongoRealmService.createRole(role);
      await mongoRealmService.dispose();
      return createdRole;
    } catch (e) {
      throw Exception('Failed to create role: $e');
    }
  }

  Future<Role> updateRolePermissions(String id, List<Permission> permissions) async {
    try {
      final mongoRealmService = MongoRealmRoleService();
      await mongoRealmService.initialize();
      final updatedRole = await mongoRealmService.updateRolePermissions(id, permissions);
      await mongoRealmService.dispose();
      return updatedRole;
    } catch (e) {
      throw Exception('Failed to update role permissions: $e');
    }
  }

  Future<void> deactivateRole(String id) async {
    try {
      final mongoRealmService = MongoRealmRoleService();
      await mongoRealmService.initialize();
      await mongoRealmService.deactivateRole(id);
      await mongoRealmService.dispose();
    } catch (e) {
      throw Exception('Failed to deactivate role: $e');
    }
  }
}
