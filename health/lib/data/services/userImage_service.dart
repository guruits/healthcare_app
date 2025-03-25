import 'dart:convert';
import 'dart:math' as Math;
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:realm/realm.dart';
import '../models/realm/faceimage_realm_model.dart';

class SyncStatus {
  bool isSyncing = false;
  DateTime? lastSyncTime;
  String? lastError;
}

class ImageServices {
  Realm? _realm;
  late Realm realm;
  mongo.Db? _mongoClient;
  final SyncStatus syncStatus = SyncStatus();

  // Initialize Realm independently of MongoDB
  // In ImageServices class:
  Future<void> initialize() async {
    try {
      // Initialize Realm with proper configuration
      final config = Configuration.local(
        [ImageRealm.schema],
        schemaVersion: 6,
        migrationCallback: (migration, oldSchemaVersion) {
          // Handle migrations from older versions
          if (oldSchemaVersion < 6) {
            print('Migrating from schema version $oldSchemaVersion to 6');
          }
        },
      );

      // Open the Realm database
      _realm = await Realm.open(config);

      // Initialize the late realm field with the opened instance
      realm = _realm!;

      print('ImageServices: Realm initialized successfully with schema version 6');

      // Try to connect to MongoDB in the background
      await _connectToMongoDB();
    } catch (e) {
      print('Error initializing Realm in ImageServices: $e');
      throw Exception('Failed to initialize Realm in ImageServices: $e');
    }
  }

  // Separate MongoDB connection method
  Future<void> _connectToMongoDB() async {
    try {
      _mongoClient = await mongo.Db.create(
          'mongodb+srv://edwinprakash603:Edwin2001@cluster0.ykeuu.mongodb.net/test'
      );
      await _mongoClient!.open();
      print('MongoDB connection established successfully');

      // Trigger initial sync of any pending items
      _triggerBackgroundSync();
    } catch (e) {
      print('Error connecting to MongoDB: $e');
      syncStatus.lastError = "Connection error: $e";
      // We'll continue with local Realm data only
    }
  }

  // Background sync method
  Future<void> _triggerBackgroundSync() async {
    // Only sync if we're not already syncing and MongoDB is connected
    if (syncStatus.isSyncing || _mongoClient == null) return;

    syncStatus.isSyncing = true;

    try {
      await backgroundSync();
      syncStatus.lastSyncTime = DateTime.now();
      syncStatus.lastError = null;
      print("Background sync completed successfully");
    } catch (e) {
      print("Background sync error: $e");
      syncStatus.lastError = "Sync error: $e";
    } finally {
      syncStatus.isSyncing = false;
    }
  }

  // Create or update image for a user with MongoDB sync
  Future<void> saveUserImage(
      String userId,
      String base64Image, {
        String? contentType,
      }) async {
    try {
      // Save to local Realm first
      realm.write(() {
        final existingImage = realm.all<ImageRealm>()
            .where((image) => image.userId == userId)
            .firstOrNull;

        if (existingImage != null) {
          existingImage.base64Image = base64Image;
          existingImage.contentType = contentType;
          existingImage.isSynced = false;
        } else {
          realm.add(ImageRealm(
            ObjectId(),
            userId,
            base64Image,
            DateTime.now(),
            contentType: contentType,
            isSynced: false,
          ));
        }
      });

      // Attempt to sync with MongoDB if connected
      if (_mongoClient != null) {
        await _syncImageToMongoDB(userId, base64Image, contentType);
      } else {
        // Try to connect if not already connected
        _connectToMongoDB();
      }
    } catch (e) {
      print('Error saving user image: $e');
      throw Exception('Error saving user image: $e');
    }
  }

  // Sync local Realm data to MongoDB
  Future<void> _syncImageToMongoDB(
      String userId,
      String base64Image,
      String? contentType,
      ) async {
    if (_mongoClient == null) {
      await _connectToMongoDB();
      if (_mongoClient == null) return; // Still not connected
    }

    try {
      final collection = _mongoClient!.collection('user_images');

      // Check if image already exists
      final existingDoc = await collection.findOne(
        mongo.where.eq('userId', userId),
      );

      if (existingDoc != null) {
        // Update existing document
        await collection.update(
          mongo.where.eq('userId', userId),
          {
            r'$set': {
              'base64Image': base64Image,
              'contentType': contentType,
              'updatedAt': DateTime.now(),
            }
          },
        );
      } else {
        // Insert new document
        final result = await collection.insertOne({
          'userId': userId,
          'base64Image': base64Image,
          'contentType': contentType,
          'createdAt': DateTime.now(),
        });

        // Update local Realm with MongoDB ID
        realm.write(() {
          final localImage = realm.all<ImageRealm>()
              .where((image) => image.userId == userId)
              .firstOrNull;

          if (localImage != null) {
            localImage.mongoId = result.id.toHexString();
            localImage.isSynced = true;
          }
        });
      }

      // Mark as synced in Realm
      realm.write(() {
        final localImage = realm.all<ImageRealm>()
            .where((image) => image.userId == userId)
            .firstOrNull;

        if (localImage != null) {
          localImage.isSynced = true;
        }
      });
    } catch (e) {
      print('MongoDB sync error: $e');
    }
  }

