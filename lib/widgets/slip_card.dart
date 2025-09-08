import 'package:flutter/material.dart';
import '../models/receipt.dart';

class SlipCard extends StatelessWidget {
  final Receipt receipt;
  final String aiInsight;
  final String warrantyStatus;

  const SlipCard({
    super.key,
    required this.receipt,
    required this.aiInsight,
    required this.warrantyStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Merchant Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMerchantIcon(receipt.storeName),
              color: const Color(0xFF6B7280),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merchant and Product
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: receipt.storeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const TextSpan(
                        text: ' • ',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: receipt.productName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Price
                Text(
                  '\$${receipt.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                // AI Insight
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'AI $aiInsight',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Date and Warranty Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(receipt.purchaseDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (warrantyStatus.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      warrantyStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getMerchantIcon(String storeName) {
    final name = storeName.toLowerCase();
    if (name.contains('best buy') || name.contains('electronics')) {
      return Icons.laptop;
    } else if (name.contains('whole foods') || name.contains('grocery')) {
      return Icons.restaurant;
    } else if (name.contains('tesla') || name.contains('auto')) {
      return Icons.directions_car;
    } else if (name.contains('amazon') || name.contains('online')) {
      return Icons.shopping_cart;
    } else {
      return Icons.store;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
