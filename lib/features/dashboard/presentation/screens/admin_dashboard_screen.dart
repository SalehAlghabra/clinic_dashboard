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
    final isWide = MediaQuery.of(context).size.width >= 800;
    final isDark = context.watch<ThemeCubit>().state;

    final navItems = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: context.tr('overview'),
        page: const DashboardOverviewView(),
      ),
      _NavItem(
        icon: Icons.medical_information_outlined,
        selectedIcon: Icons.medical_information,
        label: context.tr('doctors'),
        page: const DashboardOverviewView(),
      ),
      _NavItem(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        label: context.tr('appointments'),
        page: const DashboardOverviewView(),
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: context.tr('invoices'),
        page: const DashboardOverviewView(),
      ),
      _NavItem(
        icon: Icons.gavel_outlined,
        selectedIcon: Icons.gavel,
        label: context.tr('violations'),
        page: const DashboardOverviewView(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          navItems[_selectedIndex].label,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<LanguageCubit>().toggleLanguage();
            },
            icon: const Icon(Icons.language, size: 18),
            label: Text(
              context.tr('switch_language'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? context.tr('light_mode') : context.tr('dark_mode'),
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
          const SizedBox(width: 8),

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
            NavigationRail(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.tealCanvas,
              elevation: 4,
              extended: _isExtended,
              useIndicator: true,
              indicatorColor: AppColors.tealPrimary.withValues(alpha: 0.2),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              selectedIconTheme: const IconThemeData(color: AppColors.tealPrimary),
              unselectedIconTheme: IconThemeData(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.tealPrimary,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: IconButton(
                  icon: Icon(
                    context.isArabic
                        ? (_isExtended ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left)
                        : (_isExtended ? Icons.keyboard_double_arrow_left : Icons.keyboard_double_arrow_right),
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
