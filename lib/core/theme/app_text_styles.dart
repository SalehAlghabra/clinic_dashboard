import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle font({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: 'Cairo', // Falls back to default if font asset is dynamic
    );
  }

  static TextStyle titleLarge(Color color) => font(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle titleMedium(Color color) => font(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => font(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle bodySmall(Color color) => font(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );
}
