// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../services/ruser.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class RUser extends _RUser with RealmEntity, RealmObjectBase, RealmObject {
  RUser(
    String aadhaarNumber,
    String name,
    String phoneNumber,
    String dob,
    String address,
    String profilePicturePath,
    bool isSynced,
    DateTime createdAt, {
    DateTime? lastSyncAttempt,
  }) {
    RealmObjectBase.set(this, 'aadhaarNumber', aadhaarNumber);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'phoneNumber', phoneNumber);
    RealmObjectBase.set(this, 'dob', dob);
    RealmObjectBase.set(this, 'address', address);
    RealmObjectBase.set(this, 'profilePicturePath', profilePicturePath);
    RealmObjectBase.set(this, 'isSynced', isSynced);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'lastSyncAttempt', lastSyncAttempt);
  }

  RUser._();

  @override
  String get aadhaarNumber =>
      RealmObjectBase.get<String>(this, 'aadhaarNumber') as String;
  @override
  set aadhaarNumber(String value) =>
      RealmObjectBase.set(this, 'aadhaarNumber', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get phoneNumber =>
      RealmObjectBase.get<String>(this, 'phoneNumber') as String;
  @override
  set phoneNumber(String value) =>
      RealmObjectBase.set(this, 'phoneNumber', value);

  @override
  String get dob => RealmObjectBase.get<String>(this, 'dob') as String;
  @override
  set dob(String value) => RealmObjectBase.set(this, 'dob', value);

  @override
  String get address => RealmObjectBase.get<String>(this, 'address') as String;
  @override
  set address(String value) => RealmObjectBase.set(this, 'address', value);

  @override
  String get profilePicturePath =>
      RealmObjectBase.get<String>(this, 'profilePicturePath') as String;
  @override
  set profilePicturePath(String value) =>
      RealmObjectBase.set(this, 'profilePicturePath', value);

  @override
  bool get isSynced => RealmObjectBase.get<bool>(this, 'isSynced') as bool;
  @override
  set isSynced(bool value) => RealmObjectBase.set(this, 'isSynced', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  DateTime? get lastSyncAttempt =>
      RealmObjectBase.get<DateTime>(this, 'lastSyncAttempt') as DateTime?;
  @override
  set lastSyncAttempt(DateTime? value) =>
      RealmObjectBase.set(this, 'lastSyncAttempt', value);

  @override
  Stream<RealmObjectChanges<RUser>> get changes =>
      RealmObjectBase.getChanges<RUser>(this);

  @override
  Stream<RealmObjectChanges<RUser>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<RUser>(this, keyPaths);

  @override
  RUser freeze() => RealmObjectBase.freezeObject<RUser>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'aadhaarNumber': aadhaarNumber.toEJson(),
      'name': name.toEJson(),
      'phoneNumber': phoneNumber.toEJson(),
      'dob': dob.toEJson(),
      'address': address.toEJson(),
      'profilePicturePath': profilePicturePath.toEJson(),
      'isSynced': isSynced.toEJson(),
      'createdAt': createdAt.toEJson(),
      'lastSyncAttempt': lastSyncAttempt.toEJson(),
    };
  }

  static EJsonValue _toEJson(RUser value) => value.toEJson();
  static RUser _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'aadhaarNumber': EJsonValue aadhaarNumber,
        'name': EJsonValue name,
        'phoneNumber': EJsonValue phoneNumber,
        'dob': EJsonValue dob,
        'address': EJsonValue address,
        'profilePicturePath': EJsonValue profilePicturePath,
        'isSynced': EJsonValue isSynced,
        'createdAt': EJsonValue createdAt,
      } =>
        RUser(
          fromEJson(aadhaarNumber),
          fromEJson(name),
          fromEJson(phoneNumber),
          fromEJson(dob),
          fromEJson(address),
          fromEJson(profilePicturePath),
          fromEJson(isSynced),
          fromEJson(createdAt),
          lastSyncAttempt: fromEJson(ejson['lastSyncAttempt']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(RUser._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, RUser, 'RUser', [
      SchemaProperty('aadhaarNumber', RealmPropertyType.string,
          primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('phoneNumber', RealmPropertyType.string),
      SchemaProperty('dob', RealmPropertyType.string),
      SchemaProperty('address', RealmPropertyType.string),
      SchemaProperty('profilePicturePath', RealmPropertyType.string),
      SchemaProperty('isSynced', RealmPropertyType.bool),
      SchemaProperty('createdAt', RealmPropertyType.timestamp),
      SchemaProperty('lastSyncAttempt', RealmPropertyType.timestamp,
          optional: true),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
