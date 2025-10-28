import 'package:flutter/material.dart';

ThemeData buildTheme() {
  final base = ThemeData(
    colorSchemeSeed: Colors.teal,
    useMaterial3: true,
    brightness: Brightness.dark,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    cardTheme: const CardTheme(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
}
