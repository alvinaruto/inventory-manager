import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  String _currencyCode = 'USD'; // 'USD' or 'KHR'
  double _exchangeRate = 4100.0; // 1 USD = 4100 KHR

  String get currencyCode => _currencyCode;
  double get exchangeRate => _exchangeRate;

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString('currency_code') ?? 'USD';
    _exchangeRate = prefs.getDouble('exchange_rate') ?? 4100.0;
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currencyCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', code);
    notifyListeners();
  }

  Future<void> updateExchangeRate(double rate) async {
    _exchangeRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('exchange_rate', rate);
    notifyListeners();
  }

  String formatPrice(double priceInUsd) {
    if (_currencyCode == 'USD') {
      final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
      return formatter.format(priceInUsd);
    } else {
      final priceInKhr = priceInUsd * _exchangeRate;
      // Round to nearest 100 Riel for cleaner prices usually
      final roundedKhr = (priceInKhr / 100).round() * 100;
      final formatter = NumberFormat.currency(
        symbol: '៛',
        decimalDigits: 0,
        locale: 'km', // User Khmer locale for number formatting if available
      );
      return formatter.format(roundedKhr);
    }
  }

  // Format amount in specific currency without conversion
  String format(double amount, String currencyCode) {
    if (currencyCode == 'USD') {
      final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
      return formatter.format(amount);
    } else {
      final formatter = NumberFormat.currency(
        symbol: '៛',
        decimalDigits: 0,
        locale: 'km',
      );
      return formatter.format(amount);
    }
  }
}
