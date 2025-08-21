import '../models/receipt.dart';

class AnalyticsService {
  static Map<String, double> getCategorySpending(List<Receipt> receipts) {
    final Map<String, double> categorySpending = {};
    
    for (final receipt in receipts) {
      categorySpending[receipt.category] = 
          (categorySpending[receipt.category] ?? 0) + receipt.price;
    }
    
    return categorySpending;
  }

  static Map<String, double> getMonthlySpending(List<Receipt> receipts) {
    final Map<String, double> monthlySpending = {};
    
    for (final receipt in receipts) {
      final monthKey = '${receipt.purchaseDate.year}-${receipt.purchaseDate.month.toString().padLeft(2, '0')}';
      monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + receipt.price;
    }
    
    return monthlySpending;
  }

  static Map<String, int> getStoreFrequency(List<Receipt> receipts) {
    final Map<String, int> storeFrequency = {};
    
    for (final receipt in receipts) {
      storeFrequency[receipt.storeName] = (storeFrequency[receipt.storeName] ?? 0) + 1;
    }
    
    return storeFrequency;
  }

  static List<Receipt> getExpiringWarranties(List<Receipt> receipts, {int daysThreshold = 30}) {
    final now = DateTime.now();
    return receipts.where((receipt) {
      final daysUntilExpiry = receipt.warrantyEndDate.difference(now).inDays;
      return daysUntilExpiry <= daysThreshold && daysUntilExpiry > 0;
    }).toList();
  }

  static double getAverageReceiptValue(List<Receipt> receipts) {
    if (receipts.isEmpty) return 0.0;
    final total = receipts.fold(0.0, (sum, receipt) => sum + receipt.price);
    return total / receipts.length;
  }

  static Map<String, dynamic> getSpendingInsights(List<Receipt> receipts) {
    if (receipts.isEmpty) {
      return {
        'totalSpent': 0.0,
        'averageReceipt': 0.0,
        'totalReceipts': 0,
        'expiringWarranties': 0,
        'topCategory': '',
        'topStore': '',
        'monthlyAverage': 0.0,
      };
    }

    final categorySpending = getCategorySpending(receipts);
    final storeFrequency = getStoreFrequency(receipts);
    final expiringWarranties = getExpiringWarranties(receipts);
    
    final topCategory = categorySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final topStore = storeFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final totalSpent = receipts.fold(0.0, (sum, receipt) => sum + receipt.price);
    final averageReceipt = totalSpent / receipts.length;

    // Calculate monthly average
    final monthlySpending = getMonthlySpending(receipts);
    final monthlyAverage = monthlySpending.values.isNotEmpty 
        ? monthlySpending.values.reduce((a, b) => a + b) / monthlySpending.length 
        : 0.0;

    return {
      'totalSpent': totalSpent,
      'averageReceipt': averageReceipt,
      'totalReceipts': receipts.length,
      'expiringWarranties': expiringWarranties.length,
      'topCategory': topCategory,
      'topStore': topStore,
      'monthlyAverage': monthlyAverage,
    };
  }

  static List<Map<String, dynamic>> getSpendingTrends(List<Receipt> receipts) {
    final monthlySpending = getMonthlySpending(receipts);
    final sortedMonths = monthlySpending.keys.toList()..sort();
    
    return sortedMonths.map((month) {
      return {
        'month': month,
        'amount': monthlySpending[month]!,
      };
    }).toList();
  }

  static Map<String, double> getCategoryPercentages(List<Receipt> receipts) {
    final categorySpending = getCategorySpending(receipts);
    final totalSpent = categorySpending.values.fold(0.0, (sum, amount) => sum + amount);
    
    if (totalSpent == 0) return {};
    
    return categorySpending.map((category, amount) {
      return MapEntry(category, (amount / totalSpent) * 100);
    });
  }
}
