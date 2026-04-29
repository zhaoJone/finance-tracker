import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Gray Scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Semantic Colors
  static const Color incomeGreen600 = Color(0xFF16A34A);
  static const Color incomeGreen500 = Color(0xFF22C55E);
  static const Color expenseRed500 = Color(0xFFEF4444);
  static const Color expenseRed600 = Color(0xFFDC2626);
  static const Color balanceBlue600 = Color(0xFF2563EB);
  static const Color balanceBlue500 = Color(0xFF3B82F6);

  // Badge Colors
  static const Color badgeDefaultBg = Color(0xFFF3F4F6);
  static const Color badgeDefaultText = Color(0xFF1F2937);
  static const Color badgeSuccessBg = Color(0xFFDCFCE7);
  static const Color badgeSuccessText = Color(0xFF166534);
  static const Color badgeWarningBg = Color(0xFFFEF9C3);
  static const Color badgeWarningText = Color(0xFF854D0E);
  static const Color badgeErrorBg = Color(0xFFFEE2E2);
  static const Color badgeErrorText = Color(0xFF991B1B);
  static const Color badgeInfoBg = Color(0xFFDBEAFE);
  static const Color badgeInfoText = Color(0xFF1E40AF);

  // Chart Colors
  static const Color chartIncome = Color(0xFF10B981);
  static const Color chartExpense = Color(0xFFEF4444);
  static const Color chartBalance = Color(0xFF3B82F6);

  // Pie Palette (8 colors)
  static const List<Color> piePalette = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
  ];

  // Category Preset Colors (12)
  static const List<Color> categoryPreset = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E53),
    Color(0xFFFFCD56),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFF6C5CE7),
    Color(0xFFA29BFE),
    Color(0xFFFD79A8),
    Color(0xFFF8B500),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFF74B9FF),
  ];

  // Surface & Overlay
  static const Color surface = Colors.white;
  static const Color scaffoldBg = Colors.white;
  static const Color modalOverlay = Colors.black38;

  // Semantic convenience getters
  static Color get income => incomeGreen600;
  static Color get expense => expenseRed500;
  static Color get balance => balanceBlue600;
}
