import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:slips_warranty_tracker/services/currency_service.dart';
import '../widgets/warranty_summary_card.dart';
import '../widgets/warranty_calendar.dart';
import '../widgets/hand_drawn_button.dart';
import '../receipt_storage.dart';
import '../services/local_data_service.dart';
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
  var coveredVal;
  var expiringVal;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load real data from local storage
      final receipts = await LocalDataService.instance.getAllReceipts();
      _receipts = receipts;
      _calculateWarrantyValues();
      setState(() => _isLoading = false);
    } catch (e) {
      // Handle error gracefully
      _receipts = [];
      _calculateWarrantyValues();
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _calculateWarrantyValues() async {
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
  coveredVal = await CurrencyService.formatAmountNoDecimals(covered);
      expiringVal = await CurrencyService.formatAmountNoDecimals(expiring);
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
        shadowColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
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
          // IconButton(
          //   onPressed: _loadData,
          //   icon: Icon(
          //     Icons.refresh,
          //     color: const Color(0xFF6B7280),
          //     size: 5.w,
          //   ),
          //   tooltip: 'Refresh Data',
          // ),
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
          try {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReceiptStorage()),
            );
          } catch (e) {
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
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFF10B981),
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                          Center(child: WarrantySummaryCard(
                            coveredValue: _coveredValue,
                            expiringValue: _expiringValue,
                            totalValue: _totalValue,
                            coveredVal:coveredVal,
                            expiringVal:expiringVal
                          ),),
                
                          SizedBox(height: 10.h),
                          _buildTopRow(),
                          
                          SizedBox(height: 2.h),
                          // Text('Calendar', style: GoogleFonts.poppins(
                          //   fontSize: 12.sp,
                          //   fontWeight: FontWeight.w600,
                          //   color: const Color.fromARGB(255, 49, 58, 63),
                          //   letterSpacing: -0.3,
                          // ),),
                          SizedBox(height: 2.h),
                          WarrantyCalendar(
                            receipts: _receipts,
                            onDateTap: () {
                              Navigator.pushNamed(context, '/receipt_list');
                            },
                          ),

                          SizedBox(height: 12.h), // Extra space for FAB overlap
                        ],
                      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Status summary (compact)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                Container(
                  height: 0.8.h,
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
                            child: Container(height: 10.h,),
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
                  total == 0 ? 'No Slips' : '$total Slips',
                  style: GoogleFonts.pacifico(
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
            flex: 2,
            child: HandDrawnButton(
              
              text: 'View Slips',
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
