import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_card.dart';

class DashboardOverviewView extends StatelessWidget {
  final void Function(int targetSectionIndex)? onNavigate;

  const DashboardOverviewView({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          );
        }

        if (state is DashboardError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('refresh')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is DashboardLoaded) {
          final stats = state.stats;
          final totalAppts = stats.appointments.total > 0 ? stats.appointments.total : 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome Bar & Refresh
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('welcome_back'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('overview'),
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

                // Stat Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount = 4;
                    if (width < 600) {
                      crossAxisCount = 1;
                    } else if (width < 1100) {
                      crossAxisCount = 2;
                    }

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: width < 600 ? 2.2 : 1.6,
                      children: [
                        StatCard(
                          title: context.tr('total_patients'),
                          value: '${stats.users.totalPatients}',
                          subtitle: '+${stats.users.newPatientsToday} ${context.tr('new_patients_today')}',
                          icon: Icons.people_alt_outlined,
                          accentColor: AppColors.tealPrimary,
                          onTap: () => onNavigate?.call(3),
                        ),
                        StatCard(
                          title: context.tr('total_doctors'),
                          value: '${stats.users.totalDoctors}',
                          subtitle: '${stats.users.totalReceptionists} ${context.tr('total_receptionists')}',
                          icon: Icons.medical_services_outlined,
                          accentColor: AppColors.info,
                          onTap: () => onNavigate?.call(4),
                        ),
                        StatCard(
                          title: context.tr('today_appointments'),
                          value: '${stats.appointments.today}',
                          subtitle: '${stats.appointments.completed} ${context.tr('completed_appointments')}',
                          icon: Icons.calendar_today_outlined,
                          accentColor: AppColors.purple,
                          onTap: () => onNavigate?.call(1),
                        ),
                        StatCard(
                          title: context.tr('total_revenue'),
                          value: '\$${stats.financial.totalRevenue.toStringAsFixed(2)}',
                          subtitle: '\$${stats.financial.pendingPayments.toStringAsFixed(2)} ${context.tr('pending_payments')}',
                          icon: Icons.payments_outlined,
                          accentColor: AppColors.success,
                          onTap: () => onNavigate?.call(2),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Visual Metrics Charts Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 900;
                    return Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      children: [
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: MetricsChartCard(
                            title: context.tr('appointments'),
                            subtitle: '${context.tr('total_appointments')}: ${stats.appointments.total}',
                            items: [
                              ProgressMetricItem(
                                label: context.tr('completed_appointments'),
                                count: stats.appointments.completed,
                                percentage: stats.appointments.completed / totalAppts,
                                color: AppColors.success,
                              ),
                              ProgressMetricItem(
                                label: context.tr('confirmed_appointments'),
                                count: stats.appointments.confirmed,
                                percentage: stats.appointments.confirmed / totalAppts,
                                color: AppColors.info,
                              ),
                              ProgressMetricItem(
                                label: context.tr('pending_appointments'),
                                count: stats.appointments.pending,
                                percentage: stats.appointments.pending / totalAppts,
                                color: AppColors.warning,
                              ),
                              ProgressMetricItem(
                                label: context.tr('cancelled_appointments'),
                                count: stats.appointments.cancelled,
                                percentage: stats.appointments.cancelled / totalAppts,
                                color: AppColors.danger,
                              ),
                            ],
                          ),
                        ),
                        if (!isMobile) const SizedBox(width: 16),
                        if (isMobile) const SizedBox(height: 16),
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: MetricsChartCard(
                            title: context.tr('invoices'),
                            subtitle: context.tr('total_revenue'),
                            items: [
                              ProgressMetricItem(
                                label: context.tr('total_revenue'),
                                count: stats.financial.totalInvoices,
                                percentage: 1.0,
                                color: AppColors.tealPrimary,
                              ),
                              ProgressMetricItem(
                                label: context.tr('total_deposits'),
                                count: (stats.financial.totalDeposits / 100).round(),
                                percentage: 0.75,
                                color: AppColors.info,
                              ),
                              ProgressMetricItem(
                                label: context.tr('total_penalties'),
                                count: (stats.financial.totalPenalties / 10).round(),
                                percentage: 0.25,
                                color: AppColors.danger,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Data Table: Recent Appointments Activity
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
                      Text(
                        context.tr('recent_activity'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.recentAppointments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No recent appointments logged yet.',
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
                              DataColumn(label: Text(context.tr('date_time'))),
                              DataColumn(label: Text(context.tr('status'))),
                            ],
                            rows: state.recentAppointments.take(10).map((appt) {
                              Color statusColor = AppColors.warning;
                              if (appt.status == 'completed') statusColor = AppColors.success;
                              if (appt.status == 'confirmed') statusColor = AppColors.info;
                              if (appt.status == 'cancelled') statusColor = AppColors.danger;

                              return DataRow(cells: [
                                DataCell(Text(appt.patientName)),
                                DataCell(Text(appt.doctorName)),
                                DataCell(Text('\$${appt.consultationFee.toStringAsFixed(2)}')),
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
