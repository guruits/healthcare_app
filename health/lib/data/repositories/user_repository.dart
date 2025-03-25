/*
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realm/realm.dart';

import '../datasources/user.service.dart';
import '../models/realm/user_realm_model.dart';
import '../models/user.dart';

class RealmRepository {
  late Realm _realm;
  final _config = Configuration.local([UserRealm.schema]);

  RealmRepository() {
    _initRealm();
  }

  void _initRealm() {
    _realm = Realm(_config);
  }

  // Convert API User to RealmUser
  UserRealm _convertToRealmUser( user) {
    final realmUser = UserRealm(
      id: user.id,
      aadhaarNumber: user.aadhaarNumber,
      name: user.name,
      dob: user.dob,
      phoneNumber: user.phoneNumber,
      address: user.address,
      roles: user.roles,
      isActive: user.isActive
    );
    return realmUser;
  }

  // Convert RealmUser to API User
  User _convertToApiUser(UserRealm realmUser) {
    return User(
      id: realmUser.id,
      aadhaarNumber: realmUser.aadhaarNumber,
      name: realmUser.name,
      dob: realmUser.dob,
      phoneNumber: realmUser.phoneNumber,
      address: realmUser.address,
      roles: realmUser.roles.toList(),
      isActive: realmUser.isActive,
    );
  }

  // Sync data from API to Realm
  Future<void> syncFromApi() async {
    try {
      final userService = UserManageService();
      final users = await userService.getAllUsers();

      _realm.write(() {
        // Clear existing data
        _realm.deleteAll<UserRealm>();

        // Add new data
        for (var user in users) {
          _realm.add(_convertToRealmUser(user));
        }
      });
    } catch (e) {
      throw Exception('Error syncing data to Realm: $e');
    }
  }

  // Get all users from Realm
  List<User> getAllUsers() {
    final realmUsers = _realm.all<UserRealm>();
    return realmUsers.map((realmUser) => _convertToApiUser(realmUser)).toList();
  }

  // Clear all data from Realm
  Future<void> clearAllData() async {
    _realm.write(() {
      _realm.deleteAll<UserRealm>();
    });
  }

  // Close Realm instance
  void dispose() {
    _realm.close();
  }
}

// Create SyncScreen widget
class SyncScreen extends StatefulWidget {
  const SyncScreen({Key? key}) : super(key: key);

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final RealmRepository _realmRepository = RealmRepository();
  bool _isSyncing = false;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    setState(() {
      _users = _realmRepository.getAllUsers();
    });
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      await _realmRepository.syncFromApi();
      await _loadLocalData();
      _showSnackBar('Data synced successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error syncing data: $e', Colors.red);
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _clearData() async {
    try {
      await _realmRepository.clearAllData();
      await _loadLocalData();
      _showSnackBar('Data cleared successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error clearing data: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sync'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSyncing ? null : _syncData,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearData,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSyncing)
            const LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          Expanded(
            child: _users.isEmpty
                ? const Center(
                    child: Text('No local data available'),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text('Aadhaar: ${user.aadhaarNumber}'),
                        trailing: Text(user.roles.join(', ')),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _isSyncing ? null : _syncData,
            backgroundColor: Colors.black,
            heroTag: 'sync',
            child: const Icon(Icons.sync),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _clearData,
            backgroundColor: Colors.red,
            heroTag: 'clear',
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _realmRepository.dispose();
    super.dispose();
  }
}*/
