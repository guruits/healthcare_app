import 'package:realm/realm.dart';

part 'user_realm_model.realm.dart';

@RealmModel()
class _UserRealm   {
  @PrimaryKey()
  late String id;

  late String aadhaarNumber;
  late String name;
  late DateTime? dob;
  late String phoneNumber;
  late String address;
  late List<String> roles;
  late bool isActive;

}
