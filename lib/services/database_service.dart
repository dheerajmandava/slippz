import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/receipt.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database == null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        _database = await openDatabase(
          '${directory.path}/receipts.db',
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS receipts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                productName TEXT NOT NULL,
                purchaseDate TEXT NOT NULL,
                warrantyEndDate TEXT NOT NULL,
                receiptImagePath TEXT NOT NULL,
                storeName TEXT NOT NULL,
                price REAL NOT NULL,
                category TEXT NOT NULL
              );
            ''');
          },
        );
      } catch (e) {
        throw Exception('Failed to initialize database: $e');
      }
    }
    return _database!;
  }

  Future<void> insertReceipt(Receipt receipt) async {
    try {
      final db = await database;
      await db.insert(
        'receipts',
        receipt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert receipt: $e');
    }
  }

  Future<List<Receipt>> getAllReceipts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query('receipts');
      
      return rows.map<Receipt>((row) => Receipt.fromMap(row)).toList();
    } catch (e) {
      throw Exception('Failed to get receipts: $e');
    }
  }

  Future<void> deleteReceipt(int id) async {
    try {
      final db = await database;
      await db.delete(
        'receipts',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
