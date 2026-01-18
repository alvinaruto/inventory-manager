/// API configuration for connecting Flutter app to Node.js backend
class ApiConfig {
  // Base URL for the API
  // For Android Emulator: use 10.0.2.2 instead of localhost
  // For iOS Simulator: use localhost
  // For Physical Device: use your computer's local IP address
  
  // DEVELOPMENT - Android Emulator
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // DEVELOPMENT - iOS Simulator
  // static const String baseUrl = 'http://localhost:3000/api';
  
  // DEVELOPMENT - Physical Device (replace with your IP)
  // static const String baseUrl = 'http://192.168.1.100:3000/api';
  
  // Default for testing (will work on iOS simulator and web)
  static const String baseUrl = 'http://localhost:3000/api';
  
  // API Endpoints
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String registerPublic = '/auth/register-public';
  static const String profile = '/auth/me';
  static const String changePassword = '/auth/password';
  
  static const String products = '/products';
  static const String categories = '/categories';
  static const String dashboard = '/dashboard';
  static const String dashboardStats = '/dashboard/stats';
  static const String lowStock = '/dashboard/low-stock';
  static const String profitCalculator = '/dashboard/profit-calculator';
  static const String users = '/users';
  
  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);
  
  // Build full URL
  static String buildUrl(String endpoint) => '$baseUrl$endpoint';
}
