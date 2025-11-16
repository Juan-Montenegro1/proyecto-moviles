import 'package:taller_flutter/features/tasks/data/local/database.dart';

/// Global database instance (singleton)
LocalDatabase? _database;

/// Get the global database instance
LocalDatabase getDatabase() {
  if (_database == null) {
    throw Exception('Database not initialized. Call initializeDatabase() first.');
  }
  return _database!;
}

/// Initialize the global database
Future<void> initializeDatabase() async {
  if (_database == null) {
    // Always create the LocalDatabase instance so callers can obtain it.
    _database = LocalDatabase();

    // Try to pre-open the database, but don't prevent the app from
    // continuing if this fails — the LocalDatabase will lazily initialize
    // on first use via its `database` getter.
    try {
      await _database!.initDb();
    } catch (e) {
      // Keep the instance available; log error for debugging.
      // Avoid rethrowing so the app can continue and attempt lazy init later.
      // Using debugPrint to avoid depending on dart:io.
      // ignore: avoid_print
      print('Warning: failed to pre-initialize database: $e');
    }
  }
}
