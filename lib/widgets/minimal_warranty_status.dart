import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../models/receipt.dart';

class MinimalWarrantyStatus extends StatelessWidget {
  final List<Receipt> receipts;
  final VoidCallback? onViewAll;

  const MinimalWarrantyStatus({
    super.key,
    required this.receipts,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final urgentCount = receipts.where((r) {
      if (r.warrantyEndDate == r.purchaseDate) return false;
      final days = r.warrantyEndDate.difference(now).inDays;
      return days <= 7 && days > 0;
    }).length;

    final expiringCount = receipts.where((r) {
      if (r.warrantyEndDate == r.purchaseDate) return false;
      final days = r.warrantyEndDate.difference(now).inDays;
      return days <= 30 && days > 7;
    }).length;

    final coveredCount = receipts.where((r) {
      if (r.warrantyEndDate == r.purchaseDate) return false;
      final days = r.warrantyEndDate.difference(now).inDays;
      return days > 30;
    }).length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          // Simple status line
          _buildStatusLine(urgentCount, expiringCount, coveredCount),
          
          SizedBox(height: 1.h),
          
          // Minimal status text
          _buildStatusText(urgentCount, expiringCount, coveredCount),
        ],
      ),
    );
  }

  Widget _buildStatusLine(int urgent, int expiring, int covered) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          if (urgent > 0)
            Expanded(
              flex: urgent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (expiring > 0)
            Expanded(
              flex: expiring,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (covered > 0)
            Expanded(
              flex: covered,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText(int urgent, int expiring, int covered) {
    final total = urgent + expiring + covered;
    
    return GestureDetector(
      onTap: onViewAll,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Status summary - flexible
            Expanded(
              child: Wrap(
                spacing: 2.w,
                runSpacing: 0.5.h,
                children: [
                  if (urgent > 0) ...[
                    _buildStatusItem('$urgent urgent', const Color(0xFFEF4444)),
                  ],
                  if (expiring > 0) ...[
                    _buildStatusItem('$expiring expiring', const Color(0xFFF59E0B)),
                  ],
                  if (covered > 0) ...[
                    _buildStatusItem('$covered covered', const Color(0xFF10B981)),
                  ],
                  if (total == 0) ...[
                    Text(
                      'No warranties',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Click indicator - fixed width
            Container(
              margin: EdgeInsets.only(left: 2.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all $total',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 8.sp,
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
