import 'package:flutter/material.dart';

/// App color palette matching the religious offerings shop theme
/// Warm Woods, Gold, Saffron Orange, and Clean White
class AppColors {
  // Primary Colors
  static const Color warmWood = Color(0xFF8B4513);
  static const Color gold = Color(0xFFD4AF37);
  static const Color saffronOrange = Color(0xFFF4A460);
  static const Color deepWood = Color(0xFF3E2723);
  
  // Background Colors
  static const Color white = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFF5F0EB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Accent Colors
  static const Color lightGold = Color(0xFFFFF8E1);
  static const Color lightOrange = Color(0xFFFFF3E0);
  static const Color lightWood = Color(0xFFEFEBE9);
  
  // Status Colors
  static const Color green = Color(0xFF4CAF50);
  static const Color yellow = Color(0xFFFFB300);
  static const Color red = Color(0xFFE53935);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color lightYellow = Color(0xFFFFF8E1);
  static const Color lightRed = Color(0xFFFFEBEE);
  
  // Neutral Colors
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF616161);

  // Aliases for missing colors used in RegisterScreen
  static const Color error = red;
  static const Color cream = Color(0xFFFFF8E7); // Soft cream color
  static const Color goldenOrange = saffronOrange;
  
  // Stock Status Colors
  static Color stockStatusColor(String status) {
    switch (status) {
      case 'in_stock':
        return green;
      case 'low_stock':
        return yellow;
      case 'out_of_stock':
        return red;
      default:
        return grey;
    }
  }
  
  static Color stockStatusBackground(String status) {
    switch (status) {
      case 'in_stock':
        return lightGreen;
      case 'low_stock':
        return lightYellow;
      case 'out_of_stock':
        return lightRed;
      default:
        return lightGrey;
    }
  }
  
  // Gradient for premium look
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warmWood, Color(0xFFA0522D)],
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, Color(0xFFE6C545)],
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [saffronOrange, Color(0xFFFFB74D)],
  );
}
