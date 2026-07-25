import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../widgets/doctor_details_modal.dart';

class DoctorsManagementView extends StatelessWidget {
  const DoctorsManagementView({super.key});

  void _showAddDoctorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'password123');
    final phoneController = TextEditingController();
    final specController = TextEditingController(text: 'General Practice');
    final bioController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('add_doctor')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: context.tr('doctor_name')),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: context.tr('email')),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: context.tr('password')),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: context.tr('phone')),
                ),
                TextField(
                  controller: specController,
                  decoration: InputDecoration(labelText: context.tr('specialization')),
                ),
                TextField(
                  controller: bioController,
                  decoration: InputDecoration(labelText: context.tr('bio')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final repo = context.read<DashboardRepository>();
                  await repo.createDoctor(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    phone: phoneController.text.trim(),
                    specialization: specController.text.trim(),
                    bio: bioController.text.trim(),
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Doctor account created successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: ${e.toString()}'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create Doctor'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator(color: AppColors.tealPrimary));
        }

        if (state is DashboardLoaded) {
          final doctors = state.doctorReports;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('doctors'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('doctor_performance'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDoctorDialog(context),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('add_doctor')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (doctors.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            context.tr('no_doctors_listed'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text(context.tr('doctor_name'))),
                              DataColumn(label: Text(context.tr('specialization'))),
                              DataColumn(label: Text(context.tr('total_appointments'))),
                              DataColumn(label: Text(context.tr('completed_appointments'))),
                              DataColumn(label: Text(context.tr('cancelled_appointments'))),
                              DataColumn(label: Text(context.tr('total_revenue'))),
                              DataColumn(label: Text(context.tr('actions'))),
                            ],
                            rows: doctors.map((doc) {
                              return DataRow(cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                                        child: Icon(Icons.person, color: theme.primaryColor),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        doc.doctorName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(doc.specialization)),
                                DataCell(Text('${doc.totalAppointments}')),
                                DataCell(Text('${doc.completed}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
                                DataCell(Text('${doc.cancelled}', style: const TextStyle(color: AppColors.danger))),
                                DataCell(Text('\$${doc.revenue.toStringAsFixed(2)}', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold))),
                                DataCell(
                                  OutlinedButton.icon(
                                    onPressed: () => DoctorDetailsModal.show(context, doc),
                                    icon: const Icon(Icons.edit_calendar, size: 16),
                                    label: Text(context.tr('schedule_and_services')),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.primaryColor,
                                      side: BorderSide(color: theme.primaryColor),
                                    ),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
