import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'database_service.dart';
import '../models/receipt.dart';

/// Service to manage all local data operations
/// Ensures all user data is stored locally on the device
class LocalDataService {
  static LocalDataService? _instance;
  static LocalDataService get instance => _instance ??= LocalDataService._();
  
  LocalDataService._();

  final DatabaseService _databaseService = DatabaseService();

  /// Initialize local data service
  Future<void> initialize() async {
    try {
      // Ensure database is healthy
      final isHealthy = await _databaseService.isDatabaseHealthy();
      if (!isHealthy) {
        throw Exception('Database is not healthy');
      }
      
      // Create necessary directories
      await _createDirectories();
      
      print('LocalDataService initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize LocalDataService: $e');
    }
  }

  /// Create necessary directories for local storage
  Future<void> _createDirectories() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(path.join(appDir.path, 'receipts'));
      final exportsDir = Directory(path.join(appDir.path, 'exports'));
      final backupsDir = Directory(path.join(appDir.path, 'backups'));

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }
      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to create directories: $e');
    }
  }

  // Receipt Management
  Future<void> saveReceipt(Receipt receipt) async {
    try {
      await _databaseService.insertReceipt(receipt);
      
      // Save receipt image locally if path is provided
      if (receipt.receiptImagePath.isNotEmpty) {
        await _saveReceiptImage(receipt);
      }
    } catch (e) {
      throw Exception('Failed to save receipt: $e');
    }
  }

  Future<List<Receipt>> getAllReceipts() async {
    try {
      return await _databaseService.getAllReceipts();
    } catch (e) {
      throw Exception('Failed to get receipts: $e');
    }
  }

  Future<Receipt?> getReceiptById(int id) async {
    try {
      return await _databaseService.getReceiptById(id);
    } catch (e) {
      throw Exception('Failed to get receipt: $e');
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    try {
      await _databaseService.updateReceipt(receipt);
      
      // Update receipt image if needed
      if (receipt.receiptImagePath.isNotEmpty) {
        await _saveReceiptImage(receipt);
      }
    } catch (e) {
      throw Exception('Failed to update receipt: $e');
    }
  }

  Future<void> deleteReceipt(int id, {bool permanent = false}) async {
    try {
      if (permanent) {
        // Get receipt to delete associated image
        final receipt = await _databaseService.getReceiptById(id);
        if (receipt != null) {
          await _deleteReceiptImage(receipt);
        }
      }
      
      await _databaseService.deleteReceipt(id, permanent: permanent);
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  // Search and Filter
  Future<List<Receipt>> searchReceipts(String query) async {
    try {
      return await _databaseService.searchReceipts(query);
    } catch (e) {
      throw Exception('Failed to search receipts: $e');
    }
  }

  Future<List<Receipt>> getReceiptsByCategory(String category) async {
    try {
      return await _databaseService.getReceiptsByCategory(category);
    } catch (e) {
      throw Exception('Failed to get receipts by category: $e');
    }
  }

  Future<List<Receipt>> getExpiringWarranties({int daysAhead = 30}) async {
    try {
      return await _databaseService.getExpiringWarranties(daysAhead: daysAhead);
    } catch (e) {
      throw Exception('Failed to get expiring warranties: $e');
    }
  }

  // Image Management
  Future<String> _saveReceiptImage(Receipt receipt) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(path.join(appDir.path, 'receipts'));
      
      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(receipt.receiptImagePath);
      final filename = 'receipt_${receipt.id ?? timestamp}$extension';
      final newPath = path.join(receiptsDir.path, filename);
      
      // Copy image to local storage
      final sourceFile = File(receipt.receiptImagePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(newPath);
        return newPath;
      }
      
      return receipt.receiptImagePath;
    } catch (e) {
      throw Exception('Failed to save receipt image: $e');
    }
  }

  Future<void> _deleteReceiptImage(Receipt receipt) async {
    try {
      final file = File(receipt.receiptImagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Don't throw error for image deletion failure
      print('Failed to delete receipt image: $e');
    }
  }

  // Category Management
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      return await _databaseService.getAllCategories();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<void> addCategory(String name, {String? color, String? icon}) async {
    try {
      await _databaseService.addCategory(name, color: color, icon: icon);
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // User Preferences
  Future<void> setPreference(String key, String value) async {
    try {
      await _databaseService.setPreference(key, value);
    } catch (e) {
      throw Exception('Failed to set preference: $e');
    }
  }

  Future<String?> getPreference(String key) async {
    try {
      return await _databaseService.getPreference(key);
    } catch (e) {
      throw Exception('Failed to get preference: $e');
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      return await _databaseService.getAnalytics();
    } catch (e) {
      throw Exception('Failed to get analytics: $e');
    }
  }

  // Data Export/Import
  Future<String> exportDataToJson() async {
    try {
      final receipts = await _databaseService.getAllReceipts(includeDeleted: true);
      final categories = await _databaseService.getAllCategories();
      
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'receipts': receipts.map((r) => r.toMap()).toList(),
        'categories': categories,
      };
      
      final jsonString = jsonEncode(exportData);
      
      // Save to exports directory
      final appDir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory(path.join(appDir.path, 'exports'));
      final filename = 'slippz_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(path.join(exportsDir.path, filename));
      
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<void> importDataFromJson(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Import file does not exist');
      }
      
      final jsonString = await file.readAsString();
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate import data
      if (!importData.containsKey('receipts')) {
        throw Exception('Invalid import file format');
      }
      
      // Import receipts
      final receiptsData = importData['receipts'] as List<dynamic>;
      for (final receiptData in receiptsData) {
        final receipt = Receipt.fromMap(receiptData as Map<String, dynamic>);
        await _databaseService.insertReceipt(receipt);
      }
      
      // Import categories if available
      if (importData.containsKey('categories')) {
        final categoriesData = importData['categories'] as List<dynamic>;
        for (final categoryData in categoriesData) {
          final category = categoryData as Map<String, dynamic>;
          await _databaseService.addCategory(
            category['name'] as String,
            color: category['color'] as String?,
            icon: category['icon'] as String?,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  // Backup and Restore
  Future<String> createBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory(path.join(appDir.path, 'backups'));
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = path.join(backupsDir.path, 'backup_$timestamp.json');
      
      // Export data to backup file
      final exportPath = await exportDataToJson();
      final exportFile = File(exportPath);
      final backupFile = File(backupPath);
      
      await exportFile.copy(backupFile.path);
      
      return backupFile.path;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  Future<List<String>> getAvailableBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory(path.join(appDir.path, 'backups'));
      
      if (!await backupsDir.exists()) {
        return [];
      }
      
      final files = await backupsDir.list().toList();
      return files
          .where((file) => file is File && file.path.endsWith('.json'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      throw Exception('Failed to get backups: $e');
    }
  }

  // Data Management
  Future<void> clearAllData() async {
    try {
      // Clear database
      await _databaseService.clearAllData();
      
      // Clear local images
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(path.join(appDir.path, 'receipts'));
      
      if (await receiptsDir.exists()) {
        await receiptsDir.delete(recursive: true);
        await receiptsDir.create();
      }
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(path.join(appDir.path, 'receipts'));
      final exportsDir = Directory(path.join(appDir.path, 'exports'));
      final backupsDir = Directory(path.join(appDir.path, 'backups'));
      
      int totalFiles = 0;
      int totalSize = 0;
      
      // Calculate receipts directory size
      if (await receiptsDir.exists()) {
        final files = await receiptsDir.list().toList();
        for (final file in files) {
          if (file is File) {
            totalFiles++;
            totalSize += await file.length();
          }
        }
      }
      
      // Calculate exports directory size
      if (await exportsDir.exists()) {
        final files = await exportsDir.list().toList();
        for (final file in files) {
          if (file is File) {
            totalFiles++;
            totalSize += await file.length();
          }
        }
      }
      
      // Calculate backups directory size
      if (await backupsDir.exists()) {
        final files = await backupsDir.list().toList();
        for (final file in files) {
          if (file is File) {
            totalFiles++;
            totalSize += await file.length();
          }
        }
      }
      
      return {
        'totalFiles': totalFiles,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'databasePath': path.join(appDir.path, 'slippz_local.db'),
        'receiptsPath': receiptsDir.path,
        'exportsPath': exportsDir.path,
        'backupsPath': backupsDir.path,
      };
    } catch (e) {
      throw Exception('Failed to get storage info: $e');
    }
  }

  // Health Check
  Future<bool> isHealthy() async {
    try {
      return await _databaseService.isDatabaseHealthy();
    } catch (e) {
      return false;
    }
  }

  // Cleanup
  Future<void> cleanup() async {
    try {
      await _databaseService.closeDatabase();
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}
