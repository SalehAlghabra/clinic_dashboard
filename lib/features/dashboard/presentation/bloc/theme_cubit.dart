import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/storage_service.dart';

class ThemeCubit extends Cubit<bool> {
  final StorageService _storageService;

  ThemeCubit({required StorageService storageService})
      : _storageService = storageService,
        super(false) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _storageService.isDarkMode();
    emit(isDark);
  }

  Future<void> toggleTheme() async {
    final newIsDark = !state;
    await _storageService.setDarkMode(newIsDark);
    emit(newIsDark);
  }
}
