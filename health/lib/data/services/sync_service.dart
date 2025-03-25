import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/data/services/realm_service.dart';
import 'package:health/data/services/realmrole_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Sync status
  bool isSyncing = false;
  DateTime? lastSyncTime;
  String? lastError;
  Timer? _syncTimer;

  // Services
  final roleService = MongoRealmRoleService();
  final userService = MongoRealmUserService();

  // Stream controller for sync status updates
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // Initialize services
  Future<void> initialize() async {
    // Initialize Realm first (fast)
    await userService.initialize();

    // Start periodic sync
    startPeriodicSync(Duration(minutes: 15));

    // Try to connect to MongoDB in background
    _connectToMongoDB();
  }

  // Connect to MongoDB in background
  Future<void> _connectToMongoDB() async {
    try {
      // Connect to MongoDB
      final connected = await userService.connectToMongoDB();
      if (connected) {
        // Only initialize roleService if MongoDB is connected
        //await roleService.initialize(userService.getMongoDbInstance());

        // Initial sync
        await syncAll();
      }
    } catch (e) {
      updateSyncStatus(error: 'Connection error: $e');
    }
  }

  // Start periodic sync
  void startPeriodicSync(Duration interval) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncAll());
  }

  // Sync all data
  Future<void> syncAll() async {
    if (isSyncing || !userService.isConnected()) return;

    isSyncing = true;
    updateSyncStatus(isSyncing: true);

    try {
      // First sync users (faster)
      await userService.syncMongoToRealm();

      // Then sync roles (slower)
      await roleService.syncMongoToRealm();

      lastSyncTime = DateTime.now();
      updateSyncStatus();
    } catch (e) {
      updateSyncStatus(error: 'Sync error: $e');
    } finally {
      isSyncing = false;
      updateSyncStatus(isSyncing: false);
    }
  }

  // Force a sync now
  Future<bool> syncNow() async {
    if (isSyncing) return false;

    if (!userService.isConnected()) {
      try {
        // Try to connect first
        final connected = await userService.connectToMongoDB();
        if (!connected) return false;

        // Initialize role service with the MongoDB instance
        //await roleService.initialize(userService.getMongoDbInstance());
      } catch (e) {
        updateSyncStatus(error: 'Connection error: $e');
        return false;
      }
    }

    await syncAll();
    return true;
  }

  // Update sync status
  void updateSyncStatus({bool? isSyncing, String? error}) {
    final status = SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime,
      lastError: error ?? lastError,
    );

    _syncStatusController.add(status);
  }

  // Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
    userService.dispose();
    roleService.dispose();
  }
}

class SyncStatus {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? lastError;

  SyncStatus({
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastError,
  });
}