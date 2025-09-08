import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../widgets/warranty_summary_card.dart';
import '../widgets/warranty_calendar.dart';
import '../widgets/hand_drawn_button.dart';
import '../receipt_storage.dart';
import '../services/local_data_service.dart';
import '../services/sample_data_service.dart';
import '../models/receipt.dart';

class WarrantyTrackerScreen extends StatefulWidget {
  const WarrantyTrackerScreen({super.key});

  @override
  State<WarrantyTrackerScreen> createState() => _WarrantyTrackerScreenState();
}

class _WarrantyTrackerScreenState extends State<WarrantyTrackerScreen> {
  List<Receipt> _receipts = [];
  bool _isLoading = true;
  double _coveredValue = 0.0;
  double _expiringValue = 0.0;
  double _totalValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Try to load real data first from local storage
      final receipts = await LocalDataService.instance.getAllReceipts();
      
      if (receipts.isEmpty) {
        // Use sample data if no real data exists
        _receipts = SampleDataService.getSampleReceipts();
      } else {
        _receipts = receipts;
      }
      
      _calculateWarrantyValues();
      setState(() => _isLoading = false);
    } catch (e) {
      // Fallback to sample data on error
      _receipts = SampleDataService.getSampleReceipts();
      _calculateWarrantyValues();
      setState(() => _isLoading = false);
    }
  }

  void _calculateWarrantyValues() {
    final now = DateTime.now();
    double covered = 0.0;
    double expiring = 0.0;
    double total = 0.0;

    for (final receipt in _receipts) {
      total += receipt.price;
      final daysUntilExpiry = receipt.warrantyEndDate.difference(now).inDays;
      
      if (daysUntilExpiry > 30) {
        covered += receipt.price;
      } else if (daysUntilExpiry > 0) {
        expiring += receipt.price;
      }
    }

    setState(() {
      _coveredValue = covered;
      _expiringValue = expiring;
      _totalValue = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Slippz',
          style: GoogleFonts.timmana(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/local_storage');
            },
            icon: Icon(
              Icons.settings,
              color: const Color(0xFF6B7280),
              size: 5.w,
            ),
            tooltip: 'Local Storage Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('FAB pressed - navigating to receipt storage');
          try {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReceiptStorage()),
            );
          } catch (e) {
            print('Navigation error: $e');
          }
        },
        backgroundColor: const Color.fromARGB(255, 48, 47, 47),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
       
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4.h),
                          
                          // Warranty Summary Card (Hand-drawn Donut Chart)
                          WarrantySummaryCard(
                            coveredValue: _coveredValue,
                            expiringValue: _expiringValue,
                            totalValue: _totalValue,
                          ),
                          
                          SizedBox(height: 4.h),
                          
                          // Top Row: Status + View All
                          _buildTopRow(),
                          
                          SizedBox(height: 4.h),
                          
                          // Warranty Calendar
                          WarrantyCalendar(
                            receipts: _receipts,
                            onDateTap: () {
                              // Navigate to warranty list when date is tapped
                              Navigator.pushNamed(context, '/receipt_list');
                            },
                          ),
                          // Latest Slips Section
                          // LatestSlipsSection(
                          //   receipts: _receipts,
                          //   onViewAll: () {
                          //     Navigator.pushNamed(context, '/receipt_list');
                          //   },
                          // ),
                          
                          SizedBox(height: 12.h), // Extra space for FAB overlap
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    final now = DateTime.now();
    final urgentCount = _receipts.where((r) {
      if (r.warrantyEndDate == r.purchaseDate) return false;
      final days = r.warrantyEndDate.difference(now).inDays;
      return days <= 7 && days > 0;
    }).length;

    final expiringCount = _receipts.where((r) {
      if (r.warrantyEndDate == r.purchaseDate) return false;
      final days = r.warrantyEndDate.difference(now).inDays;
      return days <= 30 && days > 7;
    }).length;

    final coveredCount = _receipts.where((r) {
      if (r.warrantyEndDate == r.purchaseDate) return false;
      final days = r.warrantyEndDate.difference(now).inDays;
      return days > 30;
    }).length;

    final total = urgentCount + expiringCount + coveredCount;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: Status summary (compact)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      if (urgentCount > 0)
                        Expanded(
                          flex: urgentCount,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      if (expiringCount > 0)
                        Expanded(
                          flex: expiringCount,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      if (coveredCount > 0)
                        Expanded(
                          flex: coveredCount,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 1.h),
                // Status text
                Text(
                  total == 0 ? 'No warranties' : '$total warranties',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 3.w),
          
          // Right: View All button (prominent)
          Expanded(
            flex: 1,
            child: HandDrawnButton(
              text: 'View All',
              icon: Icons.arrow_forward_ios,
              backgroundColor: const Color.fromARGB(255, 48, 47, 47),
              textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/receipt_list'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: const Color(0xFF10B981),
            strokeWidth: 3,
          ),
          SizedBox(height: 4.h),
          Text(
            'Loading your warranties...',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
