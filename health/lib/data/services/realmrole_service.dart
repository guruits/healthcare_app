import 'package:realm/realm.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../models/realm/role_realm_model.dart';
import '../models/role.dart';
import '../models/permission.dart';

class MongoRealmRoleService {
  late final Realm _realm;
  late final mongo.Db _mongodb;

  // Initialize Realm and MongoDB connection
  Future<void> initialize() async {
    final config = Configuration.local(
      [RoleRealm.schema],
      schemaVersion: 6,
      migrationCallback: (migration, oldSchemaVersion) {
        // Handle migration if needed
      },
    );

    _realm = await Realm.open(config);

    _mongodb = await mongo.Db.create('mongodb+srv://edwinprakash603:Edwin2001@cluster0.ykeuu.mongodb.net/test');
    print("Connected to MongoDB for roles");
    await _mongodb.open();

    // Initial sync from MongoDB to Realm
    await syncMongoToRealm();
  }

  // Add this method to your MongoRealmRoleService class
  // Add this as a separate method
  Future<Map<String, String>> _getScreenNameToIdMap() async {
    final screenCollection = _mongodb.collection('screens');
    final screens = await screenCollection.find().toList();

    Map<String, String> nameToId = {};
    for (var screen in screens) {
      if (screen['name'] != null && screen['_id'] != null) {
        nameToId[screen['name'].toString()] = screen['_id'] is mongo.ObjectId
            ? screen['_id'].toHexString()
            : screen['_id'].toString();
      }
    }
    return nameToId;
  }

// Keep the original method signature
  Role _convertMongoDocToRole(Map<String, dynamic> doc) {
    // Debug printing to see the raw MongoDB document
    print("Raw MongoDB role document: $doc");

    // Handle permissions safely - work with raw screen values
    List<Permission> permissions = [];
    if (doc['permissions'] != null && doc['permissions'] is List) {
      try {
        permissions = (doc['permissions'] as List).map((perm) {
          // Make sure to include the ID field from the permission document
          return Permission(
            id: perm['_id'] is mongo.ObjectId ? perm['_id'].toHexString() : perm['_id']?.toString(),
            screen: perm['screen']?.toString() ?? '',
            create: perm['create'] ?? false,
            read: perm['read'] ?? false,
            update: perm['update'] ?? false,
            delete: perm['delete'] ?? false,
          );
        }).toList();

        // Debug print to verify permissions were correctly extracted
        print("Extracted ${permissions.length} permissions for role ${doc['name']}");
      } catch (e) {
        print("Error extracting permissions: $e");
      }
    }

    return Role(
      id: doc['_id'] is mongo.ObjectId ? doc['_id'].toHexString() : doc['_id'].toString(),
      name: doc['name']?.toString() ?? '',
      description: doc['description']?.toString() ?? '',
      permissions: permissions,
    );
  }

  // Convert RoleRealm to Role model
  // In the MongoRealmRoleService class
  // Improved _convertRealmToRole method
  Role _convertRealmToRole(RoleRealm realmRole, List<Map<String, dynamic>> permissionDocs) {
    List<Permission> permissions = [];

    for (var permId in realmRole.permissionIds) {
      // Convert both IDs to strings for consistent comparison
      var permDoc = permissionDocs.firstWhere(
            (p) => p['_id'].toString() == permId,
        orElse: () => {},
      );

      if (permDoc.isNotEmpty) {
        permissions.add(Permission(
          id: permId,
          screen: permDoc['screen']?.toString() ?? '',
          create: permDoc['create'] ?? false,
          read: permDoc['read'] ?? false,
          update: permDoc['update'] ?? false,
          delete: permDoc['delete'] ?? false,
        ));
      }
    }

    return Role(
      id: realmRole.id,
      name: realmRole.name ?? '',
      description: realmRole.description ?? '',
      permissions: permissions,
    );
  }

  // Sync all MongoDB data to Realm
  Future<void> syncMongoToRealm() async {
    try {
      final collection = _mongodb.collection('roles');
      final roles = await collection.find().toList();

      _realm.write(() {
        for (var mongoRole in roles) {
          try {
            final role = _convertMongoDocToRole(mongoRole);

            // Extract permission IDs
            List<String>? permissionIds = [];
            if (mongoRole['permissions'] != null && mongoRole['permissions'] is List) {
              permissionIds = (mongoRole['permissions'] as List).map((perm) {
                if (perm['_id'] is mongo.ObjectId) {
                  return perm['_id'].toHexString();
                } else if (perm['_id'] != null) {
                  return perm['_id'].toString();
                }
                return '';
              }).where((id) => id.isNotEmpty).cast<String>().toList();
            }

            // Create a RealmList for permission IDs
            final permIdsList = RealmList<String>(permissionIds);
            permIdsList.addAll(permissionIds);

            // Check if role already exists in Realm
            final existingRole = _realm.find<RoleRealm>(role.id!);

            if (existingRole != null) {
              // Update existing role
              existingRole.name = role.name;
              existingRole.description = role.description;
              existingRole.permissionIds.clear();
              existingRole.permissionIds.addAll(permissionIds);
            } else {
              // Add new role
              _realm.add(
                RoleRealm(
                  role.id!,
                  name: role.name,
                  description: role.description,
                  permissionIds: permIdsList,
                ),
              );
            }
          } catch (e) {
            print("Error syncing role to Realm: $e");
          }
        }
      });
      print("Successfully synced ${roles.length} roles from MongoDB to Realm");
    } catch (e) {
      print("Error during syncMongoToRealm for roles: $e");
      throw Exception('Error syncing roles to Realm: $e');
    }
  }

