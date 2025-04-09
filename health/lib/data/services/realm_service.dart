import 'dart:convert';

import 'package:realm/realm.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/realm/user_realm_model.dart';
import '../models/user.dart';
import 'dart:async';

class SyncStatus {
  bool isSyncing = false;
  DateTime? lastSyncTime;
  String? lastError;
}

class MongoRealmUserService {
  late final Realm _realm;
  mongo.Db? _mongodb;
  final SyncStatus syncStatus = SyncStatus();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;


  // Initialize Realm independently of MongoDB
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final config = Configuration.local(
        [UserRealm.schema],
        schemaVersion: 6,
        migrationCallback: (migration, oldSchemaVersion) {
          if (oldSchemaVersion < 6) {
            // Perform any necessary data transformations here
          }
        },
      );

      _realm = await Realm.open(config);
      _isInitialized = true;

      // Try to connect to MongoDB in the background
      _connectToMongoDB();
    } catch (e) {
      print("Failed to initialize Realm: $e");
      throw Exception('Error initializing Realm: $e');
    }
  }


  // Separate MongoDB connection method
  Future<void> _connectToMongoDB() async {
    try {
      _mongodb = await mongo.Db.create('mongodb+srv://edwinprakash603:Edwin2001@cluster0.ykeuu.mongodb.net/test');
      await _mongodb!.open();
      print("Connected to MongoDB");

      // Trigger initial sync only after successful connection
      _triggerBackgroundSync();
    } catch (e) {
      print("Failed to connect to MongoDB: $e");
      syncStatus.lastError = "Connection error: $e";
      // We'll continue with local Realm data only
    }
  }
  Realm get realm {
    if (_realm == null) {
      throw Exception('Realm not initialized. Call initialize() first.');
    }
    return _realm!;
  }


  // Convert MongoDB document to User model with improved error handling
  User _convertMongoDocToUser(Map<String, dynamic> doc) {
    // Your existing conversion code...
    DateTime? dobDateTime;
    if (doc['dob'] != null) {
      try {
        if (doc['dob'] is DateTime) {
          dobDateTime = doc['dob'];
        } else if (doc['dob'] is Map && doc['dob'].containsKey('\$date')) {
          var dateString = doc['dob']['\$date'];
          dobDateTime = DateTime.parse(dateString);
        } else if (doc['dob'] is String) {
          dobDateTime = DateTime.parse(doc['dob']);
        }
      } catch (e) {
        print("Error parsing date: $e");
      }
    }

    List<String> roles = [];
    if (doc['roles'] != null) {
      try {
        roles = (doc['roles'] as List).map((role) {
          if (role is mongo.ObjectId) {
            return role.toHexString();
          } else if (role is Map && role['\$oid'] != null) {
            return role['\$oid'].toString();
          } else {
            return role.toString();
          }
        }).toList();
      } catch (e) {
        print("Error extracting roles: $e");
      }
    }

    return User(
      id: doc['_id'] is mongo.ObjectId ? doc['_id'].toHexString() : doc['_id'].toString(),
      aadhaarNumber: doc['aadhaarNumber']?.toString() ?? '',
      name: doc['name']?.toString() ?? '',
      dob: dobDateTime,
      phoneNumber: doc['phone_number']?.toString() ?? '',
      address: doc['address']?.toString() ?? '',
      password: doc['password']?.toString() ?? '',
      roles: roles,
      isActive: doc['isActive'] ?? true,
    );
  }

  // Convert UserRealm to User model
  User _convertRealmToUser(UserRealm realmUser) {
    return User(
      id: realmUser.id,
      aadhaarNumber: realmUser.aadhaarNumber,
      name: realmUser.name,
      dob: realmUser.dob,
      phoneNumber: realmUser.phoneNumber,
      address: realmUser.address,
      password: realmUser.password,
      roles: realmUser.roles.toList(),
      isActive: realmUser.isActive,
    );
  }

  // Background sync method
  Future<void> _triggerBackgroundSync() async {
    // Only sync if we're not already syncing and MongoDB is connected
    if (syncStatus.isSyncing || _mongodb == null) return;

    syncStatus.isSyncing = true;

    try {
      await syncMongoToRealm();
      syncStatus.lastSyncTime = DateTime.now();
      syncStatus.lastError = null;
      print("Background sync completed successfully");
    } catch (e) {
      print("Background sync error: $e");
      syncStatus.lastError = "Sync error: $e";
    } finally {
      syncStatus.isSyncing = false;
    }
  }

  // Sync all MongoDB data to Realm
  Future<void> syncMongoToRealm() async {
    if (_mongodb == null) {
      throw Exception('Cannot sync: MongoDB is not connected');
    }

    try {
      final collection = _mongodb!.collection('users');
      final users = await collection.find().toList();

      _realm.write(() {
        for (var mongoUser in users) {
          try {
            final user = _convertMongoDocToUser(mongoUser);
            final rolesList = RealmList<String>(user.roles);

            // Check if user already exists in Realm
            final existingUser = _realm.find<UserRealm>(user.id);

            if (existingUser != null) {
              // Update existing user
              existingUser.aadhaarNumber = user.aadhaarNumber;
              existingUser.name = user.name;
              existingUser.dob = user.dob;
              existingUser.phoneNumber = user.phoneNumber;
              existingUser.address = user.address;
              existingUser.password = user.password;
              existingUser.isActive = user.isActive;
              existingUser.roles.clear();
              existingUser.roles.addAll(user.roles);
            } else {
              // Add new user
              _realm.add(
                UserRealm(
                  user.id,
                  user.aadhaarNumber,
                  user.name,
                  dob: user.dob,
                  user.phoneNumber,
                  user.address,
                  user.password,
                  user.isActive,
                  roles: rolesList,
                ),
              );
            }
          } catch (e) {
            print("Error syncing user to Realm: $e");
          }
        }
      });
      print("Successfully synced ${users.length} users from MongoDB to Realm");
    } catch (e) {
      print("Error during syncMongoToRealm: $e");
      throw Exception('Error syncing users to Realm: $e');
    }
  }



  // Get all users - always from Realm first
  Future<List<User>> getAllUsers() async {
    try {
      // Always get from Realm first
      final realmUsers = _realm.all<UserRealm>();

      // Try to trigger background sync if we have MongoDB connection
      if (_mongodb != null) {
        _triggerBackgroundSync();
      } else {
        // Try to reconnect if we don't have a connection
        _connectToMongoDB();
      }

      // Return Realm data immediately
      return realmUsers.map(_convertRealmToUser).toList();
    } catch (e) {
      print("Error in getAllUsers: $e");
      throw Exception('Error fetching users: $e');
    }
  }

  // Get user by ID - first check Realm, then MongoDB if necessary
  Future<User?> getUserById(String? userId) async {
    if (!_isInitialized) await initialize();

    if (userId == null) {
      throw Exception('User ID cannot be null');
    }

    try {
      // First check Realm for the user
      final realmUser = realm.find<UserRealm>(userId);

      if (realmUser != null) {
        return _convertRealmToUser(realmUser);
      }

      // If not found in Realm and MongoDB is connected, try to fetch from MongoDB
      if (_mongodb != null) {
        try {
          final collection = _mongodb!.collection('users');
          final mongoUser = await collection.findOne(mongo.where.id(mongo.ObjectId.parse(userId)));

          if (mongoUser != null) {
            // Convert MongoDB user to User model
            final user = _convertMongoDocToUser(mongoUser);

            // Also save to Realm for future offline access
            realm.write(() {
              final rolesList = RealmList<String>(user.roles);

              realm.add(UserRealm(
                user.id,
                user.aadhaarNumber,
                user.name,
                dob: user.dob,
                user.phoneNumber,
                user.address,
                user.password,
                user.isActive,
                roles: rolesList,
              ));
            });

            return user;
          }
        } catch (e) {
          print("Error fetching user from MongoDB: $e");
          // Continue to return null if not found
        }
      }

      // User not found in either database
      return null;
    } catch (e) {
      print("Error in getUserById: $e");
      throw Exception('Error fetching user: $e');
    }
  }

  Future<User?> getCurrentUserDetails() async {
    if (!_isInitialized) await initialize();

    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User ID not found in SharedPreferences');
      }

      return await getUserById(userId);
    } catch (e) {
      print("Error in getCurrentUserDetails: $e");
      throw Exception('Error fetching current user details: $e');
    }
  }


