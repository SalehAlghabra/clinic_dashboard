import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exceptions.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _isBillingQueueOnly = true;

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
      final list = await repo.fetchInvoices(
        billingQueue: _isBillingQueueOnly,
        search: _searchController.text.trim(),
      );
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

  void _showSuccessConfirmationDialog(double amountPaid, double walletBalance) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('payment_success_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr('amount_paid')}: \$${amountPaid.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${context.tr('updated_wallet_balance')}: \$${walletBalance.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.primaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('close')),
            ),
          ],
        );
      },
    );
  }

  void _showCollectPaymentDialog(InvoiceReportItem inv) {
    final topUpController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final remaining = inv.remainingAmount;
            final currentWallet = inv.walletBalance;
            final hasSufficient = currentWallet >= remaining;
            final neededTopUp = remaining - currentWallet;

            if (topUpController.text.isEmpty && neededTopUp > 0) {
              topUpController.text = neededTopUp.toStringAsFixed(2);
            }

            return AlertDialog(
              title: Text(context.tr('collect_payment')),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                            child: ClipOval(
                              child: inv.profilePictureUrl != null
                                  ? Image.network(
                                      inv.profilePictureUrl!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 20, color: theme.primaryColor),
                                    )
                                  : Icon(Icons.person, size: 20, color: theme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inv.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Invoice #${inv.id} • Doctor: ${inv.doctorName}', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('Consultation Fee Deposit: \$${inv.consultationFee.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success)),
                      if (inv.additionalCost > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Doctor Additional Charge: \$${inv.additionalCost.toStringAsFixed(2)}${inv.additionalNote != null && inv.additionalNote!.isNotEmpty ? " (${inv.additionalNote})" : ""}',
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Total Amount Due: \$${inv.remainingAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.danger),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (hasSufficient ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: (hasSufficient ? AppColors.success : AppColors.warning).withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${context.tr('wallet_balance')}: \$${currentWallet.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: hasSufficient ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasSufficient
                                  ? 'Wallet balance is sufficient to cover payment.'
                                  : 'Insufficient wallet balance. Top up needed: \$${neededTopUp.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!hasSufficient) ...[
                        Text(context.tr('deposit_to_patient_wallet'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: topUpController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Top Up Amount',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      final amt = double.tryParse(topUpController.text.trim());
                                      if (amt == null || amt <= 0) return;
                                      setDialogState(() => isSubmitting = true);
                                      try {
                                        final repo = context.read<DashboardRepository>();
                                        await repo.depositWallet(inv.patientId, amt);
                                        if (dialogCtx.mounted) {
                                          Navigator.pop(dialogCtx);
                                          _loadInvoices();
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
                              child: Text(context.tr('top_up_now')),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.tr('patient_in_person_authorization'),
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(context.tr('cancel')),
                ),
                if (hasSufficient)
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
                              final res = await repo.updateInvoicePayment(inv.id, 'paid', 'wallet');

                              final amountPaid = (res['amount_paid'] ?? inv.remainingAmount).toDouble();
                              final newWallet = (res['wallet_balance'] ?? (currentWallet - remaining)).toDouble();

                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx);
                                _loadInvoices();
                                context.read<DashboardBloc>().add(RefreshDashboard());

                                _showSuccessConfirmationDialog(amountPaid, newWallet);
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
                        : Text(context.tr('confirm_wallet_payment')),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isBillingQueueOnly ? context.tr('billing_queue') : context.tr('invoices'),
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
              OutlinedButton.icon(
                onPressed: _loadInvoices,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(context.tr('refresh')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search & Tab Toggle Bar
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        selected: _isBillingQueueOnly,
                        label: Text(context.tr('billing_queue')),
                        avatar: const Icon(Icons.queue, size: 16),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _isBillingQueueOnly = true);
                            _loadInvoices();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        selected: !_isBillingQueueOnly,
                        label: Text(context.tr('all_invoices')),
                        avatar: const Icon(Icons.receipt, size: 16),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _isBillingQueueOnly = false);
                            _loadInvoices();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => _loadInvoices(),
                    decoration: InputDecoration(
                      hintText: context.tr('search_patients'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadInvoices();
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
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
                if (_isLoadingInvoices)
                  const Center(child: CircularProgressIndicator(color: AppColors.tealPrimary))
                else if (_errorMsg != null)
                  Center(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.danger)))
                else if (_invoices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_isBillingQueueOnly ? 'No completed visits waiting for payment.' : 'No invoices found.'),
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
                        DataColumn(label: Text(context.tr('total_amount'))),
                        DataColumn(label: Text(context.tr('remaining_amount'))),
                        DataColumn(label: Text(context.tr('payment_status'))),
                        DataColumn(label: Text(context.tr('actions'))),
                      ],
                      rows: _invoices.map((inv) {
                        final isPaid = inv.paymentStatus == 'paid';
                        return DataRow(cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                                  child: ClipOval(
                                    child: inv.profilePictureUrl != null
                                        ? Image.network(
                                            inv.profilePictureUrl!,
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 16, color: theme.primaryColor),
                                          )
                                        : Icon(Icons.person, size: 16, color: theme.primaryColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(inv.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          DataCell(Text(inv.doctorName)),
                          DataCell(Text('\$${inv.consultationFee.toStringAsFixed(2)}')),
                          DataCell(Text('\$${inv.additionalCost.toStringAsFixed(2)}')),
                          DataCell(Text('\$${inv.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
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
                          DataCell(
                            isPaid
                                ? const Icon(Icons.check_circle, color: AppColors.success)
                                : ElevatedButton.icon(
                                    onPressed: () => _showCollectPaymentDialog(inv),
                                    icon: const Icon(Icons.wallet, size: 16),
                                    label: Text(context.tr('collect_payment')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
}
