import 'package:realm/realm.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

part 'faceimage_realm_model.realm.dart';

@RealmModel()
class _ImageRealm {
  @PrimaryKey()
  late ObjectId id;

  late String userId;
  late String base64Image;
  String? contentType;
  late DateTime createdAt;
  bool? isSynced;
  String? mongoId;
}