import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import '../widgets/product_card.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedCategoryId;
  String _selectedStockStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (!productProvider.isLoading && productProvider.hasNextPage) {
        productProvider.loadMore();
      }
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    productProvider.setAuthToken(authProvider.token);
    await productProvider.fetchProducts(
      refresh: refresh,
      search: _searchController.text.isEmpty ? null : _searchController.text,
      categoryId: _selectedCategoryId,
      stockStatus: _selectedStockStatus,
    );
  }

  void _applyFilters() {
    _loadProducts(refresh: true);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategoryId = null;
      _selectedStockStatus = 'all';
    });
    _loadProducts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),

          // Active Filters Chips
          _buildActiveFilters(),

          // Product List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                if (productProvider.isLoading && productProvider.products.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.warmWood),
                  );
                }

                if (productProvider.error != null && productProvider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.red),
                        const SizedBox(height: 16),
                        Text(productProvider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadProducts(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (productProvider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToAddProduct(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _loadProducts(refresh: true),
                  color: AppColors.warmWood,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: productProvider.products.length + (productProvider.hasNextPage ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == productProvider.products.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.warmWood,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      final product = productProvider.products[index];
                      return ProductCard(
                        product: product,
                        showCostPrice: isAdmin,
                        onTap: () => _navigateToProductDetail(context, product),
                        onEdit: isAdmin ? () => _navigateToEditProduct(context, product) : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _navigateToAddProduct(context),
              backgroundColor: AppColors.saffronOrange,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildActiveFilters() {
    final hasFilters = _selectedCategoryId != null || _selectedStockStatus != 'all';
    
    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedCategoryId != null)
                    _buildFilterChip(
                      label: Provider.of<CategoryProvider>(context)
                          .getCategoryById(_selectedCategoryId!)?.name ?? 'Category',
                      onRemove: () {
                        setState(() => _selectedCategoryId = null);
                        _applyFilters();
                      },
                    ),
                  if (_selectedStockStatus != 'all')
                    _buildFilterChip(
                      label: StockStatus.fromString(_selectedStockStatus).displayName,
                      onRemove: () {
                        setState(() => _selectedStockStatus = 'all');
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppColors.lightGold,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.warmWood,
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      const Text(
                        'Filter Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category Filter
                      const Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, _) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: _selectedCategoryId == null,
                                onSelected: (selected) {
                                  setModalState(() => _selectedCategoryId = null);
                                  setState(() {});
                                },
                              ),
                              ...categoryProvider.categories.map((category) {
                                return ChoiceChip(
                                  label: Text(category.name),
                                  selected: _selectedCategoryId == category.id,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      _selectedCategoryId = selected ? category.id : null;
                                    });
                                    setState(() {});
                                  },
                                );
                              }),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Stock Status Filter
                      const Text(
                        'Stock Status',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedStockStatus == 'all',
                            onSelected: (selected) {
                              setModalState(() => _selectedStockStatus = 'all');
                              setState(() {});
                            },
                          ),
                          ChoiceChip(
                            label: const Text('In Stock'),
                            selected: _selectedStockStatus == 'in_stock',
                            selectedColor: AppColors.lightGreen,
                            onSelected: (selected) {
                              setModalState(() => _selectedStockStatus = selected ? 'in_stock' : 'all');
                              setState(() {});
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Low Stock'),
                            selected: _selectedStockStatus == 'low_stock',
                            selectedColor: AppColors.lightYellow,
                            onSelected: (selected) {
                              setModalState(() => _selectedStockStatus = selected ? 'low_stock' : 'all');
                              setState(() {});
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Out of Stock'),
                            selected: _selectedStockStatus == 'out_of_stock',
                            selectedColor: AppColors.lightRed,
                            onSelected: (selected) {
                              setModalState(() => _selectedStockStatus = selected ? 'out_of_stock' : 'all');
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _navigateToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductFormScreen()),
    ).then((_) => _loadProducts(refresh: true));
  }

  void _navigateToEditProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductFormScreen(product: product)),
    ).then((_) => _loadProducts(refresh: true));
  }

  void _navigateToProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: product.id)),
    ).then((_) => _loadProducts(refresh: true));
  }
}
