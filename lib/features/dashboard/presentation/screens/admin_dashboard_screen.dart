import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_events_states.dart';
import '../bloc/theme_cubit.dart';
import '../bloc/language_cubit.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import 'dashboard_overview_view.dart';
import 'doctors_management_view.dart';
import 'appointments_management_view.dart';
import 'invoices_management_view.dart';
import 'violations_management_view.dart';

import '../widgets/theme_color_picker_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isExtended = true;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const FetchDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final primaryColor = theme.primaryColor;

    final List<_NavItem> navItems = [
      _NavItem(
        label: context.tr('overview'),
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        page: const DashboardOverviewView(),
      ),
      _NavItem(
        label: context.tr('doctors'),
        icon: Icons.medical_services_outlined,
        selectedIcon: Icons.medical_services,
        page: const DoctorsManagementView(),
      ),
      _NavItem(
        label: context.tr('appointments'),
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        page: const AppointmentsManagementView(),
      ),
      _NavItem(
        label: context.tr('invoices'),
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        page: const InvoicesManagementView(),
      ),
      _NavItem(
        label: context.tr('violations'),
        icon: Icons.gavel_outlined,
        selectedIcon: Icons.gavel,
        page: const ViolationsManagementView(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.local_hospital, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Text(
              context.tr('app_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.palette_outlined, color: primaryColor),
            tooltip: context.tr('theme_color'),
            onPressed: () {
              ThemeColorPickerDialog.show(context);
            },
          ),
          const SizedBox(width: 4),

          TextButton.icon(
            onPressed: () {
              context.read<LanguageCubit>().toggleLanguage();
            },
            icon: Icon(Icons.language, size: 18, color: primaryColor),
            label: Text(
              context.tr('switch_language'),
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ),
          const SizedBox(width: 4),

          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? context.tr('light_mode') : context.tr('dark_mode'),
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
          const SizedBox(width: 4),

          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            tooltip: context.tr('logout'),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                extended: _isExtended,
                useIndicator: true,
                indicatorColor: isDark ? primaryColor.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.15),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.6),
                    width: isDark ? 1.0 : 1.5,
                  ),
                ),
                selectedIconTheme: IconThemeData(color: primaryColor, size: 24),
                unselectedIconTheme: IconThemeData(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  size: 22,
                ),
                selectedLabelTextStyle: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                trailing: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: IconButton(
                    icon: Icon(
                      context.isArabic
                          ? (_isExtended ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left)
                          : (_isExtended ? Icons.keyboard_double_arrow_left : Icons.keyboard_double_arrow_right),
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    onPressed: () {
                      setState(() => _isExtended = !_isExtended);
                    },
                    tooltip: 'Toggle sidebar',
                  ),
                ),
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                destinations: navItems.map((item) {
                  return NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: Container(
              color: isDark ? AppColors.darkBg : AppColors.lightBg,
              child: navItems[_selectedIndex].page,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: navItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                );
              }).toList(),
            ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });
}
