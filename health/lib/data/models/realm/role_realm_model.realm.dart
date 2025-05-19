// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_realm_model.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class RoleRealm extends _RoleRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  RoleRealm(
    String id, {
    String? name,
    String? description,
    Iterable<String> permissionIds = const [],
  }) {
    RealmObjectBase.set(this, '_id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'description', description);
    RealmObjectBase.set<RealmList<String>>(
        this, 'permissionIds', RealmList<String>(permissionIds));
  }

  RoleRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, '_id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, '_id', value);

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
  RealmList<String> get permissionIds =>
      RealmObjectBase.get<String>(this, 'permissionIds') as RealmList<String>;
  @override
  set permissionIds(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<RoleRealm>> get changes =>
      RealmObjectBase.getChanges<RoleRealm>(this);

  @override
  Stream<RealmObjectChanges<RoleRealm>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<RoleRealm>(this, keyPaths);

  @override
  RoleRealm freeze() => RealmObjectBase.freezeObject<RoleRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      '_id': id.toEJson(),
      'name': name.toEJson(),
      'description': description.toEJson(),
      'permissionIds': permissionIds.toEJson(),
    };
  }

  static EJsonValue _toEJson(RoleRealm value) => value.toEJson();
  static RoleRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        '_id': EJsonValue id,
      } =>
        RoleRealm(
          fromEJson(id),
          name: fromEJson(ejson['name']),
          description: fromEJson(ejson['description']),
          permissionIds: fromEJson(ejson['permissionIds']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(RoleRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, RoleRealm, 'RoleRealm', [
      SchemaProperty('id', RealmPropertyType.string,
          mapTo: '_id', primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string, optional: true),
      SchemaProperty('description', RealmPropertyType.string, optional: true),
      SchemaProperty('permissionIds', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
