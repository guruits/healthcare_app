import 'package:realm/realm.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../models/realm/screen_realm_model.dart';
import '../models/screen.dart';

class MongoRealmScreenService {
  late final Realm _realm;
  late final mongo.Db _mongodb;

  // Initialize Realm and MongoDB connection
  Future<void> initialize() async {
    final config = Configuration.local(
      [ScreenRealm.schema],
      schemaVersion: 7,
      migrationCallback: (migration, oldSchemaVersion) {
        // Handle migration if needed
      },
    );

    _realm = await Realm.open(config);

    _mongodb = await mongo.Db.create('mongodb+srv://edwinprakash603:Edwin2001@cluster0.ykeuu.mongodb.net/test');
    print("Connected to MongoDB for screens");
    await _mongodb.open();

    // Initial sync from MongoDB to Realm
    await syncMongoToRealm();
  }

  // Convert MongoDB document to Screen model
  Screen _convertMongoDocToScreen(Map<String, dynamic> doc) {
    // Debug printing to see the raw MongoDB document
    print("Raw MongoDB screen document: $doc");

    return Screen(
      id: doc['_id'] is mongo.ObjectId ? doc['_id'].toHexString() : doc['_id'].toString(),
      name: doc['name']?.toString() ?? '',
      description: doc['description']?.toString() ?? '',
      isActive: doc['isActive'] ?? true,
    );
  }

  // Convert ScreenRealm to Screen model
  Screen _convertRealmToScreen(ScreenRealm realmScreen) {
    return Screen(
      id: realmScreen.id,
      name: realmScreen.name ?? '',
      description: realmScreen.description ?? '',
      isActive: realmScreen.isActive ?? true,
    );
  }

  // Sync all MongoDB data to Realm
  Future<void> syncMongoToRealm() async {
    try {
      final collection = _mongodb.collection('screens');
      final screens = await collection.find().toList();

      _realm.write(() {
        for (var mongoScreen in screens) {
          try {
            final screen = _convertMongoDocToScreen(mongoScreen);

            // Check if screen already exists in Realm
            final existingScreen = _realm.find<ScreenRealm>(screen.id!);

            if (existingScreen != null) {
              // Update existing screen
              existingScreen.name = screen.name;
              existingScreen.description = screen.description;
              existingScreen.isActive = screen.isActive;
            } else {
              // Add new screen
              _realm.add(
                ScreenRealm(
                  screen.id!,
                  name: screen.name,
                  description: screen.description,
                  isActive: screen.isActive,
                ),
              );
            }
          } catch (e) {
            print("Error syncing screen to Realm: $e");
          }
        }
      });
      print("Successfully synced ${screens.length} screens from MongoDB to Realm");
    } catch (e) {
      print("Error during syncMongoToRealm for screens: $e");
      throw Exception('Error syncing screens to Realm: $e');
    }
  }

  // CRUD Operations
  Future<List<Screen>> getAllScreens() async {
    try {
      // Fetch from Realm first
      final realmScreens = _realm.all<ScreenRealm>();

      if (realmScreens.isNotEmpty) {
        print("Fetched ${realmScreens.length} screens from Realm");
        return realmScreens.map((realmScreen) => _convertRealmToScreen(realmScreen)).toList();
      }

      // If Realm is empty, sync from MongoDB
      print("Realm is empty, syncing from MongoDB...");
      await syncMongoToRealm();

      // Fetch again from Realm after syncing
      final updatedRealmScreens = _realm.all<ScreenRealm>();
      print("Fetched ${updatedRealmScreens.length} screens from Realm after sync");

      return updatedRealmScreens.map((realmScreen) => _convertRealmToScreen(realmScreen)).toList();
    } catch (e) {
      print("Error in getAllScreens: $e");
      throw Exception('Error fetching screens: $e');
    }
  }


