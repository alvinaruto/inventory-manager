import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/low_stock_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    dashboardProvider.setAuthToken(authProvider.token);
    await dashboardProvider.refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: AppColors.warmWood,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.warmWood,
                        AppColors.warmWood.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Hello, ${authProvider.user?.name ?? 'User'}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAdmin ? 'Admin Dashboard' : 'Staff Dashboard',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Dashboard Content
            SliverToBoxAdapter(
              child: Consumer<DashboardProvider>(
                builder: (context, dashboard, _) {
                  if (dashboard.isLoading && dashboard.stats == null) {
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.warmWood),
                      ),
                    );
                  }

                  if (dashboard.error != null && dashboard.stats == null) {
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColors.red),
                            const SizedBox(height: 16),
                            Text(dashboard.error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDashboard,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final stats = dashboard.stats;
                  if (stats == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Grid
                        _buildQuickStats(stats, isAdmin),
                        const SizedBox(height: 24),

                        // Admin-only: Value Summary
                        if (isAdmin) ...[
                          _buildValueSummary(stats),
                          const SizedBox(height: 24),
                        ],

                        // Low Stock Alerts
                        if (stats.lowStockCount > 0 || stats.outOfStockCount > 0)
                          _buildLowStockSection(dashboard),

                        const SizedBox(height: 24),

                        // Category Breakdown
                        _buildCategoryBreakdown(stats),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(stats, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.deepWood,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Products',
                value: stats.totalProducts.toString(),
                icon: Icons.inventory_2,
                color: AppColors.warmWood,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Items in Stock',
                value: stats.totalItemsInStock.toString(),
                icon: Icons.check_circle_outline,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Low Stock',
                value: stats.lowStockCount.toString(),
                icon: Icons.warning_amber,
                color: AppColors.yellow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Out of Stock',
                value: stats.outOfStockCount.toString(),
                icon: Icons.error_outline,
                color: AppColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueSummary(stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet, color: AppColors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'Inventory Value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildValueItem('Cost Value', currencyFormat.format(stats.totalCostValue ?? 0)),
              _buildValueItem('Selling Value', currencyFormat.format(stats.totalSellingValue ?? 0)),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Potential Profit',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                currencyFormat.format(stats.potentialProfit ?? 0),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockSection(DashboardProvider dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stock Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.deepWood,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to inventory with low stock filter
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...dashboard.lowStockProducts.take(5).map((product) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LowStockItem(product: product),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'By Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.deepWood,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: stats.categoryBreakdown.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final category = entry.value;
              final isLast = index == stats.categoryBreakdown.length - 1;
              
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: AppColors.warmWood,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('${category.totalItems} items'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${category.productCount} products',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warmWood,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.grey.withOpacity(0.2),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
