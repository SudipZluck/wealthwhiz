import 'package:intl/intl.dart';
import '../models/user.dart';

class CurrencyFormatter {
  static String format(double amount, Currency currency) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String _getCurrencySymbol(Currency currency) {
    switch (currency) {
      case Currency.usd:
        return '\$';
      case Currency.eur:
        return '€';
      case Currency.gbp:
        return '£';
      case Currency.inr:
        return '₹';
      case Currency.jpy:
        return '¥';
      case Currency.aud:
        return 'A\$';
      case Currency.cad:
        return 'C\$';
    }
  }

  static String formatCompact(double amount, Currency currency) {
    if (amount >= 1000000) {
      return '${_getCurrencySymbol(currency)}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${_getCurrencySymbol(currency)}${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return format(amount, currency);
    }
  }

  static double parseAmount(String amount, {bool allowNegative = true}) {
    // Remove currency symbols and other non-numeric characters except decimal point and minus sign
    final cleanAmount = amount.replaceAll(RegExp(r'[^0-9.-]'), '');

    try {
      final parsedAmount = double.parse(cleanAmount);
      if (!allowNegative && parsedAmount < 0) {
        return 0.0;
      }
      return parsedAmount;
    } catch (e) {
      return 0.0;
    }
  }

  static String formatWithSign(double amount, Currency currency) {
    return '${amount >= 0 ? '+' : ''}${format(amount, currency)}';
  }

  static String getPercentage(double value, {int decimalPlaces = 1}) {
    return '${value.toStringAsFixed(decimalPlaces)}%';
  }
}
