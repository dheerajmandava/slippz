import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../models/receipt.dart';

class WarrantyCalendar extends StatefulWidget {
  final List<Receipt> receipts;
  final VoidCallback? onDateTap;

  const WarrantyCalendar({
    super.key,
    required this.receipts,
    this.onDateTap,
  });

  @override
  State<WarrantyCalendar> createState() => _WarrantyCalendarState();
}

class _WarrantyCalendarState extends State<WarrantyCalendar> {
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean header
          _buildHeader(),
          SizedBox(height: 2.h),
          
          // Calendar with proper spacing
          _buildCalendar(),
          SizedBox(height: 1.5.h),
          
          // Status indicators
          _buildStatusIndicators(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Text(
        //   'Warranty Timeline',
        //   style: TextStyle(
        //     fontSize: 18.sp,
        //     fontWeight: FontWeight.w700,
        //     color: const Color(0xFF111827),
        //     fontStyle: FontStyle.italic,
        //   ),
        // ),
        Row(
          children: [
            _buildNavButton(Icons.chevron_left, () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            }),
            SizedBox(width: 2.w),
            Text(
              '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            SizedBox(width: 2.w),
            _buildNavButton(Icons.chevron_right, () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 4.w,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Calculate days to show
    final daysToShow = <DateTime>[];
    
    // Add previous month's trailing days
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final prevMonthLastDay = DateTime(_currentMonth.year, _currentMonth.month, 0).day;
    for (int i = firstDayWeekday - 1; i > 0; i--) {
      daysToShow.add(DateTime(prevMonth.year, prevMonth.month, prevMonthLastDay - i + 1));
    }
    
    // Add current month's days
    for (int day = 1; day <= daysInMonth; day++) {
      daysToShow.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }
    
    // Add next month's leading days
    final remainingDays = 42 - daysToShow.length;
    for (int day = 1; day <= remainingDays; day++) {
      daysToShow.add(DateTime(_currentMonth.year, _currentMonth.month + 1, day));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          // Compact weekday headers
          Container(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          
          // Compact calendar grid
          Padding(
            padding: EdgeInsets.all(1.w),
            child: Column(
              children: List.generate(6, (weekIndex) {
                final weekDays = daysToShow.skip(weekIndex * 7).take(7).toList();
                return Row(
                  children: weekDays.map((date) => _buildDayCell(date)).toList(),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isCurrentMonth = date.month == _currentMonth.month;
    final isToday = _isSameDay(date, DateTime.now());
    final warrantyStatus = _getWarrantyStatusForDate(date);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.onDateTap?.call();
        },
        child: Container(
          height: 5.h,
          margin: EdgeInsets.all(0.2.w),
          decoration: BoxDecoration(
            color: _getDateBackgroundColor(warrantyStatus, isToday),
            borderRadius: BorderRadius.circular(6),
            border: isToday 
                ? Border.all(color: const Color(0xFF10B981), width: 1.5)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    color: _getDateTextColor(warrantyStatus, isCurrentMonth, isToday),
                  ),
                ),
              ),
              if (warrantyStatus != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _getStatusColor(warrantyStatus),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Wrap(
      spacing: 3.w,
      runSpacing: 1.h,
      children: [
        _buildStatusIndicator('Urgent', const Color(0xFFEF4444)),
        _buildStatusIndicator('Expiring', const Color(0xFFF59E0B)),
        _buildStatusIndicator('Active', const Color(0xFF10B981)),
        _buildStatusIndicator('Expired', const Color(0xFF6B7280)),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, Color color) {
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
          label,
          style: TextStyle(
            fontSize: 8.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String? _getWarrantyStatusForDate(DateTime date) {
    final now = DateTime.now();
    
    for (final receipt in widget.receipts) {
      if (receipt.warrantyEndDate == receipt.purchaseDate) continue;
      
      final daysUntilExpiry = receipt.warrantyEndDate.difference(now).inDays;
      final isExpiryDate = _isSameDay(receipt.warrantyEndDate, date);
      
      if (isExpiryDate) {
        if (daysUntilExpiry < 0) {
          return 'expired';
        } else if (daysUntilExpiry <= 7) {
          return 'urgent';
        } else if (daysUntilExpiry <= 30) {
          return 'expiring';
        } else {
          return 'active';
        }
      }
    }
    
    return null;
  }

  Color _getDateBackgroundColor(String? status, bool isToday) {
    if (isToday) {
      return const Color(0xFFF0FDF4);
    }
    if (status == null) {
      return Colors.transparent;
    }
    
    switch (status) {
      case 'urgent':
        return const Color(0xFFFEF2F2);
      case 'expiring':
        return const Color(0xFFFFFBEB);
      case 'expired':
        return const Color(0xFFF9FAFB);
      case 'active':
        return const Color(0xFFF0FDF4);
      default:
        return Colors.transparent;
    }
  }

  Color _getDateTextColor(String? status, bool isCurrentMonth, bool isToday) {
    if (isToday) {
      return const Color(0xFF10B981);
    }
    if (!isCurrentMonth) {
      return const Color(0xFFD1D5DB);
    }
    if (status == null) {
      return const Color(0xFF111827);
    }
    
    switch (status) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'expiring':
        return const Color(0xFFF59E0B);
      case 'expired':
        return const Color(0xFF6B7280);
      case 'active':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF111827);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'expiring':
        return const Color(0xFFF59E0B);
      case 'expired':
        return const Color(0xFF6B7280);
      case 'active':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }
}