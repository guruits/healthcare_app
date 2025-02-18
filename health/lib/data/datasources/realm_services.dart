import 'package:realm/realm.dart';

import '../models/user.dart';
import '../realmmodels/user.realm.dart';

class RealmService {
  static final RealmService _instance = RealmService._internal();
  late Realm _realm;
  App? _app;
  User? _currentUser;

  factory RealmService() {
    return _instance;
  }

  RealmService._internal();

  Future<void> initialize() async {
    final appConfig = AppConfiguration('your-realm-app-id');
    _app = App(appConfig);

    final config = Configuration.flexibleSync(_currentUser!, [User.schema]);
    _realm = Realm(config);

    // Set up initial subscriptions
    await _realm.subscriptions.update((mutableSubscriptions) {
      mutableSubscriptions.add(_realm.all<User>());
    });
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      final credentials = Credentials.emailPassword(email, password);
      _currentUser = await _app?.logIn(credentials);
      return _currentUser;
    } catch (e) {
      print('Realm login error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _currentUser?.logOut();
    _currentUser = null;
  }

  // CRUD Operations
  Future<User?> createUser(Map<String, dynamic> userData) async {
    try {
      final user = User(
        ObjectId(),
        aadhaarNumber: userData['aadhaarNumber'],
        name: userData['name'],
        dob: userData['dob'],
        phoneNumber: userData['phone_number'],
        address: userData['address'],
        password: userData['password'],
        createdAt: DateTime.now(),
      );

      await _realm.writeAsync(() {
        _realm.add(user);
      });

      return user;
    } catch (e) {
      print('Error creating user in Realm: $e');
      return null;
    }
  }

  User? getUserByPhone(String phoneNumber) {
    return _realm.all<User>()
        .query("phoneNumber == '$phoneNumber'")
        .firstOrNull;
  }

  Future<void> updateUser(User user, Map<String, dynamic> updates) async {
    await _realm.writeAsync(() {
      user.name = updates['name'] ?? user.name;
      user.address = updates['address'] ?? user.address;
      user.updatedAt = DateTime.now();
    });
  }

  Future<void> deleteUser(User user) async {
    await _realm.writeAsync(() {
      _realm.delete(user);
    });
  }
}
