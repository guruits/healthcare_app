import 'package:realm/realm.dart';

@RealmModel()
class _User {
  @PrimaryKey()
  late ObjectId id;

  late String aadhaarNumber;
  late String name;
  late DateTime dob;
  late String phoneNumber;
  String? address;
  late String password;

  @MapTo('face_features')
  RealmList<String>? faceFeatures;

  @MapTo('face_image')
  Map<String, dynamic>? faceImage;

  @MapTo('created_at')
  late DateTime createdAt;

  @MapTo('updated_at')
  DateTime? updatedAt;

  @MapTo('deleted_at')
  DateTime? deletedAt;
}