// Helper method to get userId from SharedPreferences
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetails = prefs.getString('userDetails');

    if (userDetails == null) {
      print('No user details stored in SharedPreferences');
      throw Exception('No user details found');
    }

    try {
      // Decode the user details JSON string into a Map
      final userJson = json.decode(userDetails) as Map<String, dynamic>;
      final userId = userJson['id'];  // Extract the 'id' from the decoded Map

      if (userId == null) {
        print('User ID not found in stored user details');
        throw Exception('No user ID found in the stored data');
      }

      return userId;
    } catch (e) {
      print('Error decoding user details: $e');
      throw Exception('Error decoding user details: $e');
    }
  }

  // Create a user - try MongoDB first, fallback to local-only
  Future<User> createUser(User user) async {
    try {
      String id = '';

      // Try to create in MongoDB first if connected
      if (_mongodb != null) {
        try {
          final collection = _mongodb!.collection('users');

          final roleObjectIds = user.roles.map((role) {
            try {
              return mongo.ObjectId.parse(role);
            } catch (e) {
              return role;
            }
          }).toList();

          final result = await collection.insert({
            'aadhaarNumber': user.aadhaarNumber,
            'name': user.name,
            'dob': user.dob?.toIso8601String(),
            'phone_number': user.phoneNumber,
            'address': user.address,
            'password': user.password,
            'roles': roleObjectIds,
            'isActive': true,
          });

          // Get the inserted ID
          if (result.containsKey('_id')) {
            id = result['_id'] is mongo.ObjectId
                ? result['_id'].toHexString()
                : result['_id'].toString();
          }
        } catch (e) {
          print("Error creating user in MongoDB: $e");
          // Generate a local ID
          id = mongo.ObjectId().toHexString();
        }
      } else {
        // Generate a local ID if MongoDB is not available
        id = mongo.ObjectId().toHexString();
      }

      user.id = id;

      // Add to Realm
      _realm.write(() {
        final rolesList = RealmList<String>(user.roles);

        _realm.add(UserRealm(
          id,
          user.aadhaarNumber,
          user.name,
          dob: user.dob,
          user.phoneNumber,
          user.address,
          user.password,
          true,
          roles: rolesList,
        ));
      });

      return user;
    } catch (e) {
      print("Error in createUser: $e");
      throw Exception('Error creating user: $e');
    }
  }

  // Update user - in Realm and try MongoDB
  Future<User> updateUser(String id, User user) async {
    try {
      // Always update Realm first
      _realm.write(() {
        final realmUser = _realm.find<UserRealm>(id);
        if (realmUser != null) {
          realmUser.aadhaarNumber = user.aadhaarNumber;
          realmUser.name = user.name;
          realmUser.dob = user.dob;
          realmUser.phoneNumber = user.phoneNumber;
          realmUser.address = user.address;
          realmUser.roles.clear();
          realmUser.roles.addAll(user.roles);
        } else {
          final rolesList = RealmList<String>(user.roles);

          _realm.add(UserRealm(
            id,
            user.aadhaarNumber,
            user.name,
            dob: user.dob,
            user.phoneNumber,
            user.address,
            user.password,
            true,
            roles: rolesList,
          ));
        }
      });

      // Try to update MongoDB if connected
      if (_mongodb != null) {
        try {
          final collection = _mongodb!.collection('users');

          final roleObjectIds = user.roles.map((role) {
            try {
              return mongo.ObjectId.parse(role);
            } catch (e) {
              return role;
            }
          }).toList();

          await collection.update(
            mongo.where.id(mongo.ObjectId.parse(id)),
            {
              '\$set': {
                'aadhaarNumber': user.aadhaarNumber,
                'name': user.name,
                'dob': user.dob?.toIso8601String(),
                'phone_number': user.phoneNumber,
                'address': user.address,
                'roles': roleObjectIds,
              }
            },
          );
        } catch (e) {
          print("Error updating user in MongoDB: $e");
          // Continue with local update only
        }
      }

      return user;
    } catch (e) {
      print("Error in updateUser: $e");
      throw Exception('Error updating user: $e');
    }
  }

  // Deactivate/Activate user
  Future<void> deactivateUser(String id) async {
    try {
      // Get current status from Realm
      final realmUser = _realm.find<UserRealm>(id);
      if (realmUser == null) {
        throw Exception('User not found in local database');
      }

      // Toggle status
      bool newStatus = !realmUser.isActive;

      // Update Realm first
      _realm.write(() {
        realmUser.isActive = newStatus;
      });

      // Try to update MongoDB if connected
      if (_mongodb != null) {
        try {
          final collection = _mongodb!.collection('users');
          await collection.update(
            mongo.where.id(mongo.ObjectId.parse(id)),
            {'\$set': {'isActive': newStatus}},
          );
        } catch (e) {
          print("Error toggling user status in MongoDB: $e");
          // Continue with local update only
        }
      }
    } catch (e) {
      print("Error in deactivateUser: $e");
      throw Exception('Error toggling user status: $e');
    }
  }

  // Force a sync now - can be called from UI
  Future<bool> syncNow() async {
    if (_mongodb == null) {
      // Try to connect first
      try {
        await _connectToMongoDB();
      } catch (e) {
        return false;
      }
    }

    if (_mongodb != null && !syncStatus.isSyncing) {
      await _triggerBackgroundSync();
      return true;
    }
    return false;
  }

  // Check connection status
  bool isConnected() {
    return _mongodb != null;
  }

  // Get sync status
  SyncStatus getSyncStatus() {
    return syncStatus;
  }

  // Clean up resources
  Future<void> dispose() async {
    _realm.close();
    if (_mongodb != null) {
      await _mongodb!.close();
    }
  }
}