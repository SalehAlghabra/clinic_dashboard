import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  final bool isDarkMode;
  final Color? primaryColor;

  const ThemeState({
    required this.isDarkMode,
    this.primaryColor,
  });

  ThemeState copyWith({
    bool? isDarkMode,
    Color? primaryColor,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }

  @override
  List<Object?> get props => [isDarkMode, primaryColor];
}
