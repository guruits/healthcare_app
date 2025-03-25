import 'package:realm/realm.dart';

part 'permission_realm_model.realm.dart';

@RealmModel()
class _PermissionRealm {
  @PrimaryKey()
  @MapTo('_id')
  late String id;

  late String screen;
  late bool create;
  late bool read;
  late bool update;
  late bool delete;
}