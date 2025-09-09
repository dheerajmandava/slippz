import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../models/receipt.dart';
import '../widgets/currency_text.dart';

class MinimalSlipItem extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback? onTap;

  const MinimalSlipItem({
    super.key,
    required this.receipt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysUntilExpiry = receipt.warrantyEndDate.difference(now).inDays;
    
    String daysLeft = '';
    Color daysColor = const Color(0xFF6B7280);
    
    if (receipt.warrantyEndDate == receipt.purchaseDate) {
      daysLeft = 'no warranty';
    } else if (daysUntilExpiry <= 0) {
      daysLeft = 'expired';
      daysColor = const Color(0xFF6B7280);
    } else if (daysUntilExpiry <= 7) {
      daysLeft = '${daysUntilExpiry}d left';
      daysColor = const Color(0xFFEF4444);
    } else if (daysUntilExpiry <= 30) {
      daysLeft = '${daysUntilExpiry}d left';
      daysColor = const Color(0xFFF59E0B);
    } else if (daysUntilExpiry <= 365) {
      daysLeft = '${(daysUntilExpiry / 30).floor()}m left';
      daysColor = const Color(0xFF10B981);
    } else {
      daysLeft = '${(daysUntilExpiry / 365).floor()}y left';
      daysColor = const Color(0xFF10B981);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Row(
          children: [
            // Product name
            Expanded(
              flex: 3,
              child: Text(
                receipt.productName,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            SizedBox(width: 2.w),
            
            // Category tag
            Expanded(
              flex: 2,
              child: Text(
                receipt.category,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            SizedBox(width: 2.w),
            
            // Price
            CurrencyText(
              amount: receipt.price,
              noDecimals: true,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            
            SizedBox(width: 2.w),
            
            // Days left
            Text(
              daysLeft,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: daysColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