  // CRUD Operations
  Future<List<Role>> getAllRoles() async {
    try {
      // Try to sync from MongoDB first to ensure up-to-date data
      await syncMongoToRealm();

      // Get all permissions from MongoDB to complete the role data
      final permCollection = _mongodb.collection('permissions');
      final permissionDocs = await permCollection.find().toList();
      print("Fetched ${permissionDocs.length} permission documents from MongoDB");

      // The problem might be here - you're only fetching from 'permissions' collection,
      // but your role documents contain embedded permissions in the 'permissions' array

      // Let's fetch the roles directly from MongoDB to ensure we have complete data
      final rolesCollection = _mongodb.collection('roles');
      final mongoRoles = await rolesCollection.find().toList();
      print("Fetched ${mongoRoles.length} role documents from MongoDB");

      // Convert directly from MongoDB
      final roles = mongoRoles.map((mongoRole) => _convertMongoDocToRole(mongoRole)).toList();

      print("Returning ${roles.length} roles with permissions");
      for (var role in roles) {
        print("Role ${role.name} has ${role.permissions.length} permissions");
      }

      return roles;
    } catch (e) {
      print("Error in getAllRoles: $e");
      throw Exception('Error fetching roles: $e');
    }
  }

  Future<Role> createRole(Role role) async {
    try {
      // Insert into MongoDB
      final collection = _mongodb.collection('roles');
      final permCollection = _mongodb.collection('permissions');

      // First create permissions and collect their IDs
      List<Map<String, dynamic>> permissionDocs = [];
      List<String> permissionIds = [];

      for (var permission in role.permissions) {
        final permResult = await permCollection.insert({
          'screen': permission.screen,
          'create': permission.create,
          'read': permission.read,
          'update': permission.update,
          'delete': permission.delete,
        });

        final permId = permResult['_id'].toHexString();
        permissionIds.add(permId);

        permissionDocs.add({
          '_id': mongo.ObjectId.parse(permId),
          'screen': permission.screen,
          'create': permission.create,
          'read': permission.read,
          'update': permission.update,
          'delete': permission.delete,
        });
      }

      // Insert the role with permission references
      final result = await collection.insert({
        'name': role.name,
        'description': role.description,
        'permissions': permissionDocs,
      });

      // Get the inserted ID
      String id = '';
      if (result.containsKey('_id')) {
        id = result['_id'] is mongo.ObjectId
            ? result['_id'].toHexString()
            : result['_id'].toString();
      }

      role.id = id;

      // Add to Realm
      _realm.write(() {
        final permIdsList = RealmList<String>(permissionIds);
        permIdsList.addAll(permissionIds);

        _realm.add(RoleRealm(
          id,
          name: role.name,
          description: role.description,
          permissionIds: permIdsList,
        ));
      });

      return role;
    } catch (e) {
      print("Error in createRole: $e");
      throw Exception('Error creating role: $e');
    }
  }

