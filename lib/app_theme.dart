import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: .light,
      colorScheme: .fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: Colors.grey.shade50,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: .all(.circular(16))),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: .all(.circular(20))),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: .dark,
      colorScheme: .fromSeed(seedColor: Colors.blue, brightness: .dark),
    );
  }
}
