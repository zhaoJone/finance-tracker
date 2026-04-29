import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  /// rounded-lg - buttons, inputs, modals
  static const double sm = 8.0;

  /// rounded-xl - cards
  static const double md = 12.0;

  /// rounded-full - badges, dots, icon containers
  static const double full = 999.0;

  /// List category icon size
  static const double categoryDot = 12.0;

  // Convenient BorderRadius getters
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get fullRadius => BorderRadius.circular(full);
}
