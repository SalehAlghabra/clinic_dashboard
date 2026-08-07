import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_events_states.dart';
import '../bloc/theme_cubit.dart';
import '../bloc/language_cubit.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import 'dashboard_overview_view.dart';
import 'doctors_management_view.dart';
import 'patients_management_view.dart';
import 'appointments_management_view.dart';
import 'invoices_management_view.dart';
import 'violations_management_view.dart';
import 'receptionists_management_view.dart';

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

  void _showProfileDialog(BuildContext context) {
    final authBlocState = context.read<AuthBloc>().state;
    UserModel? currentUser;
    if (authBlocState is Authenticated) {
      currentUser = authBlocState.user;
    }

    final nameController = TextEditingController(text: currentUser?.name ?? '');
    final phoneController = TextEditingController(text: currentUser?.phone ?? '');
    final currentPasswordController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    Uint8List? selectedBytes;
    String? selectedFileName;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final primaryColor = Theme.of(context).primaryColor;

            return AlertDialog(
              title: Text(context.tr('edit_profile')),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                        backgroundImage: selectedBytes != null
                            ? MemoryImage(selectedBytes!)
                            : (currentUser?.profilePictureUrl != null
                                ? NetworkImage(currentUser!.profilePictureUrl!) as ImageProvider
                                : null),
                        child: (selectedBytes == null && currentUser?.profilePictureUrl == null)
                            ? Icon(Icons.person, size: 40, color: primaryColor)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            if (file.bytes != null) {
                              setDialogState(() {
                                selectedBytes = file.bytes;
                                selectedFileName = file.name;
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: Text(
                          selectedFileName != null ? selectedFileName! : context.tr('choose_photo_device'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: context.tr('full_name'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: context.tr('phone'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                      const Divider(height: 32),
                      Text(context.tr('new_password'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: currentPasswordController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: context.tr('current_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: context.tr('new_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: context.tr('confirm_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(context.tr('cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final pass = passwordController.text.trim();
                          final confirmPass = confirmPasswordController.text.trim();
                          final currPass = currentPasswordController.text.trim();

                          if (pass.isNotEmpty) {
                            if (currPass.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('current_password')),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                              return;
                            }
                            if (pass != confirmPass) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('passwords_do_not_match')),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                              return;
                            }
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            final authRepo = RepositoryProvider.of<AuthRepository>(context);
                            final updatedUser = await authRepo.updateProfile(
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              currentPassword: currPass.isNotEmpty ? currPass : null,
                              password: pass.isNotEmpty ? pass : null,
                              fileBytes: selectedBytes,
                              fileName: selectedFileName,
                            );

                            if (dialogCtx.mounted) {
                              final messenger = ScaffoldMessenger.of(context);
                              final authBloc = context.read<AuthBloc>();
                              final successText = context.tr('profile_updated_success');
                              Navigator.pop(dialogCtx);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(successText),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              authBloc.add(ProfileUpdated(updatedUser));
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(parseErrorMessage(e)), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(context.tr('save_changes')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final primaryColor = theme.primaryColor;

    // Check role from AuthBloc
    final authState = context.watch<AuthBloc>().state;
    final userRole = authState is Authenticated ? authState.user.role : 'admin';

    final List<_NavItem> allNavItems = [
      _NavItem(
        label: context.tr('overview'),
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        page: const DashboardOverviewView(),
        roles: ['admin'],
      ),
      _NavItem(
        label: context.tr('appointments'),
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        page: const AppointmentsManagementView(),
        roles: ['admin', 'receptionist'],
      ),
      _NavItem(
        label: context.tr('billing_queue'),
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        page: const InvoicesManagementView(),
        roles: ['admin', 'receptionist'],
      ),
      _NavItem(
        label: context.tr('patients'),
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        page: const PatientsManagementView(),
        roles: ['admin', 'receptionist'],
      ),
      _NavItem(
        label: context.tr('doctors'),
        icon: Icons.medical_services_outlined,
        selectedIcon: Icons.medical_services,
        page: const DoctorsManagementView(),
        roles: ['admin', 'receptionist'],
      ),
      _NavItem(
        label: context.tr('violations'),
        icon: Icons.gavel_outlined,
        selectedIcon: Icons.gavel,
        page: const ViolationsManagementView(),
        roles: ['admin'],
      ),
      _NavItem(
        label: context.tr('receptionists'),
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge,
        page: const ReceptionistsManagementView(),
        roles: ['admin'],
      ),
    ];

    // Filter nav items by role
    final navItems = allNavItems.where((item) => item.roles.contains(userRole)).toList();
    final activeIndex = _selectedIndex.clamp(0, navItems.length - 1);

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
            if (userRole == 'receptionist') ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'RECEPTIONIST',
                  style: TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: primaryColor),
            tooltip: context.tr('edit_profile'),
            onPressed: () => _showProfileDialog(context),
          ),
          const SizedBox(width: 4),

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
                selectedIndex: activeIndex,
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
              child: navItems[activeIndex].page,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: activeIndex,
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
  final List<String> roles;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
    required this.roles,
  });
}