  // Retrieve image for a user (prioritize local Realm)
  ImageRealm? getUserImage(String userId) {
    print("Fetching user image from Realm for userId: $userId");
    final image = realm.all<ImageRealm>()
        .where((image) => image.userId == userId)
        .firstOrNull;
    if (image != null) {
      print("Image found in Realm: UserId: ${image.userId}, IsSynced: ${image.isSynced}");
    } else {
      print("No image found in Realm for userId: $userId");
    }
    return image;
  }
  Future<void> debugMongoDBConnection(String userId) async {
    try {
      if (_mongoClient == null) {
        print("MongoDB client not connected. Connecting...");
        await _connectToMongoDB();
        if (_mongoClient == null) {
          print("Failed to connect to MongoDB");
          return;
        }
      }

      print("Connected to MongoDB. Querying users collection...");
      final usersCollection = _mongoClient!.collection('users');

      // Try different query approaches
      print("Querying with string ID...");
      var userDoc = await usersCollection.findOne(mongo.where.eq('_id', userId));

      if (userDoc == null) {
        print("Not found with string ID. Trying ObjectId...");
        try {
          final objectId = mongo.ObjectId.fromHexString(userId);
          userDoc = await usersCollection.findOne(mongo.where.eq('_id', objectId));
        } catch (e) {
          print("Failed to convert to ObjectId: $e");
        }
      }

      if (userDoc != null) {
        print("Found user document. Keys: ${userDoc.keys.toList()}");
        if (userDoc.containsKey('face_image')) {
          print("Document contains face_image field");
          var faceImage = userDoc['face_image'];
          print("face_image structure: ${faceImage.runtimeType}");
          print("face_image keys: ${faceImage is Map ? faceImage.keys.toList() : 'Not a map'}");

          if (faceImage is Map && faceImage.containsKey('data')) {
            var imageData = faceImage['data'];
            print("imageData structure: ${imageData.runtimeType}");
            print("imageData keys: ${imageData is Map ? imageData.keys.toList() : 'Not a map'}");

            if (imageData is Map && imageData.containsKey('\$binary')) {
              var binary = imageData['\$binary'];
              print("binary structure: ${binary.runtimeType}");
              print("binary keys: ${binary is Map ? binary.keys.toList() : 'Not a map'}");

              if (binary is Map && binary.containsKey('base64')) {
                var base64Data = binary['base64'];
                print("Found base64 data, length: ${base64Data.length}");
                //print("Sample data: ${base64Data.substring(0, Math.min(50, base64Data.length))}...");

                try {
                  final decodedBytes = base64Decode(base64Data);
                  print("Successfully decoded base64. Byte length: ${decodedBytes.length}");
                } catch (e) {
                  print("Failed to decode base64: $e");
                }
              }
            }
          }
        } else {
          print("Document does not contain face_image field");
        }
      } else {
        print("User document not found with ID: $userId");
      }
    } catch (e) {
      print("MongoDB debug error: $e");
      print("Stack trace: ${StackTrace.current}");
    }
  }

