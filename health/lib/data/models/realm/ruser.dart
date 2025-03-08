import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../datasources/api_service.dart';

part 'ruser.realm.dart';

// Constants for sync settings
const String LAST_SYNC_KEY = 'last_sync_time';
const Duration SYNC_INTERVAL = Duration(hours: 1);

@RealmModel()
class _RUser {
  @PrimaryKey()
  late String aadhaarNumber;

  late String name;
  late String phoneNumber;
  late String dob;
  late String address;
  late String password;
  late String profilePicturePath;
  late bool isSynced;
  late DateTime createdAt;
  late DateTime? lastSyncAttempt;
}

// Separate sync manager class to handle sync scheduling
class UserSyncManager {
  static final UserSyncManager _instance = UserSyncManager._internal();
  Timer? _syncTimer;
  final UserService _userService = UserService();

  factory UserSyncManager() {
    return _instance;
  }

  UserSyncManager._internal();

  void initialize() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      checkAndSyncData();
    });
  }

  /*void dispose() {
    _syncTimer?.cancel();
  }*/
  @override
  void dispose() {
    _syncTimer?.cancel();
    UserSyncManager().dispose();
   // super.dispose();
  }

  Future<void> checkAndSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(LAST_SYNC_KEY) ?? 0
    );

    if (DateTime.now().difference(lastSync) >= SYNC_INTERVAL) {
      await UserServiceLocal.syncPendingRecords(_userService);
      await prefs.setInt(LAST_SYNC_KEY, DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> forceSyncNow() async {
    await UserServiceLocal.syncPendingRecords(_userService);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LAST_SYNC_KEY, DateTime.now().millisecondsSinceEpoch);
  }
}

// UserService extension for local storage operations
extension UserServiceLocal on UserService {
  static Future<Map<String, dynamic>> addUserLocal({
    required File imageFile,
    required String phoneNumber,
    required String aadhaarNumber,
    required String name,
    required String dob,
    required String address,
    required String password,
  }) async {
    try {
      // Save image to local storage
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_$aadhaarNumber.${imageFile.path.split('.').last}';
      await imageFile.copy(imagePath);

      // Initialize Realm
      final config = Configuration.local(
        [RUser.schema],
        schemaVersion: 2, // Increment this value whenever you update the schema
        migrationCallback: (migration, oldVersion) {
          if (oldVersion < 2) {
            // Handle the migration if needed
          }
        },
      );
      final realm = Realm(config);


      // Create user object
      final user = RUser(
        aadhaarNumber,
        name,
        phoneNumber,
        dob,
        address,
        password,
        imagePath,
        false, // isSynced
        DateTime.now(), // createdAt
        //null, // lastSyncAttempt
      );

      // Save to Realm
      realm.write(() {
        realm.add(user);
      });

      // Ensure sync manager is running
      UserSyncManager().initialize();

      return {
        'status': 'success',
        'statusCode': 201,
        'message': 'Registration saved locally. Will sync automatically.',
        'data': {'localOnly': true}
      };

    } catch (e) {
      return {
        'status': 'error',
        'message': 'Local registration failed: ${e.toString()}'
      };
    }
  }

  // Static method to sync pending records
  static Future<void> syncPendingRecords(UserService service) async {
    final config = Configuration.local([RUser.schema]);
    final realm = Realm(config);

    final unsyncedUsers = realm.all<RUser>().query("isSynced == false");

    for (final user in unsyncedUsers) {
      try {
        // Update last sync attempt time
        realm.write(() {
          user.lastSyncAttempt = DateTime.now();
        });

        final imageFile = File(user.profilePicturePath);

        // Check if file exists before attempting sync
        if (!await imageFile.exists()) {
          print('Profile image not found for user ${user.aadhaarNumber}');
          continue;
        }

        final response = await service.addUser(
          imageFile: imageFile,
          phoneNumber: user.phoneNumber,
          aadhaarNumber: user.aadhaarNumber,
          name: user.name,
          dob: user.dob,
          address: user.address,
          newPassword: user.password,
          confirmPassword: user.password,
        );

        if (response['status'] == 'success') {
          realm.write(() {
            user.isSynced = true;
          });
          print('Successfully synced user ${user.aadhaarNumber}');
        }
      } catch (e) {
        print('Failed to sync user ${user.aadhaarNumber}: $e');
      }
    }
  }
}