import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/storage_service.dart';

class LanguageCubit extends Cubit<Locale> {
  final StorageService _storageService;

  LanguageCubit({required StorageService storageService})
      : _storageService = storageService,
        super(const Locale('en')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final code = await _storageService.getLocale();
    emit(Locale(code));
  }

  Future<void> toggleLanguage() async {
    final nextCode = state.languageCode == 'ar' ? 'en' : 'ar';
    await _storageService.setLocale(nextCode);
    emit(Locale(nextCode));
  }
}
