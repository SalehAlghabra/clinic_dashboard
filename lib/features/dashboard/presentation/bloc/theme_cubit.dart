import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/storage_service.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final StorageService _storageService;

  ThemeCubit({required StorageService storageService})
      : _storageService = storageService,
        super(const ThemeState(isDarkMode: false)) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _storageService.isDarkMode();
    final primaryHex = await _storageService.getPrimaryColor();

    Color? primaryColor;
    if (primaryHex != null && primaryHex.isNotEmpty) {
      try {
        final val = int.parse(primaryHex, radix: 16);
        primaryColor = Color(val);
      } catch (_) {}
    }

    emit(ThemeState(isDarkMode: isDark, primaryColor: primaryColor));
  }

  Future<void> toggleTheme() async {
    final newIsDark = !state.isDarkMode;
    await _storageService.setDarkMode(newIsDark);
    emit(state.copyWith(isDarkMode: newIsDark));
  }

  Future<void> setPrimaryColor(Color color) async {
    emit(state.copyWith(primaryColor: color));
    final hexString = color.toARGB32().toRadixString(16);
    await _storageService.savePrimaryColor(hexString);
  }
}
