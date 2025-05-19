// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_realm_model.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class PermissionRealm extends _PermissionRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  PermissionRealm(
    String id,
    String screen,
    bool create,
    bool read,
    bool update,
    bool delete,
  ) {
    RealmObjectBase.set(this, '_id', id);
    RealmObjectBase.set(this, 'screen', screen);
    RealmObjectBase.set(this, 'create', create);
    RealmObjectBase.set(this, 'read', read);
    RealmObjectBase.set(this, 'update', update);
    RealmObjectBase.set(this, 'delete', delete);
  }

  PermissionRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, '_id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, '_id', value);

  @override
  String get screen => RealmObjectBase.get<String>(this, 'screen') as String;
  @override
  set screen(String value) => RealmObjectBase.set(this, 'screen', value);

  @override
  bool get create => RealmObjectBase.get<bool>(this, 'create') as bool;
  @override
  set create(bool value) => RealmObjectBase.set(this, 'create', value);

  @override
  bool get read => RealmObjectBase.get<bool>(this, 'read') as bool;
  @override
  set read(bool value) => RealmObjectBase.set(this, 'read', value);

  @override
  bool get update => RealmObjectBase.get<bool>(this, 'update') as bool;
  @override
  set update(bool value) => RealmObjectBase.set(this, 'update', value);

  @override
  bool get delete => RealmObjectBase.get<bool>(this, 'delete') as bool;
  @override
  set delete(bool value) => RealmObjectBase.set(this, 'delete', value);

  @override
  Stream<RealmObjectChanges<PermissionRealm>> get changes =>
      RealmObjectBase.getChanges<PermissionRealm>(this);

  @override
  Stream<RealmObjectChanges<PermissionRealm>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<PermissionRealm>(this, keyPaths);

  @override
  PermissionRealm freeze() =>
      RealmObjectBase.freezeObject<PermissionRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      '_id': id.toEJson(),
      'screen': screen.toEJson(),
      'create': create.toEJson(),
      'read': read.toEJson(),
      'update': update.toEJson(),
      'delete': delete.toEJson(),
    };
  }

  static EJsonValue _toEJson(PermissionRealm value) => value.toEJson();
  static PermissionRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        '_id': EJsonValue id,
        'screen': EJsonValue screen,
        'create': EJsonValue create,
        'read': EJsonValue read,
        'update': EJsonValue update,
        'delete': EJsonValue delete,
      } =>
        PermissionRealm(
          fromEJson(id),
          fromEJson(screen),
          fromEJson(create),
          fromEJson(read),
          fromEJson(update),
          fromEJson(delete),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(PermissionRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, PermissionRealm, 'PermissionRealm', [
      SchemaProperty('id', RealmPropertyType.string,
          mapTo: '_id', primaryKey: true),
      SchemaProperty('screen', RealmPropertyType.string),
      SchemaProperty('create', RealmPropertyType.bool),
      SchemaProperty('read', RealmPropertyType.bool),
      SchemaProperty('update', RealmPropertyType.bool),
      SchemaProperty('delete', RealmPropertyType.bool),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
