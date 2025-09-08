import 'package:flutter/material.dart';
import '../models/receipt.dart';
import 'slip_card.dart';

class LatestSlipsSection extends StatelessWidget {
  final List<Receipt> receipts;
  final VoidCallback? onViewAll;

  const LatestSlipsSection({
    super.key,
    required this.receipts,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
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
                'Latest Slips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
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
          // Slips List
          if (receipts.isEmpty)
           Center(child: _buildEmptyState(),)
          else
            ...receipts.take(3).map((receipt) => _buildSlipCard(receipt)),
        ],
      ),
    );
  }

  Widget _buildSlipCard(Receipt receipt) {
    final daysUntilExpiry = receipt.warrantyEndDate.difference(DateTime.now()).inDays;
    String warrantyStatus = '';
    String aiInsight = '';

    // Determine warranty status based on real data
    if (receipt.warrantyEndDate == receipt.purchaseDate) {
      // No warranty
      warrantyStatus = '';
    } else if (daysUntilExpiry > 365) {
      warrantyStatus = '${(daysUntilExpiry / 365).floor()}y left';
    } else if (daysUntilExpiry > 30) {
      warrantyStatus = '${(daysUntilExpiry / 30).floor()}m left';
    } else if (daysUntilExpiry > 0) {
      warrantyStatus = '${daysUntilExpiry}d left';
    } else {
      warrantyStatus = 'Expired';
    }

    // Determine AI insight based on real category and store data
    if (receipt.category.toLowerCase().contains('electronics')) {
      aiInsight = 'Categorized: Electronics';
    } else if (receipt.storeName.toLowerCase().contains('whole foods') || 
               receipt.storeName.toLowerCase().contains('grocery')) {
      aiInsight = 'Tagged: Tax Deductible';
    } else if (receipt.storeName.toLowerCase().contains('tesla') || 
               receipt.storeName.toLowerCase().contains('auto')) {
      aiInsight = 'Reminder: Next service due';
    } else if (receipt.category.toLowerCase().contains('food')) {
      aiInsight = 'Tagged: Tax Deductible';
    } else {
      aiInsight = 'Categorized: ${receipt.category}';
    }

    return SlipCard(
      receipt: receipt,
      aiInsight: aiInsight,
      warrantyStatus: warrantyStatus,
    );
  }

  Widget _buildEmptyState() {
    return Container(
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
            'No slips yet',
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
    );
  }
}
