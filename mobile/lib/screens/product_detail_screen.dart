import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:inventory_app/l10n/app_localizations.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/app_colors.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
    });
  }

  Future<void> _loadProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.getProduct(widget.productId);
  }

  void _showStockAdjustmentDialog(Product product) {
    final quantityController = TextEditingController();
    String adjustmentType = 'add';
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adjust Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current stock: ${product.quantityInStock}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Add'),
                      selected: adjustmentType == 'add',
                      onSelected: (selected) {
                        setDialogState(() => adjustmentType = 'add');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Remove'),
                      selected: adjustmentType == 'subtract',
                      onSelected: (selected) {
                        setDialogState(() => adjustmentType = 'subtract');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Set'),
                      selected: adjustmentType == 'set',
                      onSelected: (selected) {
                        setDialogState(() => adjustmentType = 'set');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: adjustmentType == 'set' ? 'New Quantity' : l10n.quantity,
                  hintText: 'Enter quantity',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text);
                if (quantity != null && quantity >= 0) {
                  Navigator.pop(context);
                  final productProvider = Provider.of<ProductProvider>(context, listen: false);
                  final success = await productProvider.updateStock(
                    id: product.id,
                    quantity: quantity,
                    type: adjustmentType,
                  );
                  if (success) {
                    _loadProduct();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Stock updated!'),
                          backgroundColor: AppColors.green,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading && productProvider.selectedProduct == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.warmWood),
            );
          }

          final product = productProvider.selectedProduct;
          if (product == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                  const SizedBox(height: 16),
                  const Text('Product not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final stockColor = AppColors.stockStatusColor(product.stockStatus.value);
          final stockBgColor = AppColors.stockStatusBackground(product.stockStatus.value);

          return CustomScrollView(
            slivers: [
              // Image App Bar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.warmWood,
                flexibleSpace: FlexibleSpaceBar(
                  background: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.lightGold,
                            child: const Center(
                              child: CircularProgressIndicator(color: AppColors.warmWood),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),
                actions: [
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductFormScreen(product: product),
                          ),
                        ).then((_) => _loadProduct());
                      },
                    ),
                ],
              ),

              // Product Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Stock Status Row
                      Row(
                        children: [
                          if (product.categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.lightGold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product.categoryName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.warmWood,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: stockBgColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              // Translate stock status if possible, or use display name
                              _translateStockStatus(product.stockStatus.value, l10n) ?? product.stockStatus.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: stockColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Product Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepWood,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // SKU
                      if (product.sku != null)
                        Text(
                          'SKU: ${product.sku}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyProvider.format(product.sellingPrice, product.sellingCurrency),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warmWood,
                            ),
                          ),
                          if (isAdmin && product.costPrice != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              '${l10n.costPrice}: ${currencyProvider.format(product.costPrice!, product.costCurrency)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Profit margin for admin
                      if (isAdmin && product.profitPerUnit != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up, color: AppColors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Profit: ${currencyProvider.format(product.profitPerUnit!, product.sellingCurrency)} (${product.profitPercentage?.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Stock Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepWood.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Stock Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showStockAdjustmentDialog(product),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Adjust'),
                                ),
                              ],
                            ),
                            const Divider(),
                            _buildInfoRow('Quantity in Stock', '${product.quantityInStock}'),
                            _buildInfoRow('Low Stock Threshold', '${product.lowStockThreshold}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (product.description != null && product.description!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.description!,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _translateStockStatus(String status, AppLocalizations l10n) {
    if (status == 'low_stock') return l10n.lowStock;
    if (status == 'out_of_stock') return l10n.outOfStock;
    // 'in_stock'
    return null;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.lightGold,
      child: const Center(
        child: Icon(
          Icons.temple_buddhist,
          size: 80,
          color: AppColors.warmWood,
        ),
      ),
    );
  }
}
