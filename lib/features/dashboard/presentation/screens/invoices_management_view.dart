import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/reports_models.dart';

class InvoicesManagementView extends StatefulWidget {
  const InvoicesManagementView({super.key});

  @override
  State<InvoicesManagementView> createState() => _InvoicesManagementViewState();
}

class _InvoicesManagementViewState extends State<InvoicesManagementView> {
  List<InvoiceReportItem> _invoices = [];
  bool _isLoadingInvoices = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoadingInvoices = true;
      _errorMsg = null;
    });

    try {
      final repo = context.read<DashboardRepository>();
      final list = await repo.fetchRevenueReport();
      if (mounted) {
        setState(() {
          _invoices = list;
          _isLoadingInvoices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll('ApiException: ', '');
          _isLoadingInvoices = false;
        });
      }
    }
  }

  void _showCollectPaymentDialog(InvoiceReportItem inv) {
    String selectedMethod = 'cash'; // 'cash' or 'wallet'
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.tr('collect_payment')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice #${inv.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Patient: ${inv.patientName}'),
                  Text('Total Amount: \$${inv.totalAmount.toStringAsFixed(2)}'),
                  Text('Already Paid: \$${inv.alreadyPaid.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success)),
                  Text('Remaining Balance: \$${inv.remainingAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                  const SizedBox(height: 16),
                  Text(context.tr('payment_method'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: Text(context.tr('cash')),
                    value: 'cash',
                    groupValue: selectedMethod,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMethod = val);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(context.tr('wallet')),
                    value: 'wallet',
                    groupValue: selectedMethod,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMethod = val);
                    },
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
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();
                            await repo.updateInvoicePayment(inv.id, 'paid', selectedMethod);
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment collected successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              _loadInvoices();
                              context.read<DashboardBloc>().add(RefreshDashboard());
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.danger),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(context.tr('collect_payment')),
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
          return const Center(child: CircularProgressIndicator(color: AppColors.tealPrimary));
        }

        if (state is DashboardLoaded) {
          final financial = state.stats.financial;

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
                          context.tr('invoices'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('revenue_overview_desc'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _loadInvoices();
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

                // Financial Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 700;
                    return Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      children: [
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.payments_outlined, color: AppColors.success, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  '\$${financial.totalRevenue.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(context.tr('total_revenue'), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        if (!isMobile) const SizedBox(width: 16),
                        if (isMobile) const SizedBox(height: 16),
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.pending_actions_outlined, color: AppColors.warning, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  '\$${financial.pendingPayments.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(context.tr('pending_payments'), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        if (!isMobile) const SizedBox(width: 16),
                        if (isMobile) const SizedBox(height: 16),
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined, color: AppColors.info, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  '\$${financial.totalDeposits.toStringAsFixed(2)}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(context.tr('total_deposits'), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Invoices Table Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('invoices'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (_isLoadingInvoices)
                        const Center(child: CircularProgressIndicator(color: AppColors.tealPrimary))
                      else if (_errorMsg != null)
                        Center(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.danger)))
                      else if (_invoices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No invoices found.'),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text(context.tr('patient_name'))),
                              DataColumn(label: Text(context.tr('doctor_name'))),
                              DataColumn(label: Text(context.tr('consultation_fee'))),
                              DataColumn(label: Text(context.tr('total_amount'))),
                              DataColumn(label: Text(context.tr('already_paid'))),
                              DataColumn(label: Text(context.tr('remaining_amount'))),
                              DataColumn(label: Text(context.tr('payment_status'))),
                              DataColumn(label: Text(context.tr('payment_method'))),
                              DataColumn(label: Text(context.tr('actions'))),
                            ],
                            rows: _invoices.map((inv) {
                              final isPaid = inv.paymentStatus == 'paid';
                              return DataRow(cells: [
                                DataCell(Text(inv.patientName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(inv.doctorName)),
                                DataCell(Text('\$${inv.consultationFee.toStringAsFixed(2)}')),
                                DataCell(Text('\$${inv.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text('\$${inv.alreadyPaid.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success))),
                                DataCell(Text('\$${inv.remainingAmount.toStringAsFixed(2)}', style: TextStyle(color: isPaid ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      inv.paymentStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: isPaid ? AppColors.success : AppColors.warning,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(inv.paymentMethod.toUpperCase())),
                                DataCell(
                                  isPaid
                                      ? const Icon(Icons.check_circle, color: AppColors.success)
                                      : ElevatedButton(
                                          onPressed: () => _showCollectPaymentDialog(inv),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          child: Text(context.tr('collect_payment')),
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
