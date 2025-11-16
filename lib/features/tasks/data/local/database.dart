import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:taller_flutter/features/tasks/data/models/task_model.dart';
import 'package:taller_flutter/features/tasks/data/models/queue_operation.dart';

/// Local database management using SQLite
class LocalDatabase {
  static const String dbName = 'taller_flutter.db';
  static const int dbVersion = 1;

  static const String tasksTable = 'tasks';
  static const String queueTable = 'queue_operations';

  Database? _database;
  // In-memory fallback for web
  final Map<String, Map<String, dynamic>> _tasksStore = {};
  final Map<String, Map<String, dynamic>> _queueStore = {};

  Future<Database> get database async {
    if (kIsWeb) {
      // On web we don't have a sqflite-backed Database; callers should use
      // the in-memory stores implemented below. Return a dummy that
      // will not be used in web code paths.
      throw StateError('sqflite database not available on web');
    }
    _database ??= await initDb();
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> initDb() async {
    if (kIsWeb) {
      // No sqlite available on web in this project; initialization is a no-op.
      // Methods will use in-memory stores instead.
      throw StateError('databaseFactory not initialized for web');
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tasksTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $queueTable (
        id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // TODO: Implement migration logic if needed
  }

  /// Close database connection
  Future<void> closeDb() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // ============ TASKS TABLE OPERATIONS ============

  /// Insert or update a task
  Future<int> insertTask(TaskModel task) async {
    if (kIsWeb) {
      _tasksStore[task.id] = task.toSqflite();
      return Future.value(1);
    }

    final db = await database;
    return db.insert(
      tasksTable,
      task.toSqflite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all tasks (not deleted)
  Future<List<TaskModel>> getAllTasks() async {
    if (kIsWeb) {
      final rows = _tasksStore.values
          .where((m) => (m['deleted'] as int? ?? 0) == 0)
          .toList()
        ..sort((a, b) => (b['updated_at'] as String)
            .compareTo(a['updated_at'] as String));
      return rows.map((e) => TaskModel.fromSqflite(e)).toList();
    }

    final db = await database;
    final result = await db.query(
      tasksTable,
      where: 'deleted = 0',
      orderBy: 'updated_at DESC',
    );
    return result.map((e) => TaskModel.fromSqflite(e)).toList();
  }

  /// Get task by ID
  Future<TaskModel?> getTaskById(String id) async {
    if (kIsWeb) {
      final row = _tasksStore[id];
      if (row == null) return null;
      if ((row['deleted'] as int? ?? 0) == 1) return null;
      return TaskModel.fromSqflite(row);
    }

    final db = await database;
    final result = await db.query(
      tasksTable,
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return TaskModel.fromSqflite(result.first);
    }
    return null;
  }

  /// Update task
  Future<int> updateTask(TaskModel task) async {
    if (kIsWeb) {
      if (!_tasksStore.containsKey(task.id)) return 0;
      _tasksStore[task.id] = task.toSqflite();
      return Future.value(1);
    }

    final db = await database;
    return db.update(
      tasksTable,
      task.toSqflite(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Delete task (soft delete)
  Future<int> deleteTask(String id) async {
    if (kIsWeb) {
      final row = _tasksStore[id];
      if (row == null) return Future.value(0);
      row['deleted'] = 1;
      _tasksStore[id] = row;
      return Future.value(1);
    }

    final db = await database;
    return db.update(
      tasksTable,
      {'deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all tasks (for testing/cleanup)
  Future<void> clearTasks() async {
    if (kIsWeb) {
      _tasksStore.clear();
      return;
    }

    final db = await database;
    await db.delete(tasksTable);
  }

  // ============ QUEUE OPERATIONS TABLE OPERATIONS ============

  /// Insert queue operation
  Future<int> insertQueueOperation(QueueOperation operation) async {
    if (kIsWeb) {
      _queueStore[operation.id] = operation.toSqflite();
      return Future.value(1);
    }

    final db = await database;
    return db.insert(
      queueTable,
      operation.toSqflite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all pending operations
  Future<List<QueueOperation>> getPendingOperations() async {
    if (kIsWeb) {
      final rows = _queueStore.values.toList()
        ..sort((a, b) => (a['created_at'] as int).compareTo(b['created_at'] as int));
      return rows.map((e) => QueueOperation.fromSqflite(e)).toList();
    }

    final db = await database;
    final result = await db.query(
      queueTable,
      orderBy: 'created_at ASC',
    );
    return result.map((e) => QueueOperation.fromSqflite(e)).toList();
  }

  /// Get pending operations with retry count less than max
  Future<List<QueueOperation>> getOperationsToSync({int maxAttempts = 5}) async {
    if (kIsWeb) {
      final rows = _queueStore.values
          .where((r) => (r['attempt_count'] as int? ?? 0) < maxAttempts)
          .toList()
        ..sort((a, b) => (a['created_at'] as int).compareTo(b['created_at'] as int));
      return rows.map((e) => QueueOperation.fromSqflite(e)).toList();
    }

    final db = await database;
    final result = await db.query(
      queueTable,
      where: 'attempt_count < ?',
      whereArgs: [maxAttempts],
      orderBy: 'created_at ASC',
    );
    return result.map((e) => QueueOperation.fromSqflite(e)).toList();
  }

  /// Update queue operation
  Future<int> updateQueueOperation(QueueOperation operation) async {
    if (kIsWeb) {
      if (!_queueStore.containsKey(operation.id)) return Future.value(0);
      _queueStore[operation.id] = operation.toSqflite();
      return Future.value(1);
    }

    final db = await database;
    return db.update(
      queueTable,
      operation.toSqflite(),
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }

  /// Delete queue operation
  Future<int> deleteQueueOperation(String id) async {
    if (kIsWeb) {
      return Future.value(_queueStore.remove(id) != null ? 1 : 0);
    }

    final db = await database;
    return db.delete(
      queueTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Increment attempt count for operation
  Future<void> incrementAttemptCount(String operationId) async {
    if (kIsWeb) {
      final row = _queueStore[operationId];
      if (row != null) {
        row['attempt_count'] = (row['attempt_count'] as int? ?? 0) + 1;
        _queueStore[operationId] = row;
      }
      return;
    }

    final db = await database;
    await db.rawUpdate(
      'UPDATE $queueTable SET attempt_count = attempt_count + 1 WHERE id = ?',
      [operationId],
    );
  }

  /// Update operation with error
  Future<void> setOperationError(String operationId, String error) async {
    if (kIsWeb) {
      final row = _queueStore[operationId];
      if (row != null) {
        row['last_error'] = error;
        _queueStore[operationId] = row;
      }
      return;
    }

    final db = await database;
    await db.update(
      queueTable,
      {'last_error': error},
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  /// Clear all queue operations (for testing)
  Future<void> clearQueue() async {
    if (kIsWeb) {
      _queueStore.clear();
      return;
    }

    final db = await database;
    await db.delete(queueTable);
  }

  /// Clear all data (for testing/logout)
  Future<void> clearAllData() async {
    await clearTasks();
    await clearQueue();
  }
}

