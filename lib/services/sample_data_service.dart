import '../models/receipt.dart';

class SampleDataService {
  static List<Receipt> getSampleReceipts() {
    final now = DateTime.now();
    
    return [
      Receipt(
        productName: 'MacBook Pro M3',
        purchaseDate: DateTime(now.year, now.month, 15),
        warrantyEndDate: DateTime(now.year + 2, now.month, 15),
        receiptImagePath: 'lib/assets/images/1.png',
        storeName: 'Best Buy',
        price: 2499.00,
        category: 'Electronics',
      ),
      Receipt(
        productName: 'Groceries',
        purchaseDate: DateTime(now.year, now.month, 14),
        warrantyEndDate: DateTime(now.year, now.month, 14), // No warranty
        receiptImagePath: 'lib/assets/images/2.png',
        storeName: 'Whole Foods',
        price: 84.32,
        category: 'Food',
      ),
      Receipt(
        productName: 'Model 3 Service',
        purchaseDate: DateTime(now.year, now.month, 12),
        warrantyEndDate: DateTime(now.year, now.month + 6, 12),
        receiptImagePath: 'lib/assets/images/1.png',
        storeName: 'Tesla Service',
        price: 450.00,
        category: 'Automotive',
      ),
    ];
  }
}
