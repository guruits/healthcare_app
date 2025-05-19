// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faceimage_realm_model.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class ImageRealm extends _ImageRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  ImageRealm(
    ObjectId id,
    String userId,
    String base64Image,
    DateTime createdAt, {
    String? contentType,
    bool? isSynced,
    String? mongoId,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'userId', userId);
    RealmObjectBase.set(this, 'base64Image', base64Image);
    RealmObjectBase.set(this, 'contentType', contentType);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'isSynced', isSynced);
    RealmObjectBase.set(this, 'mongoId', mongoId);
  }

  ImageRealm._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get userId => RealmObjectBase.get<String>(this, 'userId') as String;
  @override
  set userId(String value) => RealmObjectBase.set(this, 'userId', value);

  @override
  String get base64Image =>
      RealmObjectBase.get<String>(this, 'base64Image') as String;
  @override
  set base64Image(String value) =>
      RealmObjectBase.set(this, 'base64Image', value);

  @override
  String? get contentType =>
      RealmObjectBase.get<String>(this, 'contentType') as String?;
  @override
  set contentType(String? value) =>
      RealmObjectBase.set(this, 'contentType', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  bool? get isSynced => RealmObjectBase.get<bool>(this, 'isSynced') as bool?;
  @override
  set isSynced(bool? value) => RealmObjectBase.set(this, 'isSynced', value);

  @override
  String? get mongoId =>
      RealmObjectBase.get<String>(this, 'mongoId') as String?;
  @override
  set mongoId(String? value) => RealmObjectBase.set(this, 'mongoId', value);

  @override
  Stream<RealmObjectChanges<ImageRealm>> get changes =>
      RealmObjectBase.getChanges<ImageRealm>(this);

  @override
  Stream<RealmObjectChanges<ImageRealm>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<ImageRealm>(this, keyPaths);

  @override
  ImageRealm freeze() => RealmObjectBase.freezeObject<ImageRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'userId': userId.toEJson(),
      'base64Image': base64Image.toEJson(),
      'contentType': contentType.toEJson(),
      'createdAt': createdAt.toEJson(),
      'isSynced': isSynced.toEJson(),
      'mongoId': mongoId.toEJson(),
    };
  }

  static EJsonValue _toEJson(ImageRealm value) => value.toEJson();
  static ImageRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'userId': EJsonValue userId,
        'base64Image': EJsonValue base64Image,
        'createdAt': EJsonValue createdAt,
      } =>
        ImageRealm(
          fromEJson(id),
          fromEJson(userId),
          fromEJson(base64Image),
          fromEJson(createdAt),
          contentType: fromEJson(ejson['contentType']),
          isSynced: fromEJson(ejson['isSynced']),
          mongoId: fromEJson(ejson['mongoId']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(ImageRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, ImageRealm, 'ImageRealm', [
      SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
      SchemaProperty('userId', RealmPropertyType.string),
      SchemaProperty('base64Image', RealmPropertyType.string),
      SchemaProperty('contentType', RealmPropertyType.string, optional: true),
      SchemaProperty('createdAt', RealmPropertyType.timestamp),
      SchemaProperty('isSynced', RealmPropertyType.bool, optional: true),
      SchemaProperty('mongoId', RealmPropertyType.string, optional: true),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
