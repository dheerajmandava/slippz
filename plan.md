# Project Plan for Warranty Receipts Mobile App

## Objective
Develop a mobile application using Flutter that allows users to store and manage warranty receipts. The app will remind users when warranties are nearing their end date.

## Features
1. **Receipt Storage**: Users can add, view, and delete warranty receipts.
2. **Reminder System**: Set reminders for nearing end dates of warranties.
3. **Search and Filter**: Users can search and filter receipts based on various criteria.
4. **User Authentication**: Secure user data with login functionality.

## Development Milestones
1. **Setup Project Structure**: Organize files and directories.
2. **Implement Receipt Storage**: Allow users to add and manage receipts.
3. **Develop Reminder System**: Implement functionality to remind users.
4. **Add Search and Filter**: Enable searching and filtering of receipts.
5. **User Authentication**: Integrate login system.

## Current Status
- ✅ **Project Structure**: Basic Flutter app structure is in place
- ✅ **Receipt Storage Foundation**: Created receipt_storage.dart with basic scaffold
- ✅ **Navigation**: Updated main.dart to include routing to the receipt storage feature

## Revised Detailed Plan for Next Phase

### Immediate Next Steps (Priority Order):

#### 1. Complete Receipt Storage Implementation
- **Receipt Model Class**: Create with fields:
  - product name
  - purchase date
  - warranty end date
  - receipt image
  - store name
  - price
  - category
- **Local Storage**: Implement using SQLite or Hive
- **Add Receipt UI**: Form with date pickers and image upload
- **List View**: Display all receipts with thumbnails
- **Delete Functionality**: Swipe-to-delete or delete button
- **Edit Functionality**: Update existing receipts

#### 2. Reminder System Foundation
- **Notification Service**: Using flutter_local_notifications
- **Background Tasks**: Check warranty expiry daily
- **Reminder Settings**: Allow users to set reminder timing (30/15/7 days before expiry)
- **Notification UI**: Display upcoming expirations

#### 3. Enhanced Features
- **Search Functionality**: By product name, store, or category
- **Filter Options**: 
  - By warranty status (active/expiring/expired)
  - By category
  - By date range
- **Receipt Image Capture**: Camera/gallery integration
- **Receipt Scanner**: OCR for automatic data extraction (future enhancement)

### Technical Architecture:
- **State Management**: Provider pattern for simplicity
- **Storage**: 
  - SQLite for structured data
  - File system for receipt images
- **Notifications**: flutter_local_notifications package
- **Image Handling**: 
  - image_picker for capture
  - path_provider for storage
  - image_cropper for optimization

### Package Dependencies:
```yaml
dependencies:
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  image_picker: ^1.0.4
  flutter_local_notifications: ^16.1.0
  provider: ^6.0.5
  intl: ^0.18.1
```

### Development Timeline:
- **Week 1**: Complete receipt storage (CRUD operations)
- **Week 2**: Implement reminder system
- **Week 3**: Add search/filter features
- **Week 4**: Polish UI and add user authentication

### File Structure:
```
lib/
├── models/
│   └── receipt.dart
├── providers/
│   └── receipt_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── add_receipt_screen.dart
│   └── receipt_detail_screen.dart
├── services/
│   ├── database_service.dart
│   └── notification_service.dart
├── widgets/
│   └── receipt_card.dart
└── main.dart
```

### Testing Strategy:
- Unit tests for data models
- Widget tests for UI components
- Integration tests for database operations

## Current Tasks
- [ ] Create receipt model class
- [ ] Set up SQLite database
- [ ] Implement add receipt screen
- [ ] Create receipt list view
- [ ] Add delete functionality