  Future<Role> updateRolePermissions(String id, List<Permission> permissions) async {
    try {
      // First get the current role
      final collection = _mongodb.collection('roles');
      final permCollection = _mongodb.collection('permissions');

      final mongoRole = await collection.findOne(mongo.where.id(mongo.ObjectId.parse(id)));
      if (mongoRole == null) {
        throw Exception('Role not found in MongoDB');
      }

      Role role = _convertMongoDocToRole(mongoRole);

      // Delete existing permissions
      if (mongoRole['permissions'] != null && mongoRole['permissions'] is List) {
        for (var perm in mongoRole['permissions']) {
          if (perm['_id'] != null) {
            var permId = perm['_id'];
            await permCollection.remove(mongo.where.id(permId));
          }
        }
      }

      // Create new permissions
      List<Map<String, dynamic>> permissionDocs = [];
      List<String> permissionIds = [];

      // Debug print
      print("Updating role with ${permissions.length} permissions");

      for (var permission in permissions) {
        // Skip permissions with no screen name
        if (permission.screen.isEmpty) {
          continue;
        }

        final permResult = await permCollection.insert({
          'screen': permission.screen,
          'create': permission.create,
          'read': permission.read,
          'update': permission.update,
          'delete': permission.delete,
        });

        final permId = permResult['_id'].toHexString();
        permissionIds.add(permId);

        // Add the permission with its ID for MongoDB update
        permissionDocs.add({
          '_id': mongo.ObjectId.parse(permId),
          'screen': permission.screen,
          'create': permission.create,
          'read': permission.read,
          'update': permission.update,
          'delete': permission.delete,
        });
      }

      // Update MongoDB
      await collection.update(
        mongo.where.id(mongo.ObjectId.parse(id)),
        {'\$set': {'permissions': permissionDocs}},
      );

      // Update the role object with new permissions
      role.permissions = permissions.map((p) => Permission(
        id: p.id,
        screen: p.screen,
        create: p.create,
        read: p.read,
        update: p.update,
        delete: p.delete,
      )).toList();

      // After update, verify the data
      print("Updated role ${role.name} with ${role.permissions.length} permissions");

      // Update Realm
      _realm.write(() {
        final realmRole = _realm.find<RoleRealm>(id);
        if (realmRole != null) {
          realmRole.permissionIds.clear();
          realmRole.permissionIds.addAll(permissionIds);
        } else {
          print("Warning: Role not found in Realm during update. Creating new entry.");
          final permIdsList = RealmList<String>(permissionIds);
          permIdsList.addAll(permissionIds);

          _realm.add(RoleRealm(
            id,
            name: role.name,
            description: role.description,
            permissionIds: permIdsList,
          ));
        }
      });

      return role;
    } catch (e) {
      print("Error in updateRolePermissions: $e");
      throw Exception('Error updating role permissions: $e');
    }
  }

  Future<void> deactivateRole(String id) async {
    try {
      // In this implementation, we'll just delete the role
      // Update MongoDB
      final collection = _mongodb.collection('roles');
      final permCollection = _mongodb.collection('permissions');

      // First get the role to find its permissions
      final mongoRole = await collection.findOne(mongo.where.id(mongo.ObjectId.parse(id)));
      if (mongoRole != null && mongoRole['permissions'] != null && mongoRole['permissions'] is List) {
        // Delete all associated permissions
        for (var perm in mongoRole['permissions']) {
          if (perm['_id'] != null) {
            var permId = perm['_id'];
            await permCollection.remove(mongo.where.id(permId));
          }
        }
      }

      // Delete the role
      await collection.remove(mongo.where.id(mongo.ObjectId.parse(id)));

      // Update Realm
      _realm.write(() {
        final realmRole = _realm.find<RoleRealm>(id);
        if (realmRole != null) {
          _realm.delete(realmRole);
        } else {
          print("Warning: Role not found in Realm during deactivation");
        }
      });
    } catch (e) {
      print("Error in deactivateRole: $e");
      throw Exception('Error deactivating role: $e');
    }
  }

  // Sync an individual role from MongoDB to Realm
  Future<void> syncRoleToRealm(String roleId) async {
    try {
      final collection = _mongodb.collection('roles');
      final mongoRole = await collection.findOne(mongo.where.id(mongo.ObjectId.parse(roleId)));

      if (mongoRole == null) {
        throw Exception('Role not found in MongoDB');
      }

      final role = _convertMongoDocToRole(mongoRole);

      // Extract permission IDs
      List<String>? permissionIds = [];
      if (mongoRole['permissions'] != null && mongoRole['permissions'] is List) {
        permissionIds = (mongoRole['permissions'] as List).map((perm) {
          if (perm['_id'] is mongo.ObjectId) {
            return perm['_id'].toHexString();
          } else if (perm['_id'] != null) {
            return perm['_id'].toString();
          }
          return '';
        }).where((id) => id.isNotEmpty).cast<String>().toList();
      }

      _realm.write(() {
        final permIdsList = RealmList<String>(permissionIds as Iterable<String>);
        permIdsList.addAll(permissionIds as Iterable<String>);

        final existingRole = _realm.find<RoleRealm>(roleId);

        if (existingRole != null) {
          existingRole.name = role.name;
          existingRole.description = role.description;
          existingRole.permissionIds.clear();
          existingRole.permissionIds.addAll(permissionIds as Iterable<String>);
        } else {
          _realm.add(
            RoleRealm(
              role.id!,
              name: role.name,
              description: role.description,
              permissionIds: permIdsList,
            ),
          );
        }
      });
    } catch (e) {
      print("Error syncing individual role to Realm: $e");
      throw Exception('Error syncing role: $e');
    }
  }

  Future<void> dispose() async {
    _realm.close();
    await _mongodb.close();
  }
}