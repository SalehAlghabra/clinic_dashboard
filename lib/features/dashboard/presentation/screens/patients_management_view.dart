import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/reports_models.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';

class PatientsManagementView extends StatefulWidget {
  const PatientsManagementView({super.key});

  @override
  State<PatientsManagementView> createState() => _PatientsManagementViewState();
}

class _PatientsManagementViewState extends State<PatientsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  List<PatientReportItem> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients([String? query]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<DashboardRepository>();
      final list = await repo.fetchPatientsReport(search: query ?? _searchController.text.trim());
      setState(() {
        _patients = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showDepositDialog(PatientReportItem patient) {
    final amountController = TextEditingController(text: '50.00');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return AlertDialog(
              title: Text(context.tr('deposit_to_patient_wallet')),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr('patient_name')}: ${patient.patientName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('wallet_balance')}: \$${patient.walletBalance.toStringAsFixed(2)}',
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: context.tr('deposit_amount'),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(context.tr('cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final amt = double.tryParse(amountController.text.trim());
                          if (amt == null || amt <= 0) return;

                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();
                            await repo.depositWallet(patient.id, amt);

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('deposit_success')),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              _loadPatients();
                              context.read<DashboardBloc>().add(RefreshDashboard());
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(context.tr('deposit')),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('patients'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('patients_overview_desc'),
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _loadPatients(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(context.tr('refresh')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Bar Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => _loadPatients(val),
                      decoration: InputDecoration(
                        hintText: context.tr('search_patients'),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadPatients('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Patients Table
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    )
                  else if (_patients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          context.tr('no_patients_found'),
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columnSpacing: 24,
                        columns: [
                          DataColumn(label: Text(context.tr('patient_name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.tr('email'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.tr('phone'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.tr('wallet_balance'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.tr('violation_count'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.tr('actions'), style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _patients.map((patient) {
                          return DataRow(cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                                    backgroundImage: patient.profilePictureUrl != null ? NetworkImage(patient.profilePictureUrl!) : null,
                                    child: patient.profilePictureUrl == null ? Icon(Icons.person, size: 18, color: theme.primaryColor) : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    patient.patientName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(patient.email)),
                            DataCell(Text(patient.phone.isNotEmpty ? patient.phone : '-')),
                            DataCell(
                              Text(
                                '\$${patient.walletBalance.toStringAsFixed(2)}',
                                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (patient.violationCount > 0 ? AppColors.danger : AppColors.success).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${patient.violationCount}',
                                  style: TextStyle(
                                    color: patient.violationCount > 0 ? AppColors.danger : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              ElevatedButton.icon(
                                onPressed: () => _showDepositDialog(patient),
                                icon: const Icon(Icons.add_card, size: 16),
                                label: Text(context.tr('deposit_wallet')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
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
          ),
        ],
      ),
    );
  }
}
