import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'models/receipt.dart';
import 'services/database_service.dart';

enum ReceiptSource { none, camera, gallery, file }

class ReceiptStorage extends StatefulWidget {
  final ReceiptSource initialSource;
  const ReceiptStorage({super.key, this.initialSource = ReceiptSource.none});

  @override
  State<ReceiptStorage> createState() => _ReceiptStorageState();
}

class _ReceiptStorageState extends State<ReceiptStorage> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _warrantyEndDateController = TextEditingController();
  final _priceController = TextEditingController();
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
  void dispose() {
    _productNameController.dispose();
    _storeNameController.dispose();
    _purchaseDateController.dispose();
    _warrantyEndDateController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Autostart appropriate picker based on the entry point
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutostart());
  }

  Future<void> _maybeAutostart() async {
    switch (widget.initialSource) {
      case ReceiptSource.camera:
        await _pickImage(ImageSource.camera);
        break;
      case ReceiptSource.gallery:
        await _pickImage(ImageSource.gallery);
        break;
      case ReceiptSource.file:
        await _pickFile();
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      final pickedPath = result?.files.single.path;
      if (pickedPath != null && mounted) {
        setState(() {
          _selectedImagePath = pickedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
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

  Future<void> _addReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final receipt = Receipt(
        productName: _productNameController.text.trim(),
        storeName: _storeNameController.text.trim(),
        purchaseDate: _purchaseDate ?? DateTime.now(),
        warrantyEndDate: _warrantyEndDate ?? DateTime.now().add(const Duration(days: 365)),
        receiptImagePath: _selectedImagePath ?? '',
        price: _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) ?? 0.0 : 0.0,
        category: _selectedCategory,
      );

      await DatabaseService().insertReceipt(receipt);

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
    final TextEditingController categoryController = TextEditingController();
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newCategory = categoryController.text.trim();
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Add Warranty',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with better hierarchy
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warranty Details',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your warranty information to track it',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Photo section with better visual hierarchy
              _buildPhotoSection(),
              const SizedBox(height: 24),
              
              // Main form with progressive disclosure
              _buildMainForm(),
              const SizedBox(height: 24),
              
              // Optional details with expansion
              _buildOptionalDetails(),
              const SizedBox(height: 32),
              
              // Action buttons with better contrast
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withOpacity(0.05),
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
              Icon(
                Icons.camera_alt,
                color: const Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Receipt Photo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '(Optional)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedImagePath != null) ...[
            Container(
              width: double.infinity,
              height: 200,
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
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.folder, size: 18),
                  label: const Text('File'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          
          // Product name
          TextFormField(
            controller: _productNameController,
            decoration: const InputDecoration(
              labelText: 'Product Name *',
              hintText: 'Enter product name',
              prefixIcon: Icon(Icons.inventory, color: Color(0xFF10B981)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Product name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Warranty end date
          TextFormField(
            controller: _warrantyEndDateController,
            decoration: InputDecoration(
              labelText: 'Warranty End Date *',
              hintText: 'Select end date',
              prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF10B981)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => _selectDate(context, false),
              ),
              helperText: _warrantyEndDate != null 
                ? '${_calculateDaysUntilExpiry()} days remaining'
                : null,
            ),
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

  Widget _buildOptionalDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.more_horiz,
              color: const Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Additional Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const Spacer(),
            Text(
              '(Optional)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Store name
                TextFormField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Store Name',
                    hintText: 'Enter store name',
                    prefixIcon: Icon(Icons.store, color: Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Purchase date
                TextFormField(
                  controller: _purchaseDateController,
                  decoration: InputDecoration(
                    labelText: 'Purchase Date',
                    hintText: 'Select purchase date',
                    prefixIcon: const Icon(Icons.shopping_cart, color: Color(0xFF10B981)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () => _selectDate(context, true),
                    ),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                
                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: 'Enter price',
                    prefixIcon: Icon(Icons.attach_money, color: Color(0xFF10B981)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Category
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._categories.map((category) => FilterChip(
                          label: Text(category),
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
                          ),
                        )),
                        FilterChip(
                          label: const Text('+ Add'),
                          selected: false,
                          onSelected: (_) => _addCategoryDialog(),
                          selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF10B981),
                          labelStyle: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _addReceipt,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save Warranty',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}