# Local Storage Implementation

## Overview
Slippz now uses **100% local storage** for all user data. No data is sent to external servers except for Firebase authentication (Google Sign-in).

## Storage Architecture

### Database
- **SQLite Database**: `slippz_local.db` stored in app documents directory
- **Version**: 2 (with migration support)
- **Tables**:
  - `receipts`: All receipt/warranty data
  - `user_preferences`: App settings and preferences
  - `categories`: Receipt categories with colors and icons

### File Storage
- **Receipt Images**: Stored in `receipts/` subdirectory
- **Exports**: JSON exports saved in `exports/` subdirectory
- **Backups**: Automatic backups in `backups/` subdirectory

## Key Features

### ✅ Complete Local Storage
- All receipt data stored locally on device
- Receipt images saved to device storage
- User preferences stored locally
- No cloud sync (except authentication)

### ✅ Data Management
- **Soft Delete**: Receipts marked as deleted, not permanently removed
- **Search**: Full-text search across product names, stores, categories
- **Filtering**: Filter by category, date range, warranty status
- **Analytics**: Local calculation of spending insights

### ✅ Backup & Export
- **JSON Export**: Export all data to JSON file
- **Automatic Backups**: Create timestamped backups
- **Data Import**: Import previously exported data
- **Storage Info**: View storage usage and file counts

### ✅ Privacy & Security
- **No Cloud Storage**: All data stays on your device
- **Local Authentication**: Uses Firebase only for Google Sign-in
- **Data Control**: Users can export, backup, or clear all data
- **Offline First**: App works completely offline

## Database Schema

### Receipts Table
```sql
CREATE TABLE receipts (
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
```

### User Preferences Table
```sql
CREATE TABLE user_preferences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
```

### Categories Table
```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  color TEXT,
  icon TEXT,
  createdAt TEXT NOT NULL
);
```

## Usage

### Accessing Local Storage Settings
Navigate to: `/local_storage` route or add a settings button in your app.

### Key Methods

```dart
// Initialize local storage
await LocalDataService.instance.initialize();

// Save receipt
await LocalDataService.instance.saveReceipt(receipt);

// Get all receipts
final receipts = await LocalDataService.instance.getAllReceipts();

// Search receipts
final results = await LocalDataService.instance.searchReceipts("iPhone");

// Export data
final exportPath = await LocalDataService.instance.exportDataToJson();

// Create backup
final backupPath = await LocalDataService.instance.createBackup();

// Get storage info
final info = await LocalDataService.instance.getStorageInfo();
```

## Storage Locations

### Android
- Database: `/data/data/com.example.slippz/app_flutter/slippz_local.db`
- Images: `/data/data/com.example.slippz/app_flutter/receipts/`
- Exports: `/data/data/com.example.slippz/app_flutter/exports/`
- Backups: `/data/data/com.example.slippz/app_flutter/backups/`

### iOS
- Database: `~/Documents/slippz_local.db`
- Images: `~/Documents/receipts/`
- Exports: `~/Documents/exports/`
- Backups: `~/Documents/backups/`

## Migration Support

The database includes migration support:
- **Version 1 → 2**: Added timestamps, soft delete, preferences, categories
- Future versions will automatically migrate existing data

## Benefits

1. **Privacy**: No data leaves your device
2. **Performance**: Fast local queries and operations
3. **Offline**: Works without internet connection
4. **Control**: Full control over your data
5. **Backup**: Easy export and backup capabilities
6. **Security**: No risk of data breaches on external servers

## Data Export Format

```json
{
  "exportDate": "2024-01-15T10:30:00.000Z",
  "appVersion": "1.0.0",
  "receipts": [
    {
      "id": 1,
      "productName": "iPhone 15 Pro",
      "purchaseDate": "2024-01-01T00:00:00.000Z",
      "warrantyEndDate": "2025-01-01T00:00:00.000Z",
      "receiptImagePath": "/path/to/image.jpg",
      "storeName": "Apple Store",
      "price": 999.99,
      "category": "Electronics",
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z",
      "isDeleted": 0
    }
  ],
  "categories": [
    {
      "id": 1,
      "name": "Electronics",
      "color": "#3B82F6",
      "icon": "electronics",
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

## Troubleshooting

### Database Issues
- Check if database is healthy: `LocalDataService.instance.isHealthy()`
- Reinitialize if needed: `LocalDataService.instance.initialize()`

### Storage Issues
- Check available space: `LocalDataService.instance.getStorageInfo()`
- Clear old backups if storage is full

### Data Recovery
- Use automatic backups in `backups/` directory
- Import from JSON export files
- Restore from device backup (iOS/Android)

---

**Note**: This implementation ensures complete data privacy and local control while maintaining all functionality of the warranty tracking app.
