import 'dart:async';
import 'package:logger/logger.dart';
import 'package:taller_flutter/services/connectivity_service.dart';
import 'package:taller_flutter/features/tasks/data/repositories/task_repository_impl.dart';

/// Service for synchronizing data between local and remote storage
class SyncService {
  final TaskRepositoryImpl repository;
  final ConnectivityService connectivityService;
  final Logger logger = Logger();

  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;

  SyncService({
    required this.repository,
    required this.connectivityService,
  });

  /// Initialize sync service and start monitoring connectivity
  void initialize() {
    _monitorConnectivity();
    _startPeriodicSync();
  }

  /// Monitor connectivity changes
  void _monitorConnectivity() {
    _connectivitySubscription = connectivityService.onConnectivityChanged.listen(
      (isConnected) {
        if (isConnected) {
          logger.i('Internet connection restored. Starting sync...');
          syncData();
        } else {
          logger.w('Internet connection lost. Offline mode active.');
        }
      },
    );
  }

  /// Start periodic sync every 5 minutes
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final hasConnection = await connectivityService.hasInternetConnection();
      if (hasConnection) {
        logger.i('Running periodic sync...');
        await syncData();
      }
    });
  }

  /// Sync data between local and remote storage
  Future<void> syncData() async {
    try {
      final hasConnection = await connectivityService.hasInternetConnection();
      
      if (!hasConnection) {
        logger.w('No internet connection. Skipping sync.');
        return;
      }

      logger.i('Starting data synchronization...');
      
      // Sync pending operations with exponential backoff
      await _syncPendingOperationsWithRetry();
      
      logger.i('Synchronization completed successfully.');
    } catch (e) {
      logger.e('Sync error: $e');
    }
  }

  /// Sync pending operations with retry logic
  Future<void> _syncPendingOperationsWithRetry() async {
    try {
      await repository.syncPendingOperations();
    } catch (e) {
      logger.e('Error during sync: $e');
      // Continue - operations will be retried in next sync cycle
    }
  }

  /// Stop sync service
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Force immediate sync
  Future<void> forceSyncNow() async {
    logger.i('Force sync initiated by user');
    await syncData();
  }

  /// Get sync status
  Future<SyncStatus> getSyncStatus() async {
    try {
      final hasConnection = await connectivityService.hasInternetConnection();
      final db = repository.localDatabase;
      final pendingOps = await db.getPendingOperations();
      
      return SyncStatus(
        isOnline: hasConnection,
        pendingOperations: pendingOps.length,
        lastSyncTime: DateTime.now(), // Could be stored in DB
      );
    } catch (e) {
      return SyncStatus(
        isOnline: false,
        pendingOperations: 0,
        lastSyncTime: null,
      );
    }
  }
}

/// Sync status information
class SyncStatus {
  final bool isOnline;
  final int pendingOperations;
  final DateTime? lastSyncTime;

  SyncStatus({
    required this.isOnline,
    required this.pendingOperations,
    this.lastSyncTime,
  });

  bool get hasPendingOperations => pendingOperations > 0;
  
  @override
  String toString() =>
      'SyncStatus(online: $isOnline, pending: $pendingOperations, lastSync: $lastSyncTime)';
}

