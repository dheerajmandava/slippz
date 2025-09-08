import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sizer/sizer.dart';
import '../models/receipt.dart';
import '../services/settings_service.dart';

class WarrantyCard extends StatefulWidget {
  final Receipt receipt;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WarrantyCard({
    super.key,
    required this.receipt,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<WarrantyCard> createState() => _WarrantyCardState();
}

class _WarrantyCardState extends State<WarrantyCard> {
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysUntilExpiry = widget.receipt.warrantyEndDate.difference(now).inDays;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Product Image/Icon
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF3F4F6),
                  ),
                  child: widget.receipt.receiptImagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(widget.receipt.receiptImagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.receipt,
                                color: const Color(0xFF6B7280),
                                size: 5.w,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.receipt,
                          color: const Color(0xFF6B7280),
                          size: 5.w,
                        ),
                ),
                SizedBox(width: 3.w),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receipt.productName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.receipt.storeName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status Badge
                _buildStatusBadge(daysUntilExpiry),
              ],
            ),
            SizedBox(height: 4.h),
            
            // Details Row
            Row(
              children: [
                // Price
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${widget.receipt.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                // Category
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.receipt.category,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const Spacer(),
                // Days remaining
                Text(
                  _getDaysText(daysUntilExpiry),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(daysUntilExpiry),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            
            // Progress Bar
            _buildProgressBar(daysUntilExpiry),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int daysUntilExpiry) {
    final status = _getStatusInfo(daysUntilExpiry);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: status['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status['color'].withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status['icon'],
            size: 3.w,
            color: status['color'],
          ),
          SizedBox(width: 1.w),
          Text(
            status['text'],
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: status['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) {
      // Expired - show red bar
      return Container(
        height: 1.h,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    // Calculate progress based on warranty duration
    final totalWarrantyDays = widget.receipt.warrantyEndDate
        .difference(widget.receipt.purchaseDate)
        .inDays;
    final remainingDays = daysUntilExpiry;
    final progress = remainingDays / totalWarrantyDays;
    
    return Container(
      height: 1.h,
      decoration: BoxDecoration(
        color: _getStatusColor(daysUntilExpiry).withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: _getStatusColor(daysUntilExpiry),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) {
      return {
        'text': 'Expired',
        'color': const Color(0xFF6B7280),
        'icon': Icons.cancel,
      };
    } else if (daysUntilExpiry <= 7) {
      return {
        'text': 'Urgent',
        'color': const Color(0xFFEF4444),
        'icon': Icons.warning,
      };
    } else if (daysUntilExpiry <= _expiringThreshold) {
      return {
        'text': 'Expiring',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.schedule,
      };
    } else {
      return {
        'text': 'Covered',
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle,
      };
    }
  }

  Color _getStatusColor(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) return const Color(0xFF6B7280);
    if (daysUntilExpiry <= 7) return const Color(0xFFEF4444);
    if (daysUntilExpiry <= _expiringThreshold) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _getDaysText(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) return 'Expired';
    if (daysUntilExpiry == 1) return '1 day left';
    if (daysUntilExpiry <= 7) return '$daysUntilExpiry days left';
    if (daysUntilExpiry <= _expiringThreshold) return '$daysUntilExpiry days left';
    return '$daysUntilExpiry days left';
  }
}
