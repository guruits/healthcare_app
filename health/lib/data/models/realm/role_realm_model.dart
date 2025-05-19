import 'package:realm/realm.dart';

part 'role_realm_model.realm.dart';

@RealmModel()
class _RoleRealm {
  @PrimaryKey()
  @MapTo('_id')
  late String id;

  late String? name;
  late String? description;
  late List<String> permissionIds;
}