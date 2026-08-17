import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exceptions.dart';
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
    final amountController = TextEditingController(text: '100.0');
    bool isDeduct = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return AlertDialog(
              title: Text(isDeduct ? 'Deduct from Patient Wallet' : context.tr('deposit_to_patient_wallet')),
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
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Add Funds (+)')),
                            selected: !isDeduct,
                            selectedColor: AppColors.success.withValues(alpha: 0.2),
                            onSelected: (_) => setDialogState(() => isDeduct = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Deduct (-)')),
                            selected: isDeduct,
                            selectedColor: AppColors.danger.withValues(alpha: 0.2),
                            onSelected: (_) => setDialogState(() => isDeduct = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: isDeduct ? 'Deduction Amount (\$)' : context.tr('deposit_amount'),
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
                    backgroundColor: isDeduct ? AppColors.danger : theme.primaryColor,
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
                            if (isDeduct) {
                              await repo.deductWallet(patient.id, amt);
                            } else {
                              await repo.depositWallet(patient.id, amt);
                            }

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isDeduct ? 'Wallet balance deducted successfully!' : context.tr('deposit_success')),
                                  backgroundColor: isDeduct ? AppColors.info : AppColors.success,
                                ),
                              );
                              _loadPatients();
                              context.read<DashboardBloc>().add(RefreshDashboard());
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
                      : Text(isDeduct ? 'Deduct Funds' : context.tr('deposit')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRegisterPatientDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isStaffOverride = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return AlertDialog(
              title: Text(context.tr('register_patient')),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: context.tr('full_name')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: context.tr('email')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: context.tr('phone')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: context.tr('password')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: context.tr('confirm_password')),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isStaffOverride,
                                  onChanged: (val) {
                                    setDialogState(() => isStaffOverride = val ?? false);
                                  },
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(() => isStaffOverride = !isStaffOverride);
                                    },
                                    child: Text(
                                      context.tr('staff_override_notice'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 36.0, right: 8.0),
                              child: Text(
                                'Bypass email OTP verification after verifying patient identity in-person.',
                                style: TextStyle(fontSize: 11, color: theme.hintColor),
                              ),
                            ),
                          ],
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
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final phone = phoneController.text.trim();
                          final pass = passwordController.text.trim();
                          final confirmPass = confirmPasswordController.text.trim();

                          if (name.isEmpty || email.isEmpty || pass.isEmpty) return;

                          if (pass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('passwords_do_not_match')),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();
                            final res = await repo.registerPatient(
                              name: name,
                              email: email,
                              phone: phone,
                              password: pass,
                              passwordConfirmation: confirmPass,
                              staffOverride: isStaffOverride,
                            );

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              if (res['requires_otp'] == true) {
                                _showRegistrationOtpDialog(email);
                              } else {
                                _loadPatients();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('patient_registered_verified_success')),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
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
                      : Text(context.tr('register_patient')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRegistrationOtpDialog(String email) {
    final otpController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text(context.tr('enter_email_otp')),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('otp_sent_notice')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '6-Digit OTP Code',
                        hintText: '123456',
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
                          final otpCode = otpController.text.trim();
                          if (otpCode.length != 6) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();
                            await repo.verifyOtp(email, otpCode);
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _loadPatients();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('patient_registered_verified_success')),
                                  backgroundColor: AppColors.success,
                                ),
                              );
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
                      : Text(context.tr('verify_and_save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOtpVerificationDialog(int patientId, String name, String email, String phone) {
    final otpController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text(context.tr('enter_email_otp')),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('otp_sent_notice')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '6-Digit OTP Code',
                        hintText: '123456',
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
                          final otpCode = otpController.text.trim();
                          if (otpCode.length != 6) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();
                            await repo.updatePatient(
                              id: patientId,
                              name: name,
                              email: email,
                              phone: phone,
                              otp: otpCode,
                            );
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _loadPatients();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('patient_email_verified_success')),
                                  backgroundColor: AppColors.success,
                                ),
                              );
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
                      : Text(context.tr('verify_and_save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPatientDialog(PatientReportItem patient) {
    final nameController = TextEditingController(text: patient.patientName);
    final emailController = TextEditingController(text: patient.email);
    final phoneController = TextEditingController(text: patient.phone);
    bool isStaffOverride = false;
    bool isSubmitting = false;
    Uint8List? selectedPhotoBytes;
    String? selectedPhotoName;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final primaryColor = theme.primaryColor;
            final emailChanged = emailController.text.trim().toLowerCase() != patient.email.toLowerCase();

            return AlertDialog(
              title: Text(context.tr('edit_patient')),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile picture section
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: primaryColor.withValues(alpha: 0.15),
                              backgroundImage: selectedPhotoBytes != null
                                  ? MemoryImage(selectedPhotoBytes!) as ImageProvider
                                  : (patient.profilePictureUrl != null ? NetworkImage(patient.profilePictureUrl!) : null),
                              child: (selectedPhotoBytes == null && patient.profilePictureUrl == null)
                                  ? Icon(Icons.person, size: 36, color: primaryColor)
                                  : null,
                            ),
                            const SizedBox(height: 8),
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
                                      selectedPhotoBytes = file.bytes;
                                      selectedPhotoName = file.name;
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.photo_camera_outlined, size: 16),
                              label: Text(
                                selectedPhotoName ?? context.tr('choose_photo_device'),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: context.tr('patient_name')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        onChanged: (_) => setDialogState(() {}),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: context.tr('email')),
                      ),
                      if (emailChanged) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            context.tr('staff_override_notice'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          value: isStaffOverride,
                          onChanged: (val) => setDialogState(() => isStaffOverride = val ?? false),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: context.tr('phone')),
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
                          final name = nameController.text.trim();
                          final newEmail = emailController.text.trim();
                          final phone = phoneController.text.trim();

                          if (name.isEmpty || newEmail.isEmpty) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();

                            // Upload profile picture first if selected
                            if (selectedPhotoBytes != null && selectedPhotoName != null) {
                              await repo.updatePatientProfilePicture(
                                patientId: patient.id,
                                fileBytes: selectedPhotoBytes!,
                                fileName: selectedPhotoName!,
                              );
                            }

                            final res = await repo.updatePatient(
                              id: patient.id,
                              name: name,
                              email: newEmail,
                              phone: phone,
                              staffOverride: isStaffOverride,
                            );

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              if (res['requires_otp'] == true) {
                                _showOtpVerificationDialog(patient.id, name, newEmail, phone);
                              } else {
                                _loadPatients();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('patient_updated_success')),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
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

  void _showPatientProfileModal(PatientReportItem patient) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                child: ClipOval(
                  child: patient.profilePictureUrl != null
                      ? Image.network(
                          patient.profilePictureUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 22, color: theme.primaryColor),
                        )
                      : Icon(Icons.person, size: 22, color: theme.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(patient.email, style: TextStyle(fontSize: 12, color: theme.hintColor)),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: MediaQuery.of(context).size.height * 0.65,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: context.read<DashboardRepository>().fetchPatientTransactions(patient.id),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final txs = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${context.tr('wallet_balance')}: \$${patient.walletBalance.toStringAsFixed(2)}',
                            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              _showDepositDialog(patient);
                            },
                            icon: const Icon(Icons.add_card, size: 16),
                            label: Text(context.tr('deposit_wallet')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(context.tr('transaction_history'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: txs.isEmpty
                          ? Center(child: Text(context.tr('no_transactions')))
                          : ListView.builder(
                              itemCount: txs.length,
                              itemBuilder: (context, index) {
                                final tx = txs[index];
                                final isDeposit = tx['type'] == 'deposit';
                                final rawAmt = tx['amount'];
                                final amt = rawAmt == null
                                    ? 0.0
                                    : (rawAmt is num
                                        ? rawAmt.toDouble()
                                        : double.tryParse(rawAmt.toString()) ?? 0.0);

                                final rawDate = (tx['created_at'] ?? '').toString();
                                final formattedDate = rawDate.contains('T')
                                    ? rawDate.split('T').first
                                    : (rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate);

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                                  child: ListTile(
                                    leading: Icon(
                                      isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isDeposit ? AppColors.success : AppColors.danger,
                                    ),
                                    title: Text(
                                      '${isDeposit ? '+' : '-'}\$${amt.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDeposit ? AppColors.success : AppColors.danger,
                                      ),
                                    ),
                                    subtitle: Text(tx['description'] ?? tx['type'] ?? ''),
                                    trailing: Text(
                                      formattedDate,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(context.tr('close')),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _loadPatients(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(context.tr('refresh')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showRegisterPatientDialog,
                    icon: const Icon(Icons.person_add),
                    label: Text(context.tr('register_patient')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
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
                                    child: ClipOval(
                                      child: patient.profilePictureUrl != null
                                          ? Image.network(
                                              patient.profilePictureUrl!,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 18, color: theme.primaryColor),
                                            )
                                          : Icon(Icons.person, size: 18, color: theme.primaryColor),
                                    ),
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.account_box, color: theme.primaryColor),
                                    tooltip: 'View Profile & History',
                                    onPressed: () => _showPatientProfileModal(patient),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.info),
                                    tooltip: 'Edit Patient',
                                    onPressed: () => _showEditPatientDialog(patient),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showDepositDialog(patient),
                                    icon: const Icon(Icons.add_card, size: 16),
                                    label: Text(context.tr('deposit_wallet')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
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
