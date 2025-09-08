import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../services/settings_service.dart';

class WarrantyAlertsDashboard extends StatefulWidget {
  final List<Receipt> receipts;
  final VoidCallback? onViewAll;

  const WarrantyAlertsDashboard({
    super.key,
    required this.receipts,
    this.onViewAll,
  });

  @override
  State<WarrantyAlertsDashboard> createState() => _WarrantyAlertsDashboardState();
}

class _WarrantyAlertsDashboardState extends State<WarrantyAlertsDashboard> {
  int _expiringThreshold = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final threshold = await SettingsService.getExpiringThreshold();
    setState(() {
      _expiringThreshold = threshold;
    });
  }

  List<Receipt> _getUrgentItems() {
    final now = DateTime.now();
    return widget.receipts.where((receipt) {
      if (receipt.warrantyEndDate == receipt.purchaseDate) return false;
      final daysUntilExpiry = receipt.warrantyEndDate.difference(now).inDays;
      return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
    }).toList();
  }

  List<Receipt> _getWarningItems() {
    final now = DateTime.now();
    return widget.receipts.where((receipt) {
      if (receipt.warrantyEndDate == receipt.purchaseDate) return false;
      final daysUntilExpiry = receipt.warrantyEndDate.difference(now).inDays;
      return daysUntilExpiry <= _expiringThreshold && daysUntilExpiry > 7;
    }).toList();
  }

  List<Receipt> _getCoveredItems() {
    final now = DateTime.now();
    return widget.receipts.where((receipt) {
      if (receipt.warrantyEndDate == receipt.purchaseDate) return false;
      final daysUntilExpiry = receipt.warrantyEndDate.difference(now).inDays;
      return daysUntilExpiry > _expiringThreshold;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final urgentItems = _getUrgentItems();
    final warningItems = _getWarningItems();
    final coveredItems = _getCoveredItems();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Warranty Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (widget.onViewAll != null)
                GestureDetector(
                  onTap: widget.onViewAll,
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Urgent Items (Next 7 days)
          if (urgentItems.isNotEmpty) ...[
            _buildSectionHeader('🔴 URGENT', 'Next 7 days', const Color(0xFFEF4444)),
            const SizedBox(height: 8),
            ...urgentItems.take(3).map((receipt) => _buildAlertCard(receipt, 'urgent')),
            const SizedBox(height: 16),
          ],

          // Warning Items (Next 30 days)
          if (warningItems.isNotEmpty) ...[
            _buildSectionHeader('⚠️ WARNING', 'Next $_expiringThreshold days', const Color(0xFFF59E0B)),
            const SizedBox(height: 8),
            ...warningItems.take(3).map((receipt) => _buildAlertCard(receipt, 'warning')),
            const SizedBox(height: 16),
          ],

          // All Good Section
          if (urgentItems.isEmpty && warningItems.isEmpty) ...[
            _buildSectionHeader('✅ All Good', '${coveredItems.length} items fully covered', const Color(0xFF10B981)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No warranties expiring soon! All your items are fully covered.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Empty State
          if (widget.receipts.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No warranties yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first receipt to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Receipt receipt, String type) {
    final daysUntilExpiry = receipt.warrantyEndDate.difference(DateTime.now()).inDays;
    final isUrgent = type == 'urgent';
    
    Color cardColor;
    Color textColor;
    String actionText;
    
    if (isUrgent) {
      cardColor = const Color(0xFFFFF1F2);
      textColor = const Color(0xFFDC2626);
      actionText = 'Take Action';
    } else {
      cardColor = const Color(0xFFFFFBEB);
      textColor = const Color(0xFFD97706);
      actionText = 'View Details';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMerchantIcon(receipt.storeName),
              color: textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  receipt.storeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${receipt.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          // Days left and action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${daysUntilExpiry}d left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showActionDialog(receipt, isUrgent),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
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

  void _showActionDialog(Receipt receipt, bool isUrgent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUrgent ? 'Urgent Action Needed' : 'Warranty Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${receipt.productName} from ${receipt.storeName}'),
            const SizedBox(height: 8),
            Text('Price: \$${receipt.price.toStringAsFixed(2)}'),
            Text('Warranty expires: ${receipt.warrantyEndDate.toLocal().toString().split(' ')[0]}'),
            const SizedBox(height: 16),
            if (isUrgent) ...[
              const Text('Recommended actions:', style: TextStyle(fontWeight: FontWeight.w600)),
              const Text('• Contact store for warranty service'),
              const Text('• Get repairs or replacement'),
              const Text('• Extend warranty if possible'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
