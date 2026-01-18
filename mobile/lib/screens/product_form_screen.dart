import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_colors.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameKmController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _skuController = TextEditingController();

  String? _selectedCategoryId;
  XFile? _selectedImage;
  String _costCurrency = 'USD';
  String _sellingCurrency = 'USD';
  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    } else {
      _thresholdController.text = '5';
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _nameKmController.text = product.nameKm ?? '';
    _descriptionController.text = product.description ?? '';
    _costPriceController.text = product.costPrice?.toStringAsFixed(2) ?? '';
    _sellingPriceController.text = product.sellingPrice.toStringAsFixed(2);
    _quantityController.text = product.quantityInStock.toString();
    _thresholdController.text = product.lowStockThreshold.toString();
    _skuController.text = product.sku ?? '';
    _selectedCategoryId = product.categoryId;
    _costCurrency = product.costCurrency;
    _sellingCurrency = product.sellingCurrency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameKmController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source, maxWidth: 800);
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    try {
      Product? result;
      
      final String name = _nameController.text.trim();
      final String? nameKm = _nameKmController.text.trim().isEmpty ? null : _nameKmController.text.trim();

      if (_isEditing) {
        result = await productProvider.updateProduct(
          id: widget.product!.id,
          name: name,
          nameKm: nameKm,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          categoryId: _selectedCategoryId,
          costPrice: double.parse(_costPriceController.text),
          sellingPrice: double.parse(_sellingPriceController.text),
          costCurrency: _costCurrency,
          sellingCurrency: _sellingCurrency,
          quantityInStock: int.parse(_quantityController.text),
          lowStockThreshold: int.parse(_thresholdController.text),
          sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
          image: _selectedImage,
        );
      } else {
        result = await productProvider.createProduct(
          name: name,
          nameKm: nameKm,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          categoryId: _selectedCategoryId,
          costPrice: double.parse(_costPriceController.text),
          sellingPrice: double.parse(_sellingPriceController.text),
          costCurrency: _costCurrency,
          sellingCurrency: _sellingCurrency,
          quantityInStock: int.parse(_quantityController.text),
          lowStockThreshold: int.parse(_thresholdController.text),
          sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
          image: _selectedImage,
        );
      }

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Product updated!' : 'Product created!'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.error ?? 'Failed to save product'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${widget.product!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(widget.product!.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted!'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.error ?? 'Failed to delete product'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: AppColors.white,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
              onPressed: _isLoading ? null : _deleteProduct,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Product Name
              _buildTextField(
                controller: _nameController,
                label: 'Product Name (English)',
                hint: 'e.g., Teak Wood Spirit House',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Product Name Khmer
              _buildTextField(
                controller: _nameKmController,
                label: 'Product Name (Khmer)',
                hint: 'e.g., ផ្ទះសំណាក់ឈើទាល',
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              _buildCategoryDropdown(),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Product description...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Price Section
              const Text(
                'Pricing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepWood,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _costPriceController,
                          label: 'Cost Price',
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCurrencyDropdown(
                          value: _costCurrency,
                          onChanged: (val) => setState(() => _costCurrency = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _sellingPriceController,
                          label: 'Selling Price',
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildCurrencyDropdown(
                          value: _sellingCurrency,
                          onChanged: (val) => setState(() => _sellingCurrency = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stock Section
              const Text(
                'Stock',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepWood,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _thresholdController,
                      label: 'Low Stock Alert',
                      hint: '5',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SKU
              _buildTextField(
                controller: _skuController,
                label: 'SKU (Optional)',
                hint: 'e.g., SH-TK-LG-001',
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isEditing ? 'Update Product' : 'Add Product'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey.withOpacity(0.3)),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(
                        _selectedImage!.path,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        io.File(_selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
              )
            : _isEditing && widget.product!.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.product!.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: AppColors.warmWood),
                      ),
                      errorWidget: (context, url, error) => _buildImagePlaceholder(),
                    ),
                  )
                : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: AppColors.grey,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to add image',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'Category',
            filled: true,
            fillColor: AppColors.white,
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Select Category'),
            ),
            ...categoryProvider.categories.map((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
        );
      },
    );
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      items: const [
        DropdownMenuItem(value: 'USD', child: Text('USD (\$)', style: TextStyle(fontSize: 14))),
        DropdownMenuItem(value: 'KHR', child: Text('KHR (៛)', style: TextStyle(fontSize: 14))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        filled: true,
        fillColor: AppColors.white,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }
}
