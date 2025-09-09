import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sizer/sizer.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';
import '../widgets/currency_text.dart';
import '../services/settings_service.dart';
import '../widgets/minimal_slip_item.dart';

class WarrantyListScreen extends StatefulWidget {
  const WarrantyListScreen({super.key});

  @override
  State<WarrantyListScreen> createState() => _WarrantyListScreenState();
}

class _WarrantyListScreenState extends State<WarrantyListScreen> {
  List<Receipt> _receipts = [];
  List<Receipt> _filteredReceipts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  int _expiringThreshold = 30;

  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'All', 'value': 'All', 'icon': Icons.list},
    {'label': 'Urgent', 'value': 'Urgent', 'icon': Icons.warning},
    {'label': 'Expiring', 'value': 'Expiring', 'icon': Icons.schedule},
    {'label': 'Covered', 'value': 'Covered', 'icon': Icons.check_circle},
    {'label': 'Expired', 'value': 'Expired', 'icon': Icons.cancel},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final receipts = await DatabaseService().getAllReceipts();
      final threshold = await SettingsService.getExpiringThreshold();
      
      setState(() {
        _receipts = receipts;
        _expiringThreshold = threshold;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading warranties: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReceipts = _receipts.where((receipt) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            receipt.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            receipt.storeName.toLowerCase().contains(_searchQuery.toLowerCase());

        // Status filter
        final now = DateTime.now();
        final daysUntilExpiry = receipt.warrantyEndDate.difference(now).inDays;
        
        bool matchesFilter = true;
        switch (_selectedFilter) {
          case 'Urgent':
            matchesFilter = daysUntilExpiry <= 7 && daysUntilExpiry > 0;
            break;
          case 'Expiring':
            matchesFilter = daysUntilExpiry <= _expiringThreshold && daysUntilExpiry > 7;
            break;
          case 'Covered':
            matchesFilter = daysUntilExpiry > _expiringThreshold;
            break;
          case 'Expired':
            matchesFilter = daysUntilExpiry <= 0;
            break;
          case 'All':
          default:
            matchesFilter = true;
            break;
        }

        return matchesSearch && matchesFilter;
      }).toList();
      
      // Sort by urgency and date
      _filteredReceipts.sort((a, b) {
        final now = DateTime.now();
        final aDays = a.warrantyEndDate.difference(now).inDays;
        final bDays = b.warrantyEndDate.difference(now).inDays;
        
        // Sort by urgency first (urgent items first)
        if (aDays <= 7 && aDays > 0 && bDays > 7) return -1;
        if (bDays <= 7 && bDays > 0 && aDays > 7) return 1;
        
        // Then by date (newest first)
        return b.purchaseDate.compareTo(a.purchaseDate);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(),
            // Search Bar
            _buildSearchBar(),
            // Filter Chips
            _buildFilterChips(),
            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredReceipts.isEmpty
                      ? Center(child: _buildEmptyState(),)
                      : _buildWarrantiesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          // Minimal back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              '←',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          // Title and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Warranties',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  '${_filteredReceipts.length} items',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Minimal refresh
          GestureDetector(
            onTap: _loadData,
            child: Text(
              '↻',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          // Settings button
          GestureDetector(
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/local_storage');
              if (result == true) {
                _loadData(); // Refresh when returning from settings
              }
            },
            child: Icon(
              Icons.settings,
              size: 5.w,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
        decoration: InputDecoration(
          hintText: 'search...',
          hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
          // prefixIcon: Text(
          //   '🔍',
          //   style: TextStyle(fontSize: 14.sp),
          // ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 2.h),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 6.h,
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option['value'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = option['value'];
                _applyFilters();
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 3.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                option['label'],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 4.h),
          Text(
            'Loading warranties...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'Urgent':
        message = 'No urgent warranties';
        subtitle = 'All your warranties are safe for now';
        icon = Icons.check_circle;
        break;
      case 'Expiring':
        message = 'No expiring warranties';
        subtitle = 'Nothing expiring in the next $_expiringThreshold days';
        icon = Icons.schedule;
        break;
      case 'Covered':
        message = 'No covered warranties';
        subtitle = 'Add some warranties to see them here';
        icon = Icons.shield;
        break;
      case 'Expired':
        message = 'No expired warranties';
        subtitle = 'Great! No expired warranties found';
        icon = Icons.cancel;
        break;
      default:
        message = 'No warranties yet';
        subtitle = 'Add your first warranty to get started';
        icon = Icons.receipt_long;
        break;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 12.w,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_selectedFilter == 'All') ...[
              SizedBox(height: 6.h),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true), // Return true to trigger refresh
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: 5.w),
                label: Text(
                  'Add First Warranty',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantiesList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF10B981),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: _filteredReceipts.length,
        itemBuilder: (context, index) {
          final receipt = _filteredReceipts[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: MinimalSlipItem(
              receipt: receipt,
              onTap: () => _showWarrantyDetails(receipt),
            ),
          );
        },
      ),
    );
  }

  void _showWarrantyDetails(Receipt receipt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWarrantyDetailsSheet(receipt),
    );
  }

  Widget _buildWarrantyDetailsSheet(Receipt receipt) {
    final now = DateTime.now();
    final daysUntilExpiry = receipt.warrantyEndDate.difference(now).inDays;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF3F4F6),
                        ),
                        child: receipt.receiptImagePath.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(receipt.receiptImagePath),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.receipt,
                                color: Color(0xFF6B7280),
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              receipt.productName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              receipt.storeName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          Navigator.pop(context);
                          if (value == 'edit') {
                            _editWarranty(receipt);
                          } else if (value == 'delete') {
                            _deleteWarranty(receipt);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(daysUntilExpiry).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(daysUntilExpiry).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(daysUntilExpiry),
                          color: _getStatusColor(daysUntilExpiry),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(daysUntilExpiry),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _getStatusColor(daysUntilExpiry),
                                ),
                              ),
                              Text(
                                _getStatusSubtext(daysUntilExpiry),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _getStatusColor(daysUntilExpiry).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Details
                  _buildDetailRow('Purchase Date', _formatDate(receipt.purchaseDate)),
                  _buildDetailRow('Warranty Ends', _formatDate(receipt.warrantyEndDate)),
                  _buildDetailRowWidget('Price', CurrencyText(amount: receipt.price, style: Theme.of(context).textTheme.labelLarge)),
                  _buildDetailRow('Category', receipt.category),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWidget(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: value,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) return const Color(0xFF6B7280);
    if (daysUntilExpiry <= 7) return const Color(0xFFEF4444);
    if (daysUntilExpiry <= _expiringThreshold) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  IconData _getStatusIcon(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) return Icons.cancel;
    if (daysUntilExpiry <= 7) return Icons.warning;
    if (daysUntilExpiry <= _expiringThreshold) return Icons.schedule;
    return Icons.check_circle;
  }

  String _getStatusText(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) return 'Expired';
    if (daysUntilExpiry <= 7) return 'Urgent';
    if (daysUntilExpiry <= _expiringThreshold) return 'Expiring Soon';
    return 'Fully Covered';
  }

  String _getStatusSubtext(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) return 'Warranty has expired';
    if (daysUntilExpiry == 1) return 'Expires tomorrow';
    if (daysUntilExpiry <= 7) return 'Expires in $daysUntilExpiry days';
    if (daysUntilExpiry <= _expiringThreshold) return 'Expires in $daysUntilExpiry days';
    return 'Safe for $daysUntilExpiry more days';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editWarranty(Receipt receipt) {
    // Edit functionality will be implemented in future version
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _deleteWarranty(Receipt receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Warranty'),
        content: Text('Are you sure you want to delete "${receipt.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseService().deleteReceipt(receipt.id!);
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Warranty deleted successfully'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting warranty: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}
