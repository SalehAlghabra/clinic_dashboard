import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/reports_models.dart';
import '../../data/models/financial_transaction_model.dart';

class InvoicesManagementView extends StatefulWidget {
  final String initialTab;

  const InvoicesManagementView({
    super.key,
    this.initialTab = 'billing_queue',
  });

  @override
  State<InvoicesManagementView> createState() => _InvoicesManagementViewState();
}

class _InvoicesManagementViewState extends State<InvoicesManagementView> {
  final TextEditingController _searchController = TextEditingController();
  late String _activeTab; // 'billing_queue', 'all_invoices', 'financial_history'
  String _selectedHistoryType = 'all'; // 'all', 'deposit', 'consultation', 'penalty', 'refund'

  List<InvoiceReportItem> _invoices = [];
  bool _isLoadingInvoices = true;
  String? _errorMsg;

  List<FinancialTransactionModel> _historyTransactions = [];
  bool _isLoadingHistory = false;
  String? _historyErrorMsg;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    if (_activeTab == 'financial_history') {
      _loadHistory();
    } else {
      _loadInvoices();
    }
  }

  void _loadCurrentView() {
    if (_activeTab == 'financial_history') {
      _loadHistory();
    } else {
      _loadInvoices();
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyErrorMsg = null;
    });

    try {
      final repo = context.read<DashboardRepository>();
      final list = await repo.fetchFinancialHistory(
        type: _selectedHistoryType,
        search: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _historyTransactions = list;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyErrorMsg = e.toString().replaceAll('ApiException: ', '');
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoadingInvoices = true;
      _errorMsg = null;
    });

    try {
      final repo = context.read<DashboardRepository>();
      final list = await repo.fetchInvoices(
        billingQueue: _activeTab == 'billing_queue',
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

  Widget _buildTypeBadge(FinancialTransactionModel tx) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (tx.type) {
      case 'deposit':
        bg = AppColors.tealPrimary.withValues(alpha: 0.12);
        fg = AppColors.tealPrimary;
        icon = Icons.account_balance_wallet_rounded;
        label = context.tr('type_deposit');
        break;
      case 'booking_deduct':
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        icon = Icons.medical_services_rounded;
        label = context.tr('type_consultation');
        break;
      case 'penalty':
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = Colors.orange.shade800;
        icon = Icons.warning_amber_rounded;
        label = context.tr('type_penalty');
        break;
      case 'refund_full':
      case 'refund_partial':
        bg = AppColors.danger.withValues(alpha: 0.12);
        fg = AppColors.danger;
        icon = Icons.replay_rounded;
        label = context.tr('type_refund');
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey.shade700;
        icon = Icons.receipt_long_rounded;
        label = tx.type.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetailsDialog(FinancialTransactionModel tx) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: theme.primaryColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${context.tr('financial_history')} #${tx.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: (tx.type.startsWith('refund') || tx.type == 'deduct')
                          ? AppColors.danger.withValues(alpha: 0.08)
                          : AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          (tx.type.startsWith('refund') || tx.type == 'deduct')
                              ? '-\$${tx.amount.toStringAsFixed(2)}'
                              : '+\$${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: (tx.type.startsWith('refund') || tx.type == 'deduct')
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildTypeBadge(tx),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 28),
                _buildDetailRow(context.tr('created'), tx.createdAt ?? 'N/A'),
                _buildDetailRow(context.tr('patient_name'), tx.patientName),
                if (tx.patientPhone != null && tx.patientPhone!.isNotEmpty)
                  _buildDetailRow(context.tr('phone'), tx.patientPhone!),
                if (tx.doctorName != null && tx.doctorName!.isNotEmpty)
                  _buildDetailRow(context.tr('doctor_name'), tx.doctorName!),
                if (tx.appointmentId != null)
                  _buildDetailRow(context.tr('reference'), 'Appointment #${tx.appointmentId}'),
                _buildDetailRow(
                  context.tr('description'),
                  tx.description ?? 'No description provided.',
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance: \$${tx.balanceBefore.toStringAsFixed(2)}',
                        style: TextStyle(color: theme.hintColor, fontSize: 13),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 14),
                      Text(
                        'New Balance: \$${tx.balanceAfter.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String headerTitle = context.tr('invoices');
    String headerDesc = context.tr('revenue_overview_desc');

    if (_activeTab == 'billing_queue') {
      headerTitle = context.tr('billing_queue');
    } else if (_activeTab == 'financial_history') {
      headerTitle = context.tr('financial_history');
      headerDesc = context.tr('financial_history_desc');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    headerTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    headerDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _loadCurrentView,
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

          // Search & 3-Tab Toggle Bar
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Navigation Segment Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          selected: _activeTab == 'billing_queue',
                          label: Text(context.tr('billing_queue')),
                          avatar: const Icon(Icons.queue, size: 16),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _activeTab = 'billing_queue');
                              _loadInvoices();
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          selected: _activeTab == 'all_invoices',
                          label: Text(context.tr('all_invoices')),
                          avatar: const Icon(Icons.receipt, size: 16),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _activeTab = 'all_invoices');
                              _loadInvoices();
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          selected: _activeTab == 'financial_history',
                          label: Text(context.tr('financial_history')),
                          avatar: const Icon(Icons.history_edu_rounded, size: 16),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _activeTab = 'financial_history');
                              _loadHistory();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // If Financial History tab is active, show category filter pills
                  if (_activeTab == 'financial_history') ...[
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            selected: _selectedHistoryType == 'all',
                            label: Text(context.tr('all_types')),
                            onSelected: (_) {
                              setState(() => _selectedHistoryType = 'all');
                              _loadHistory();
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _selectedHistoryType == 'consultation',
                            label: Text(context.tr('type_consultation')),
                            avatar: const Icon(Icons.medical_services_rounded, size: 14, color: AppColors.success),
                            onSelected: (_) {
                              setState(() => _selectedHistoryType = 'consultation');
                              _loadHistory();
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _selectedHistoryType == 'deposit',
                            label: Text(context.tr('type_deposit')),
                            avatar: const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppColors.tealPrimary),
                            onSelected: (_) {
                              setState(() => _selectedHistoryType = 'deposit');
                              _loadHistory();
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _selectedHistoryType == 'penalty',
                            label: Text(context.tr('type_penalty')),
                            avatar: const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                            onSelected: (_) {
                              setState(() => _selectedHistoryType = 'penalty');
                              _loadHistory();
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _selectedHistoryType == 'refund',
                            label: Text(context.tr('type_refund')),
                            avatar: const Icon(Icons.replay_rounded, size: 14, color: AppColors.danger),
                            onSelected: (_) {
                              setState(() => _selectedHistoryType = 'refund');
                              _loadHistory();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => _loadCurrentView(),
                    decoration: InputDecoration(
                      hintText: _activeTab == 'financial_history'
                          ? context.tr('search_financial_history')
                          : context.tr('search_patients'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadCurrentView();
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

          // Main Table Content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: _activeTab == 'financial_history'
                ? _buildFinancialHistoryTable(context, theme, isDark)
                : _buildInvoicesTable(context, theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTable(BuildContext context, ThemeData theme, bool isDark) {
    if (_isLoadingInvoices) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.tealPrimary)));
    }
    if (_errorMsg != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_errorMsg!, style: const TextStyle(color: AppColors.danger))));
    }
    if (_invoices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            _activeTab == 'billing_queue'
                ? 'No completed visits waiting for payment.'
                : 'No invoices found.',
            style: TextStyle(color: theme.hintColor, fontSize: 15),
          ),
        ),
      );
    }

    return SingleChildScrollView(
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
    );
  }

  Widget _buildFinancialHistoryTable(BuildContext context, ThemeData theme, bool isDark) {
    if (_isLoadingHistory) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.tealPrimary)));
    }
    if (_historyErrorMsg != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_historyErrorMsg!, style: const TextStyle(color: AppColors.danger))));
    }
    if (_historyTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            context.tr('no_financial_transactions'),
            style: TextStyle(color: theme.hintColor, fontSize: 15),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(context.tr('created'))),
          DataColumn(label: Text(context.tr('transaction_type'))),
          DataColumn(label: Text(context.tr('patient_name'))),
          DataColumn(label: Text(context.tr('doctor_staff'))),
          DataColumn(label: Text(context.tr('amount'))),
          DataColumn(label: Text(context.tr('reference'))),
          DataColumn(label: Text(context.tr('description'))),
          DataColumn(label: Text(context.tr('actions'))),
        ],
        rows: _historyTransactions.map((tx) {
          final isDebit = tx.type.startsWith('refund') || tx.type == 'deduct';
          final amountPrefix = isDebit ? '-' : '+';
          final amountColor = isDebit ? AppColors.danger : AppColors.success;

          return DataRow(
            cells: [
              // Date & Time
              DataCell(
                Text(
                  tx.createdAt ?? 'N/A',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),

              // Transaction Type Badge
              DataCell(_buildTypeBadge(tx)),

              // Patient Info
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                      child: ClipOval(
                        child: tx.patientProfilePictureUrl != null
                            ? Image.network(
                                tx.patientProfilePictureUrl!,
                                width: 26,
                                height: 26,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 14, color: theme.primaryColor),
                              )
                            : Icon(Icons.person, size: 14, color: theme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tx.patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Doctor / Staff
              DataCell(
                Text(
                  tx.doctorName ?? '—',
                  style: TextStyle(
                    fontSize: 13,
                    color: tx.doctorName != null ? null : theme.hintColor,
                  ),
                ),
              ),

              // Amount
              DataCell(
                Text(
                  '$amountPrefix\$${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              // Reference
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tx.appointmentId != null ? 'Visit #${tx.appointmentId}' : 'Receipt #${tx.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),

              // Description
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    tx.description ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: theme.hintColor),
                  ),
                ),
              ),

              // Actions (View Details)
              DataCell(
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                  tooltip: 'View Details',
                  onPressed: () => _showTransactionDetailsDialog(tx),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

