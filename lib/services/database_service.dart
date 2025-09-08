import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/receipt.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'slippz_local.db';
  static const int _databaseVersion = 2;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, _databaseName);
      
      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
      
      return _database!;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Create receipts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productName TEXT NOT NULL,
        purchaseDate TEXT NOT NULL,
        warrantyEndDate TEXT NOT NULL,
        receiptImagePath TEXT NOT NULL,
        storeName TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isDeleted INTEGER DEFAULT 0
      );
    ''');

    // Create user preferences table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      );
    ''');

    // Create categories table for better category management
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        color TEXT,
        icon TEXT,
        createdAt TEXT NOT NULL
      );
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE receipts ADD COLUMN createdAt TEXT');
      await db.execute('ALTER TABLE receipts ADD COLUMN updatedAt TEXT');
      await db.execute('ALTER TABLE receipts ADD COLUMN isDeleted INTEGER DEFAULT 0');
      
      // Create new tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_preferences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT UNIQUE NOT NULL,
          value TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          color TEXT,
          icon TEXT,
          createdAt TEXT NOT NULL
        );
      ''');

      // Insert default categories
      await _insertDefaultCategories(db);
      
      // Update existing receipts with timestamps
      final now = DateTime.now().toIso8601String();
      await db.execute('UPDATE receipts SET createdAt = ?, updatedAt = ?', [now, now]);
    }
  }

  static Future<void> _onOpen(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Electronics', 'color': '#3B82F6', 'icon': 'electronics'},
      {'name': 'Appliances', 'color': '#10B981', 'icon': 'appliances'},
      {'name': 'Furniture', 'color': '#F59E0B', 'icon': 'furniture'},
      {'name': 'Clothing', 'color': '#EF4444', 'icon': 'clothing'},
      {'name': 'Automotive', 'color': '#8B5CF6', 'icon': 'automotive'},
      {'name': 'Home & Garden', 'color': '#06B6D4', 'icon': 'home_garden'},
      {'name': 'Sports', 'color': '#84CC16', 'icon': 'sports'},
      {'name': 'Food', 'color': '#F97316', 'icon': 'food'},
      {'name': 'Other', 'color': '#6B7280', 'icon': 'other'},
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', {
        ...category,
        'createdAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // Receipt CRUD Operations
  Future<void> insertReceipt(Receipt receipt) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      
      final receiptMap = receipt.toMap();
      receiptMap['createdAt'] = now;
      receiptMap['updatedAt'] = now;
      receiptMap['isDeleted'] = 0;
      
      await db.insert(
        'receipts',
        receiptMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert receipt: $e');
    }
  }

  Future<List<Receipt>> getAllReceipts({bool includeDeleted = false}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'receipts',
        where: includeDeleted ? null : 'isDeleted = ?',
        whereArgs: includeDeleted ? null : [0],
        orderBy: 'createdAt DESC',
      );
      
      return rows.map<Receipt>((row) => Receipt.fromMap(row)).toList();
    } catch (e) {
      throw Exception('Failed to get receipts: $e');
    }
  }

  Future<Receipt?> getReceiptById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'receipts',
        where: 'id = ? AND isDeleted = ?',
        whereArgs: [id, 0],
        limit: 1,
      );
      
      if (rows.isEmpty) return null;
      return Receipt.fromMap(rows.first);
    } catch (e) {
      throw Exception('Failed to get receipt: $e');
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    try {
      final db = await database;
      final receiptMap = receipt.toMap();
      receiptMap['updatedAt'] = DateTime.now().toIso8601String();
      
      await db.update(
        'receipts',
        receiptMap,
        where: 'id = ?',
        whereArgs: [receipt.id],
      );
    } catch (e) {
      throw Exception('Failed to update receipt: $e');
    }
  }

  Future<void> deleteReceipt(int id, {bool permanent = false}) async {
    try {
      final db = await database;
      
      if (permanent) {
        await db.delete(
          'receipts',
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        // Soft delete
        await db.update(
          'receipts',
          {
            'isDeleted': 1,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  Future<void> restoreReceipt(int id) async {
    try {
      final db = await database;
      await db.update(
        'receipts',
        {
          'isDeleted': 0,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to restore receipt: $e');
    }
  }

  // Search and Filter Operations
  Future<List<Receipt>> searchReceipts(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'receipts',
        where: '''
          (productName LIKE ? OR storeName LIKE ? OR category LIKE ?) 
          AND isDeleted = ?
        ''',
        whereArgs: ['%$query%', '%$query%', '%$query%', 0],
        orderBy: 'createdAt DESC',
      );
      
      return rows.map<Receipt>((row) => Receipt.fromMap(row)).toList();
    } catch (e) {
      throw Exception('Failed to search receipts: $e');
    }
  }

  Future<List<Receipt>> getReceiptsByCategory(String category) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'receipts',
        where: 'category = ? AND isDeleted = ?',
        whereArgs: [category, 0],
        orderBy: 'createdAt DESC',
      );
      
      return rows.map<Receipt>((row) => Receipt.fromMap(row)).toList();
    } catch (e) {
      throw Exception('Failed to get receipts by category: $e');
    }
  }

  Future<List<Receipt>> getExpiringWarranties({int daysAhead = 30}) async {
    try {
      final db = await database;
      final cutoffDate = DateTime.now().add(Duration(days: daysAhead)).toIso8601String();
      
      final List<Map<String, dynamic>> rows = await db.query(
        'receipts',
        where: 'warrantyEndDate <= ? AND warrantyEndDate > ? AND isDeleted = ?',
        whereArgs: [cutoffDate, DateTime.now().toIso8601String(), 0],
        orderBy: 'warrantyEndDate ASC',
      );
      
      return rows.map<Receipt>((row) => Receipt.fromMap(row)).toList();
    } catch (e) {
      throw Exception('Failed to get expiring warranties: $e');
    }
  }

  // Category Management
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final db = await database;
      return await db.query('categories', orderBy: 'name ASC');
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<void> addCategory(String name, {String? color, String? icon}) async {
    try {
      final db = await database;
      await db.insert(
        'categories',
        {
          'name': name,
          'color': color ?? '#6B7280',
          'icon': icon ?? 'other',
          'createdAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // User Preferences
  Future<void> setPreference(String key, String value) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      
      await db.insert(
        'user_preferences',
        {
          'key': key,
          'value': value,
          'createdAt': now,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to set preference: $e');
    }
  }

  Future<String?> getPreference(String key) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'user_preferences',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      
      return rows.isEmpty ? null : rows.first['value'] as String;
    } catch (e) {
      throw Exception('Failed to get preference: $e');
    }
  }

  // Analytics and Statistics
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final db = await database;
      
      // Total receipts
      final totalReceipts = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM receipts WHERE isDeleted = 0')
      ) ?? 0;
      
      // Total value
      final totalValueResult = await db.rawQuery('SELECT SUM(price) as total FROM receipts WHERE isDeleted = 0');
      final totalValue = (totalValueResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      // Average receipt value
      final avgValueResult = await db.rawQuery('SELECT AVG(price) as avg FROM receipts WHERE isDeleted = 0');
      final avgValue = (avgValueResult.first['avg'] as num?)?.toDouble() ?? 0.0;
      
      // Expiring warranties (next 30 days)
      final expiringCount = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT COUNT(*) FROM receipts 
          WHERE warrantyEndDate <= ? 
          AND warrantyEndDate > ? 
          AND isDeleted = 0
        ''', [
          DateTime.now().add(Duration(days: 30)).toIso8601String(),
          DateTime.now().toIso8601String(),
        ])
      ) ?? 0;
      
      return {
        'totalReceipts': totalReceipts,
        'totalValue': totalValue,
        'averageValue': avgValue,
        'expiringWarranties': expiringCount,
      };
    } catch (e) {
      throw Exception('Failed to get analytics: $e');
    }
  }

  // Database Management
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('receipts');
      await db.delete('user_preferences');
      // Keep categories as they are default
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }

  Future<void> exportData() async {
    try {
      // This would export all data to a JSON file
      // Implementation depends on your export requirements
      // For now, this is handled by LocalDataService
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Database health check
  Future<bool> isDatabaseHealthy() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      return false;
    }
  }
}
