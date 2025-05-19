import 'package:realm/realm.dart';

@RealmModel()
class _Rlogin {
  @PrimaryKey()

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