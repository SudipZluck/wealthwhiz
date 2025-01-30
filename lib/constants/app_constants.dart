import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'WealthWhiz';
  static const String appVersion = '1.0.0';

  // API Keys and Endpoints
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';

  // Colors
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color accentColor = Color(0xFF7D5260);
  static const Color backgroundColor = Color(0xFFFFFBFE);
  static const Color errorColor = Color(0xFFB00020);

  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
  );

  // Padding and Margins
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Local Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String themeKey = 'app_theme';
  static const String authTokenKey = 'auth_token';
  static const String lastSyncKey = 'last_sync_timestamp';

  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Authentication failed. Please try again.';

  // Success Messages
  static const String saveSuccess = 'Changes saved successfully!';
  static const String deleteSuccess = 'Item deleted successfully!';
  static const String updateSuccess = 'Update completed successfully!';

  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableAIInsights = false;
  static const bool enablePushNotifications = true;

  // Limits and Constraints
  static const int maxTransactionNote = 500;
  static const int maxGoalDescription = 1000;
  static const double maxTransactionAmount = 999999.99;
  static const int maxAttachmentSize = 5 * 1024 * 1024; // 5MB

  // Date Formats
  static const String dateFormatFull = 'MMMM d, y';
  static const String dateFormatShort = 'MMM d, y';
  static const String dateFormatMonthYear = 'MMMM y';

  // Currency Formats
  static const String currencySymbolUSD = '\$';
  static const String currencySymbolEUR = '€';
  static const String currencySymbolGBP = '£';
  static const int decimalPlaces = 2;
}
