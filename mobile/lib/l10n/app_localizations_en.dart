// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Inventory Manager';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToManage => 'Sign in to manage your inventory';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get validEmail => 'Please enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get validPassword => 'Password must be at least 6 characters';

  @override
  String get signIn => 'Sign In';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get inventory => 'Inventory';

  @override
  String get profile => 'Profile';

  @override
  String get products => 'Products';

  @override
  String get categories => 'Categories';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get totalValue => 'Total Value';

  @override
  String get totalProfit => 'Total Profit';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get filter => 'Filter';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get productName => 'Product Name';

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get sellingPrice => 'Selling Price';

  @override
  String get quantity => 'Quantity';

  @override
  String get alertThreshold => 'Alert Threshold';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDelete => 'Are you sure you want to delete this product?';

  @override
  String get logout => 'Logout';

  @override
  String get changePassword => 'Change Password';

  @override
  String get language => 'Language';

  @override
  String get currency => 'Currency';

  @override
  String get required => 'Required';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get createAccount => 'Create Account';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get register => 'Register';

  @override
  String get name => 'Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registrationSuccess => 'Registration successful';
}
