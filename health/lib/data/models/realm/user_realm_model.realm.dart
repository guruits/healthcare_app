// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_realm_model.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class UserRealm extends _UserRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  UserRealm(
    String id,
    String aadhaarNumber,
    String name,
    String phoneNumber,
    String address,
    String password,
    bool isActive, {
    DateTime? dob,
    Iterable<String> roles = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'aadhaarNumber', aadhaarNumber);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'dob', dob);
    RealmObjectBase.set(this, 'phoneNumber', phoneNumber);
    RealmObjectBase.set(this, 'address', address);
    RealmObjectBase.set(this, 'password', password);
    RealmObjectBase.set<RealmList<String>>(
        this, 'roles', RealmList<String>(roles));
    RealmObjectBase.set(this, 'isActive', isActive);
  }

  UserRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

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
  DateTime? get dob => RealmObjectBase.get<DateTime>(this, 'dob') as DateTime?;
  @override
  set dob(DateTime? value) => RealmObjectBase.set(this, 'dob', value);

  @override
  String get phoneNumber =>
      RealmObjectBase.get<String>(this, 'phoneNumber') as String;
  @override
  set phoneNumber(String value) =>
      RealmObjectBase.set(this, 'phoneNumber', value);

  @override
  String get address => RealmObjectBase.get<String>(this, 'address') as String;
  @override
  set address(String value) => RealmObjectBase.set(this, 'address', value);

  @override
  String get password =>
      RealmObjectBase.get<String>(this, 'password') as String;
  @override
  set password(String value) => RealmObjectBase.set(this, 'password', value);

  @override
  RealmList<String> get roles =>
      RealmObjectBase.get<String>(this, 'roles') as RealmList<String>;
  @override
  set roles(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  bool get isActive => RealmObjectBase.get<bool>(this, 'isActive') as bool;
  @override
  set isActive(bool value) => RealmObjectBase.set(this, 'isActive', value);

  @override
  Stream<RealmObjectChanges<UserRealm>> get changes =>
      RealmObjectBase.getChanges<UserRealm>(this);

  @override
  Stream<RealmObjectChanges<UserRealm>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<UserRealm>(this, keyPaths);

  @override
  UserRealm freeze() => RealmObjectBase.freezeObject<UserRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'aadhaarNumber': aadhaarNumber.toEJson(),
      'name': name.toEJson(),
      'dob': dob.toEJson(),
      'phoneNumber': phoneNumber.toEJson(),
      'address': address.toEJson(),
      'password': password.toEJson(),
      'roles': roles.toEJson(),
      'isActive': isActive.toEJson(),
    };
  }

  static EJsonValue _toEJson(UserRealm value) => value.toEJson();
  static UserRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'aadhaarNumber': EJsonValue aadhaarNumber,
        'name': EJsonValue name,
        'phoneNumber': EJsonValue phoneNumber,
        'address': EJsonValue address,
        'password': EJsonValue password,
        'isActive': EJsonValue isActive,
      } =>
        UserRealm(
          fromEJson(id),
          fromEJson(aadhaarNumber),
          fromEJson(name),
          fromEJson(phoneNumber),
          fromEJson(address),
          fromEJson(password),
          fromEJson(isActive),
          dob: fromEJson(ejson['dob']),
          roles: fromEJson(ejson['roles']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(UserRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, UserRealm, 'UserRealm', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('aadhaarNumber', RealmPropertyType.string),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('dob', RealmPropertyType.timestamp, optional: true),
      SchemaProperty('phoneNumber', RealmPropertyType.string),
      SchemaProperty('address', RealmPropertyType.string),
      SchemaProperty('password', RealmPropertyType.string),
      SchemaProperty('roles', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
      SchemaProperty('isActive', RealmPropertyType.bool),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
