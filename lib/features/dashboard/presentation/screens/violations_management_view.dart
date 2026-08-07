import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/reports_models.dart';

class ViolationsManagementView extends StatelessWidget {
  const ViolationsManagementView({super.key});

  void _showDepositDialog(BuildContext context, {List<ViolationReportItem>? patients, ViolationReportItem? selectedPatient}) {
    final theme = Theme.of(context);
    ViolationReportItem? currentPatient = selectedPatient ?? (patients != null && patients.isNotEmpty ? patients.first : null);
    final amountController = TextEditingController(text: '100.0');
    bool isDeduct = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: Text(isDeduct ? 'Deduct from Patient Wallet' : context.tr('deposit_wallet')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (patients != null && patients.isNotEmpty)
                    DropdownButtonFormField<ViolationReportItem>(
                      initialValue: currentPatient,
                      decoration: InputDecoration(labelText: context.tr('select_patient')),
                      items: patients.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text('${p.patientName} (${p.email})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setStateModal(() {
                            currentPatient = val;
                          });
                        }
                      },
                    )
                  else if (currentPatient != null)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                        backgroundImage: currentPatient?.profilePictureUrl != null ? NetworkImage(currentPatient!.profilePictureUrl!) : null,
                        child: currentPatient?.profilePictureUrl == null ? Icon(Icons.person, color: theme.primaryColor) : null,
                      ),
                      title: Text(currentPatient!.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(currentPatient!.email),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Add Funds (+)')),
                          selected: !isDeduct,
                          selectedColor: AppColors.success.withValues(alpha: 0.2),
                          onSelected: (_) => setStateModal(() => isDeduct = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Deduct (-)')),
                          selected: isDeduct,
                          selectedColor: AppColors.danger.withValues(alpha: 0.2),
                          onSelected: (_) => setStateModal(() => isDeduct = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: isDeduct ? 'Deduction Amount (\$)' : context.tr('deposit_amount')),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(context.tr('cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeduct ? AppColors.danger : theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      final userId = currentPatient?.id ?? 0;
                      final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                      if (userId <= 0 || amount <= 0) {
                        throw Exception('Please select a valid patient and enter an amount.');
                      }

                      final repo = context.read<DashboardRepository>();
                      if (isDeduct) {
                        await repo.deductWallet(userId, amount);
                      } else {
                        await repo.depositWallet(userId, amount);
                      }
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isDeduct
                                ? 'Deducted \$${amount.toStringAsFixed(2)} from ${currentPatient?.patientName}\'s wallet!'
                                : 'Deposited \$${amount.toStringAsFixed(2)} to ${currentPatient?.patientName}\'s wallet!'),
                            backgroundColor: isDeduct ? AppColors.info : AppColors.success,
                          ),
                        );
                        context.read<DashboardBloc>().add(RefreshDashboard());
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(parseErrorMessage(e)),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(isDeduct ? 'Deduct Funds' : context.tr('deposit')),
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

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return Center(child: CircularProgressIndicator(color: theme.primaryColor));
        }

        if (state is DashboardLoaded) {
          final violations = state.violations;

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
                          context.tr('violations'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('violations_overview_desc'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.read<DashboardBloc>().add(RefreshDashboard()),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(context.tr('refresh')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primaryColor,
                            side: BorderSide(color: theme.primaryColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showDepositDialog(context, patients: violations),
                          icon: const Icon(Icons.account_balance_wallet_outlined),
                          label: Text(context.tr('deposit_wallet')),
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
                      if (violations.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            context.tr('no_violations_recorded'),
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
                              DataColumn(label: Text(context.tr('email'))),
                              DataColumn(label: Text(context.tr('violation_count'))),
                              DataColumn(label: Text(context.tr('total_penalties'))),
                              DataColumn(label: Text(context.tr('penalty_rate'))),
                              DataColumn(label: Text(context.tr('actions'))),
                            ],
                            rows: violations.map((v) {
                              return DataRow(cells: [
                                DataCell(Text(v.patientName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(v.email)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${v.violationCount}',
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text('\$${v.totalPenalties.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold))),
                                DataCell(Text(v.penaltyRate, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  ElevatedButton.icon(
                                    onPressed: () => _showDepositDialog(context, selectedPatient: v),
                                    icon: const Icon(Icons.add_card, size: 16),
                                    label: Text(context.tr('deposit')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