  // Fetch image from MongoDB if not found locally
  Future<ImageRealm?> getUserImageWithMongoBackup(String userId) async {
    print("Fetching user image with MongoDB backup for userId: $userId");
    ImageRealm? localImage = getUserImage(userId);
    if (localImage != null) {
      print("Image found in local Realm, returning it");
      return localImage;
    }

    if (_mongoClient == null) {
      print("MongoDB client not connected. Attempting to connect...");
      await _connectToMongoDB();
      if (_mongoClient == null) {
        print("Failed to connect to MongoDB. Returning null.");
        return null;
      }
    }

    try {
      print("Searching for image in user_images collection...");
      final collection = _mongoClient!.collection('user_images');
      final doc = await collection.findOne(mongo.where.eq('userId', userId));

      if (doc == null) {
        print("No dedicated image found, searching in users collection...");
        final usersCollection = _mongoClient!.collection('users');

        // Try to find by ObjectId if userId is a valid ObjectId
        mongo.ObjectId? objectId;
        try {
          objectId = mongo.ObjectId.fromHexString(userId);
        } catch (e) {
          print("userId is not a valid ObjectId: $e");
        }

        final query = objectId != null ?
        mongo.where.eq('_id', objectId) :
        mongo.where.eq('_id', userId);

        final userDoc = await usersCollection.findOne(query);
        print("User document found: ${userDoc != null}");

        if (userDoc != null && userDoc.containsKey('face_image')) {
          // Extract image data from user document
          final faceImage = userDoc['face_image'];
          print("Face image data type: ${faceImage.runtimeType}");

          if (faceImage != null) {
            String? base64Image;
            String? contentType = 'image/jpeg';

            // Handle different ways the binary data might be stored
            if (faceImage.containsKey('data')) {
              var imageData = faceImage['data'];
              print("Image data type: ${imageData.runtimeType}");

              // Case 1: Binary data in MongoDB's binary format
              if (imageData is mongo.BsonBinary) {
                print("Converting MongoDB BsonBinary to base64");
                base64Image = base64Encode(imageData.byteList);
              }
              // Case 2: Data is in extended JSON format with $binary.base64
              else if (imageData is Map &&
                  imageData.containsKey('\$binary') &&
                  imageData['\$binary'] is Map &&
                  imageData['\$binary'].containsKey('base64')) {
                print("Extracting base64 from \$binary.base64 format");
                base64Image = imageData['\$binary']['base64'];
              }
              // Case 3: Direct base64 string (less common)
              else if (imageData is String) {
                print("Using string data directly as base64");
                base64Image = imageData;
              }

              if (faceImage.containsKey('contentType')) {
                contentType = faceImage['contentType'];
                print("Content type found: $contentType");
              }

              if (base64Image != null) {
                print("Successfully extracted base64 image, length: ${base64Image.length}");
                return realm.write(() {
                  return realm.add(ImageRealm(
                    ObjectId(),
                    userId,
                    base64Image!,
                    DateTime.now(),
                    contentType: contentType,
                    isSynced: true,
                  ));
                });
              } else {
                print("Failed to extract base64 image");
              }
            } else {
              print("No 'data' field in face_image object");
            }
          }
        } else {
          print("User document doesn't contain face_image field");
        }

        print("No image found in MongoDB for userId: $userId");
        return null;
      }

      print("Image found in user_images collection for UserId: ${doc['userId']}, Image Length: ${doc['base64Image'].length}");
      return realm.write(() {
        return realm.add(ImageRealm(
          ObjectId(),
          userId,
          doc['base64Image'],
          DateTime.now(),
          contentType: doc['contentType'],
          isSynced: true,
          mongoId: doc['_id'] is mongo.ObjectId ? doc['_id'].toHexString() : doc['_id'].toString(),
        ));
      });
    } catch (e) {
      print("Error fetching image from MongoDB: $e");
      print("Stack trace: ${StackTrace.current}");
    }

    return null;
  }


  // Delete user image from both Realm and MongoDB
  Future<void> deleteUserImage(String userId) async {
    // Always delete from Realm first
    realm.write(() {
      final imagesToDelete = realm.all<ImageRealm>()
          .where((image) => image.userId == userId);
      realm.deleteMany(imagesToDelete);
    });

    // Try to delete from MongoDB if connected
    if (_mongoClient == null) {
      await _connectToMongoDB();
      if (_mongoClient == null) return; // Still not connected
    }

    try {
      final collection = _mongoClient!.collection('user_images');
      await collection.deleteMany(
        mongo.where.eq('userId', userId),
      );
    } catch (e) {
      print('Error deleting image from MongoDB: $e');
    }
  }

  // Perform background sync of unsynced images
  Future<void> backgroundSync() async {
    if (_mongoClient == null) {
      await _connectToMongoDB();
      if (_mongoClient == null) return; // Still not connected
    }

    final unsyncedImages = realm.all<ImageRealm>()
        .where((image) => image.isSynced == false)
        .toList();

    print('Found ${unsyncedImages.length} unsynced images to sync');

    for (var image in unsyncedImages) {
      await _syncImageToMongoDB(
        image.userId,
        image.base64Image,
        image.contentType,
      );
    }
  }

  // Force a sync now - can be called from UI
  Future<bool> syncNow() async {
    if (_mongoClient == null) {
      // Try to connect first
      try {
        await _connectToMongoDB();
      } catch (e) {
        return false;
      }
    }

    if (_mongoClient != null && !syncStatus.isSyncing) {
      await _triggerBackgroundSync();
      return true;
    }
    return false;
  }

  // Check connection status
  bool isConnected() {
    return _mongoClient != null;
  }

  // Get sync status
  SyncStatus getSyncStatus() {
    return syncStatus;
  }

  // Close connections
  Future<void> dispose() async {
    realm.close();
    if (_mongoClient != null) {
      await _mongoClient!.close();
    }
  }
}