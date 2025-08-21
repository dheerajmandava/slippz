class Receipt {
  final String productName;
  final DateTime purchaseDate;
  final DateTime warrantyEndDate;
  final String receiptImagePath;
  final String storeName;
  final double price;
  final String category;

  const Receipt({
    required this.productName,
    required this.purchaseDate,
    required this.warrantyEndDate,
    required this.receiptImagePath,
    required this.storeName,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'warrantyEndDate': warrantyEndDate.toIso8601String(),
      'receiptImagePath': receiptImagePath,
      'storeName': storeName,
      'price': price,
      'category': category,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      productName: map['productName'] as String,
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      warrantyEndDate: DateTime.parse(map['warrantyEndDate'] as String),
      receiptImagePath: map['receiptImagePath'] as String,
      storeName: map['storeName'] as String,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String,
    );
  }
}
