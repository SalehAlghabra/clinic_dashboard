import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../bloc/theme_cubit.dart';
import '../bloc/theme_state.dart';

class ThemeColorPickerDialog extends StatelessWidget {
  const ThemeColorPickerDialog({super.key});

  static const List<Map<String, dynamic>> themeColors = [
    {'name': 'Ocean Blue', 'color': Color(0xFF0077B6)},
    {'name': 'Teal Green', 'color': Color(0xFF0D9488)},
    {'name': 'Emerald Green', 'color': Color(0xFF10B981)},
    {'name': 'Rose Pink', 'color': Color(0xFFE11D48)},
    {'name': 'Indigo Blue', 'color': Color(0xFF4F46E5)},
    {'name': 'Warm Amber', 'color': Color(0xFFD97706)},
  ];

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => const ThemeColorPickerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final activeColor = themeState.primaryColor ?? theme.primaryColor;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.palette_outlined, color: theme.primaryColor),
              const SizedBox(width: 10),
              Text(
                context.tr('select_accent_color'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('choose_accent_desc'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: themeColors.map((item) {
                  final color = item['color'] as Color;
                  final isSelected = activeColor.toARGB32() == color.toARGB32();

                  return GestureDetector(
                    onTap: () {
                      context.read<ThemeCubit>().setPrimaryColor(color);
                      Navigator.pop(context);
                    },
                    child: Tooltip(
                      message: item['name'],
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('close')),
            ),
          ],
        );
      },
    );
  }
}
