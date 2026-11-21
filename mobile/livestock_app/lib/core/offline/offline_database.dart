import 'package:sqflite/sqflite.dart';
import 'offline_queue_item.dart';

class OfflineDatabase {
  static const _dbName = 'livestock_offline.db';
  static const _dbVersion = 1;
  static const _table = 'sync_queue';

  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = '${await getDatabasesPath()}/$_dbName';
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $_table (
          id           TEXT PRIMARY KEY,
          operation_type TEXT NOT NULL,
          endpoint     TEXT NOT NULL,
          payload      TEXT NOT NULL,
          created_at   TEXT NOT NULL,
          status       TEXT NOT NULL DEFAULT 'pending',
          retry_count  INTEGER NOT NULL DEFAULT 0,
          error_message TEXT
        )
      '''),
    );
  }

  // Insert a new item at the back of the queue.
  static Future<void> enqueue(OfflineQueueItem item) async {
    final db = await database;
    await db.insert(_table, item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,);
  }

  // Return all pending items ordered FIFO.
  static Future<List<OfflineQueueItem>> pendingItems() async {
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return rows.map(OfflineQueueItem.fromMap).toList();
  }

  // Update status and retry metadata.
  static Future<void> updateItem(OfflineQueueItem item) async {
    final db = await database;
    await db.update(
      _table,
      {
        'status': item.status.name,
        'retry_count': item.retryCount,
        'error_message': item.errorMessage,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Remove a successfully synced item.
  static Future<void> remove(String id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // Drop all queued items — called on logout.
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }

  // Count of items still pending.
  static Future<int> pendingCount() async {
    final db = await database;
    final result =
        await db.rawQuery("SELECT COUNT(*) FROM $_table WHERE status='pending'");
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