  Future<Screen> createScreen(Screen screen) async {
    try {
      // Insert into MongoDB
      final collection = _mongodb.collection('screens');

      final result = await collection.insert({
        'name': screen.name,
        'description': screen.description,
        'isActive': screen.isActive,
      });

      // Get the inserted ID
      String id = '';
      if (result.containsKey('_id')) {
        id = result['_id'] is mongo.ObjectId
            ? result['_id'].toHexString()
            : result['_id'].toString();
      }

      //screen.id = id;

      // Add to Realm
      _realm.write(() {
        _realm.add(ScreenRealm(
          id,
          name: screen.name,
          description: screen.description,
          isActive: screen.isActive,
        ));
      });

      return screen;
    } catch (e) {
      print("Error in createScreen: $e");
      throw Exception('Error creating screen: $e');
    }
  }

  Future<Screen> updateScreen(String id, Screen screen) async {
    try {
      // Update MongoDB
      final collection = _mongodb.collection('screens');

      await collection.update(
        mongo.where.id(mongo.ObjectId.parse(id)),
        {
          '\$set': {
            'name': screen.name,
            'description': screen.description,
            'isActive': screen.isActive,
          }
        },
      );

      // Update Realm
      _realm.write(() {
        final realmScreen = _realm.find<ScreenRealm>(id);
        if (realmScreen != null) {
          realmScreen.name = screen.name;
          realmScreen.description = screen.description;
          realmScreen.isActive = screen.isActive;
        } else {
          print("Warning: Screen not found in Realm during update. Creating new entry.");
          _realm.add(ScreenRealm(
            id,
            name: screen.name,
            description: screen.description,
            isActive: screen.isActive,
          ));
        }
      });

      //screen.id = id;
      return screen;
    } catch (e) {
      print("Error in updateScreen: $e");
      throw Exception('Error updating screen: $e');
    }
  }

  Future<void> deactivateScreen(String name) async {
    try {
      // In this implementation, we'll just set isActive to false
      final collection = _mongodb.collection('screens');

      // Find the screen by name
      final query = mongo.where.eq('name', name);
      final mongoScreen = await collection.findOne(query);

      if (mongoScreen == null) {
        throw Exception('Screen with name $name not found');
      }

      final id = mongoScreen['_id'] is mongo.ObjectId
          ? mongoScreen['_id'].toHexString()
          : mongoScreen['_id'].toString();

      // Update MongoDB
      await collection.update(
        mongo.where.id(mongoScreen['_id']),
        {'\$set': {'isActive': false}},
      );

      // Update Realm
      _realm.write(() {
        final realmScreen = _realm.find<ScreenRealm>(id);
        if (realmScreen != null) {
          realmScreen.isActive = false;
        } else {
          print("Warning: Screen not found in Realm during deactivation");
        }
      });
    } catch (e) {
      print("Error in deactivateScreen: $e");
      throw Exception('Error deactivating screen: $e');
    }
  }

  // Sync an individual screen from MongoDB to Realm
  Future<void> syncScreenToRealm(String screenId) async {
    try {
      final collection = _mongodb.collection('screens');
      final mongoScreen = await collection.findOne(mongo.where.id(mongo.ObjectId.parse(screenId)));

      if (mongoScreen == null) {
        throw Exception('Screen not found in MongoDB');
      }

      final screen = _convertMongoDocToScreen(mongoScreen);

      _realm.write(() {
        final existingScreen = _realm.find<ScreenRealm>(screenId);

        if (existingScreen != null) {
          existingScreen.name = screen.name;
          existingScreen.description = screen.description;
          existingScreen.isActive = screen.isActive;
        } else {
          _realm.add(
            ScreenRealm(
              screen.id!,
              name: screen.name,
              description: screen.description,
              isActive: screen.isActive,
            ),
          );
        }
      });
    } catch (e) {
      print("Error syncing individual screen to Realm: $e");
      throw Exception('Error syncing screen: $e');
    }
  }

  Future<void> dispose() async {
    _realm.close();
    await _mongodb.close();
  }
}