import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/reports_models.dart';

class AppointmentsManagementView extends StatelessWidget {
  const AppointmentsManagementView({super.key});

  void _showCompleteDialog(BuildContext context, AppointmentReportItem appt) {
    final costController = TextEditingController(text: '0.00');
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(context.tr('complete_appointment')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Consultation Fee Paid: \$${appt.consultationFee.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.tr('additional_cost'),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: context.tr('additional_note'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final repo = context.read<DashboardRepository>();
                  final cost = double.tryParse(costController.text.trim()) ?? 0.0;
                  await repo.updateAppointmentStatus(
                    appt.id,
                    'completed',
                    additionalCost: cost,
                    additionalNote: noteController.text.trim(),
                  );
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appointment completed & invoice generated!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  }
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: const Text('Complete & Issue Invoice'),
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
          final appts = state.recentAppointments;

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
                          context.tr('appointments'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('appointments_overview_desc'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<DashboardBloc>().add(RefreshDashboard());
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(context.tr('refresh')),
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
                      if (appts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            context.tr('no_appointments_recorded'),
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
                              DataColumn(label: Text(context.tr('patient_name'))),
                              DataColumn(label: Text(context.tr('doctor_name'))),
                              DataColumn(label: Text(context.tr('consultation_fee'))),
                              DataColumn(label: Text(context.tr('additional_cost'))),
                              DataColumn(label: Text(context.tr('additional_note'))),
                              DataColumn(label: Text(context.tr('date_time'))),
                              DataColumn(label: Text(context.tr('status'))),
                              DataColumn(label: Text(context.tr('actions'))),
                            ],
                            rows: appts.map((appt) {
                              Color statusColor = AppColors.warning;
                              if (appt.status == 'completed') statusColor = AppColors.success;
                              if (appt.status == 'confirmed') statusColor = AppColors.info;
                              if (appt.status == 'cancelled') statusColor = AppColors.danger;

                              return DataRow(cells: [
                                DataCell(Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(appt.doctorName)),
                                DataCell(Text('\$${appt.consultationFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text('\$${appt.additionalCost.toStringAsFixed(2)}')),
                                DataCell(Text(appt.additionalNote ?? '-')),
                                DataCell(Text('${appt.appointmentDate} ${appt.appointmentTime}')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      appt.status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  appt.status == 'completed' || appt.status == 'cancelled'
                                      ? const Text('-')
                                      : ElevatedButton(
                                          onPressed: () => _showCompleteDialog(context, appt),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          child: const Text('Complete Visit'),
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
