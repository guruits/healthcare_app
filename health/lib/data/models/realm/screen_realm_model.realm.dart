// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_realm_model.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class ScreenRealm extends _ScreenRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  ScreenRealm(
    String id, {
    String? name,
    String? description,
    bool? isActive,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'description', description);
    RealmObjectBase.set(this, 'isActive', isActive);
  }

  ScreenRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String? get name => RealmObjectBase.get<String>(this, 'name') as String?;
  @override
  set name(String? value) => RealmObjectBase.set(this, 'name', value);

  @override
  String? get description =>
      RealmObjectBase.get<String>(this, 'description') as String?;
  @override
  set description(String? value) =>
      RealmObjectBase.set(this, 'description', value);

  @override
  bool? get isActive => RealmObjectBase.get<bool>(this, 'isActive') as bool?;
  @override
  set isActive(bool? value) => RealmObjectBase.set(this, 'isActive', value);

  @override
  Stream<RealmObjectChanges<ScreenRealm>> get changes =>
      RealmObjectBase.getChanges<ScreenRealm>(this);

  @override
  Stream<RealmObjectChanges<ScreenRealm>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<ScreenRealm>(this, keyPaths);

  @override
  ScreenRealm freeze() => RealmObjectBase.freezeObject<ScreenRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'description': description.toEJson(),
      'isActive': isActive.toEJson(),
    };
  }

  static EJsonValue _toEJson(ScreenRealm value) => value.toEJson();
  static ScreenRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
      } =>
        ScreenRealm(
          fromEJson(id),
          name: fromEJson(ejson['name']),
          description: fromEJson(ejson['description']),
          isActive: fromEJson(ejson['isActive']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(ScreenRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, ScreenRealm, 'ScreenRealm', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string, optional: true),
      SchemaProperty('description', RealmPropertyType.string, optional: true),
      SchemaProperty('isActive', RealmPropertyType.bool, optional: true),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
