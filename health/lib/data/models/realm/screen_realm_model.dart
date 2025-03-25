import 'package:realm/realm.dart';

part 'screen_realm_model.realm.dart';

@RealmModel()
class _ScreenRealm {
  @PrimaryKey()
  late String id;
  late String? name;
  late String? description;
  late bool? isActive;

}