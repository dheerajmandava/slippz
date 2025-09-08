import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'models/receipt.dart';
import 'services/local_data_service.dart';

enum ReceiptSource { none, camera, gallery }

class ReceiptStorage extends StatefulWidget {
  final ReceiptSource initialSource;
  const ReceiptStorage({super.key, this.initialSource = ReceiptSource.none});

  @override
  State<ReceiptStorage> createState() => _ReceiptStorageState();
}

class _ReceiptStorageState extends State<ReceiptStorage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productNameController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _purchaseDateController;
  late final TextEditingController _warrantyEndDateController;
  late final TextEditingController _priceController;
  
  final List<String> _categories = [
    'Electronics',
    'Appliances',
    'Furniture',
    'Clothing',
    'Automotive',
    'Home & Garden',
    'Sports',
    'Other',
  ];
  String _selectedCategory = 'Other';
  String? _selectedImagePath;
  DateTime? _purchaseDate;
  DateTime? _warrantyEndDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with empty strings to prevent corruption
    _productNameController = TextEditingController(text: '');
    _storeNameController = TextEditingController(text: '');
    _purchaseDateController = TextEditingController(text: '');
    _warrantyEndDateController = TextEditingController(text: '');
    _priceController = TextEditingController(text: '');
    
    // Debug logging
    debugPrint('Controllers initialized successfully');
    debugPrint('Product name controller text: "${_productNameController.text}"');
    
    // Autostart appropriate picker based on the entry point
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutostart());
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _storeNameController.dispose();
    _purchaseDateController.dispose();
    _warrantyEndDateController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Helper method to check and fix corrupted controllers
  void _validateAndFixControllers() {
    final controllers = [
      _productNameController,
      _storeNameController,
      _purchaseDateController,
      _warrantyEndDateController,
      _priceController,
    ];
    
    for (final controller in controllers) {
      if (controller.text.contains(RegExp(r'[┤├]'))) {
        debugPrint('Detected corrupted controller, resetting...');
        controller.text = '';
        controller.selection = TextSelection.collapsed(offset: 0);
      }
    }
  }

  Future<void> _maybeAutostart() async {
    switch (widget.initialSource) {
      case ReceiptSource.camera:
        await _pickImage(ImageSource.camera);
        break;
      case ReceiptSource.gallery:
        await _pickImage(ImageSource.gallery);
        break;
      case ReceiptSource.none:
        break;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null && mounted) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
          _purchaseDateController.text = '${picked.day}/${picked.month}/${picked.year}';
        } else {
          _warrantyEndDate = picked;
          _warrantyEndDateController.text = '${picked.day}/${picked.month}/${picked.year}';
        }
      });
    }
  }

  int _calculateDaysUntilExpiry() {
    if (_warrantyEndDate == null) return 0;
    final now = DateTime.now();
    return _warrantyEndDate!.difference(now).inDays;
  }

  String _sanitizeInput(String input) {
    // Remove any potentially problematic characters
    return input.replaceAll(RegExp(r'[^\w\s\-\.\,\(\)\/]'), '');
  }

  Future<void> _addReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final receipt = Receipt(
        productName: _sanitizeInput(_productNameController.text.trim()),
        storeName: _sanitizeInput(_storeNameController.text.trim()),
        purchaseDate: _purchaseDate ?? DateTime.now(),
        warrantyEndDate: _warrantyEndDate ?? DateTime.now().add(const Duration(days: 365)),
        receiptImagePath: _selectedImagePath ?? '',
        price: _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) ?? 0.0 : 0.0,
        category: _selectedCategory,
      );

      await LocalDataService.instance.saveReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Warranty added successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding warranty: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addCategoryDialog() {
    final TextEditingController categoryController = TextEditingController(text: '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Category',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter category name',
          ),
          autofocus: true,
          onChanged: (value) {
            // Sanitize input in real-time
            final sanitized = _sanitizeInput(value);
            if (sanitized != value) {
              categoryController.value = categoryController.value.copyWith(
                text: sanitized,
                selection: TextSelection.collapsed(offset: sanitized.length),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newCategory = _sanitizeInput(categoryController.text.trim());
              if (newCategory.isNotEmpty) {
                setState(() {
                  _categories.add(newCategory);
                  _selectedCategory = newCategory;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Validate and fix controllers before building
    _validateAndFixControllers();

    // Wrap the entire widget in Material to provide Material context
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: 2.h),
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Text(
                    'Add Warranty',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: const Color(0xFF6B7280), size: 5.w),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            
            // Form content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    children: [
                      // Essential Fields
                      _buildEssentialFields(),
                      SizedBox(height: 2.h),
                      
                      // Additional Details
                      _buildAdditionalDetails(),
                      SizedBox(height: 2.h),
                      
                      // Photo Section
                      _buildPhotoSection(),
                      SizedBox(height: 3.h),
                      
                      // Action Buttons
                      _buildActionButtons(),
                      SizedBox(height: 2.h),
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

  Widget _buildPhotoSection() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: const Color(0xFF10B981),
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                'Receipt Photo',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          if (_selectedImagePath != null) ...[
            Container(
              width: double.infinity,
              height: 40.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selectedImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, size: 4.w),
                    label: Text('Retake', style: TextStyle(fontSize: 12.sp)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, size: 4.w),
                    label: Text('Change', style: TextStyle(fontSize: 12.sp)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              height: 25.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 8.w,
                    color: const Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Add receipt photo',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, size: 4.w),
                    label: Text('Camera', style: TextStyle(fontSize: 12.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, size: 4.w),
                    label: Text('Gallery', style: TextStyle(fontSize: 12.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEssentialFields() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Product name
          TextFormField(
            controller: _productNameController,
            decoration: InputDecoration(
              labelText: 'Product Name *',
              hintText: 'e.g., iPhone 15 Pro',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              floatingLabelAlignment: FloatingLabelAlignment.start,
              contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            style: TextStyle(fontSize: 11.sp),
            onChanged: (value) {
              // Sanitize input in real-time
              final sanitized = _sanitizeInput(value);
              if (sanitized != value) {
                _productNameController.value = _productNameController.value.copyWith(
                  text: sanitized,
                  selection: TextSelection.collapsed(offset: sanitized.length),
                );
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Product name is required';
              }
              return null;
            },
          ),
          SizedBox(height: 1.5.h),
          
          // Warranty end date
          TextFormField(
            controller: _warrantyEndDateController,
            decoration: InputDecoration(
              labelText: 'Warranty End Date *',
              hintText: 'Select when warranty expires',
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_month, color: const Color(0xFF10B981), size: 4.w),
                onPressed: () => _selectDate(context, false),
              ),
              helperText: _warrantyEndDate != null 
                ? '${_calculateDaysUntilExpiry()} days remaining'
                : 'When does your warranty expire?',
              helperStyle: TextStyle(fontSize: 9.sp),
              contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            style: TextStyle(fontSize: 11.sp),
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Warranty end date is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Store name
          TextFormField(
            controller: _storeNameController,
            decoration: InputDecoration(
              labelText: 'Store Name',
              hintText: 'e.g., Apple Store, Best Buy',
              contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            style: TextStyle(fontSize: 11.sp),
            onChanged: (value) {
              final sanitized = _sanitizeInput(value);
              if (sanitized != value) {
                _storeNameController.value = _storeNameController.value.copyWith(
                  text: sanitized,
                  selection: TextSelection.collapsed(offset: sanitized.length),
                );
              }
            },
          ),
          SizedBox(height: 1.5.h),
          
          // Purchase date
          TextFormField(
            controller: _purchaseDateController,
            decoration: InputDecoration(
              labelText: 'Purchase Date',
              hintText: 'When did you buy this?',
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_month, color: const Color(0xFF10B981), size: 4.w),
                onPressed: () => _selectDate(context, true),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            style: TextStyle(fontSize: 11.sp),
            readOnly: true,
          ),
          SizedBox(height: 1.5.h),
          
          // Price
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Price',
              hintText: '0.00',
              contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            style: TextStyle(fontSize: 11.sp),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              // Only allow numbers, decimal points, and basic characters
              final sanitized = value.replaceAll(RegExp(r'[^\d\.]'), '');
              if (sanitized != value) {
                _priceController.value = _priceController.value.copyWith(
                  text: sanitized,
                  selection: TextSelection.collapsed(offset: sanitized.length),
                );
              }
            },
          ),
          SizedBox(height: 1.5.h),
          
          // Category
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              SizedBox(height: 2.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 2.h,
                children: [
                  ..._categories.map((category) => FilterChip(
                    label: Text(category, style: TextStyle(fontSize: 11.sp)),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: _selectedCategory == category 
                        ? const Color(0xFF10B981) 
                        : const Color(0xFF6B7280),
                      fontWeight: _selectedCategory == category 
                        ? FontWeight.w600 
                        : FontWeight.w500,
                      fontSize: 11.sp,
                    ),
                  )),
                  FilterChip(
                    label: Text('+ Add', style: TextStyle(fontSize: 11.sp)),
                    selected: false,
                    onSelected: (_) => _addCategoryDialog(),
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 2.w),
        // Save Button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _addReceipt,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 3.w,
                    width: 3.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save Warranty',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}