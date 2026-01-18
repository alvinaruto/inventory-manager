import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventory_app/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../utils/app_colors.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'profit_calculator_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _adminScreens = [
    const DashboardScreen(),
    const InventoryScreen(),
    const ProfitCalculatorScreen(),
    const ProfileScreen(),
  ];

  final List<Widget> _staffScreens = [
    const DashboardScreen(),
    const InventoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    categoryProvider.setAuthToken(authProvider.token);
    await categoryProvider.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;
    final screens = isAdmin ? _adminScreens : _staffScreens;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.deepWood.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: AppLocalizations.of(context)!.dashboard,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: AppLocalizations.of(context)!.inventory,
                ),
                if (isAdmin)
                  _buildNavItem(
                    index: 2,
                    icon: Icons.calculate_outlined,
                    activeIcon: Icons.calculate,
                    label: AppLocalizations.of(context)!.totalProfit,
                  ),
                _buildNavItem(
                  index: isAdmin ? 3 : 2,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: AppLocalizations.of(context)!.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightGold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.warmWood : AppColors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.warmWood : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
