import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/reports_models.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_events_states.dart';
import '../widgets/doctor_details_modal.dart';

class DoctorsManagementView extends StatefulWidget {
  const DoctorsManagementView({super.key});

  @override
  State<DoctorsManagementView> createState() => _DoctorsManagementViewState();
}

class _DoctorsManagementViewState extends State<DoctorsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  List<DoctorReportItem> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<DashboardRepository>();
      final list = await repo.fetchDoctorsReport();
      if (mounted) {
        setState(() {
          _doctors = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showAddDoctorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'password123');
    final phoneController = TextEditingController();
    final specController = TextEditingController(text: 'General Practice');
    final feeController = TextEditingController(text: '150.00');
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
                  textDirection: TextDirection.ltr,
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
                  controller: feeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: context.tr('consultation_fee')),
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
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final phone = phoneController.text.trim();
                final spec = specController.text.trim();
                final fee = double.tryParse(feeController.text.trim()) ?? 0.0;
                final bio = bioController.text.trim();

                if (name.isEmpty || email.isEmpty || password.isEmpty || spec.isEmpty) {
                  return;
                }

                try {
                  final repo = context.read<DashboardRepository>();
                  await repo.createDoctor(
                    name: name,
                    email: email,
                    password: password,
                    phone: phone,
                    specialization: spec,
                    consultationFee: fee,
                    bio: bio,
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _loadDoctors();
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: Text(context.tr('add_doctor')),
            ),
          ],
        );
      },
    );
  }

  void _showEditDoctorDialog(DoctorReportItem doctor) {
    final nameController = TextEditingController(text: doctor.doctorName);
    final emailController = TextEditingController(text: doctor.email ?? '');
    final phoneController = TextEditingController(text: doctor.phone ?? '');
    final specController = TextEditingController(text: doctor.specialization);
    final feeController = TextEditingController(text: doctor.consultationFee.toStringAsFixed(2));
    final bioController = TextEditingController(text: doctor.bio ?? '');

    Uint8List? selectedPhotoBytes;
    String? selectedPhotoName;
    bool removePhoto = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final primaryColor = Theme.of(context).primaryColor;
            final currentPicUrl = doctor.profilePictureUrl;
            final hasPictureNow = !removePhoto && (selectedPhotoBytes != null || (currentPicUrl != null && currentPicUrl.isNotEmpty));

            return AlertDialog(
              title: Text(context.tr('edit_doctor')),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile picture section
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  withData: true,
                                );
                                if (result != null && result.files.isNotEmpty) {
                                  final file = result.files.first;
                                  if (file.bytes != null) {
                                    setDialogState(() {
                                      removePhoto = false;
                                      selectedPhotoBytes = file.bytes;
                                      selectedPhotoName = file.name;
                                    });
                                  }
                                }
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                                    backgroundImage: !removePhoto
                                        ? (selectedPhotoBytes != null
                                            ? MemoryImage(selectedPhotoBytes!) as ImageProvider
                                            : (currentPicUrl != null && currentPicUrl.isNotEmpty ? NetworkImage(currentPicUrl) : null))
                                        : null,
                                    child: (!hasPictureNow)
                                        ? Icon(Icons.person, size: 36, color: primaryColor)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
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
                                          removePhoto = false;
                                          selectedPhotoBytes = file.bytes;
                                          selectedPhotoName = file.name;
                                        });
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.photo_camera_outlined, size: 16),
                                  label: Text(
                                    context.tr('choose_photo'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryColor,
                                    side: BorderSide(color: primaryColor),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                ),
                                if (hasPictureNow)
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        removePhoto = true;
                                        selectedPhotoBytes = null;
                                        selectedPhotoName = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                    label: Text(
                                      context.tr('remove_photo'),
                                      style: const TextStyle(color: AppColors.danger, fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    ),
                                  ),
                              ],
                            ),
                            if (selectedPhotoName != null && !removePhoto) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  selectedPhotoName!,
                                  style: TextStyle(fontSize: 11, color: primaryColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: context.tr('doctor_name')),
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
                        controller: specController,
                        decoration: InputDecoration(labelText: context.tr('specialization')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: feeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: context.tr('consultation_fee')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bioController,
                        decoration: InputDecoration(labelText: context.tr('bio')),
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
                          final email = emailController.text.trim();
                          final phone = phoneController.text.trim();
                          final spec = specController.text.trim();
                          final fee = double.tryParse(feeController.text.trim()) ?? doctor.consultationFee;
                          final bio = bioController.text.trim();

                          if (name.isEmpty || email.isEmpty || spec.isEmpty) return;

                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();

                            if (removePhoto && doctor.userId > 0) {
                              await repo.removeStaffProfilePicture(userId: doctor.userId);
                            } else if (selectedPhotoBytes != null && selectedPhotoName != null && doctor.userId > 0) {
                              await repo.updateStaffProfilePicture(
                                userId: doctor.userId,
                                fileBytes: selectedPhotoBytes!,
                                fileName: selectedPhotoName!,
                              );
                            }

                            await repo.updateDoctor(
                              doctor.id,
                              name: name,
                              email: email,
                              phone: phone,
                              specialization: spec,
                              consultationFee: fee,
                              bio: bio,
                            );

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _loadDoctors();
                              context.read<DashboardBloc>().add(RefreshDashboard());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('profile_updated_success')),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('ApiException: ', '')), backgroundColor: AppColors.danger),
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

  void _confirmDeleteDoctor(BuildContext context, DoctorReportItem doctor) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(context.tr('delete_doctor')),
          content: Text(context.tr('delete_doctor_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  final repo = context.read<DashboardRepository>();
                  await repo.deleteDoctor(doctor.id);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                    _loadDoctors();
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  }
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: Text(context.tr('delete')),
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
    final authState = context.watch<AuthBloc>().state;
    final userRole = authState is Authenticated ? authState.user.role : 'admin';
    final isReceptionist = userRole == 'receptionist';

    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredDoctors = searchQuery.isEmpty
        ? _doctors
        : _doctors.where((doc) {
            return doc.doctorName.toLowerCase().contains(searchQuery) ||
                (doc.email != null && doc.email!.toLowerCase().contains(searchQuery)) ||
                doc.specialization.toLowerCase().contains(searchQuery);
          }).toList();

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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadDoctors,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(context.tr('refresh')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                    ),
                  ),
                  if (!isReceptionist)
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
            ],
          ),
          const SizedBox(height: 24),

          // Search Bar
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.tr('search_doctors'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _searchController.clear()),
                        )
                      : null,
                ),
              ),
            ),
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
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger))),
                  )
                else if (filteredDoctors.isEmpty)
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
                        DataColumn(label: Text(context.tr('email'))),
                        DataColumn(label: Text(context.tr('specialization'))),
                        DataColumn(label: Text(context.tr('consultation_fee'))),
                        DataColumn(label: Text(context.tr('total_appointments'))),
                        DataColumn(label: Text(context.tr('completed_appointments'))),
                        DataColumn(label: Text(context.tr('cancelled_appointments'))),
                        DataColumn(label: Text(context.tr('total_revenue'))),
                        DataColumn(label: Text(context.tr('actions'))),
                      ],
                      rows: filteredDoctors.map((doc) {
                        return DataRow(cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                                  child: ClipOval(
                                    child: doc.profilePictureUrl != null
                                        ? Image.network(
                                            doc.profilePictureUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: theme.primaryColor),
                                          )
                                        : Icon(Icons.person, color: theme.primaryColor),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  doc.doctorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(doc.email ?? '-')),
                          DataCell(Text(doc.specialization)),
                          DataCell(Text('\$${doc.consultationFee.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('${doc.totalAppointments}')),
                          DataCell(Text('${doc.completed}',
                              style: const TextStyle(
                                  color: AppColors.success, fontWeight: FontWeight.bold))),
                          DataCell(Text('${doc.cancelled}', style: const TextStyle(color: AppColors.danger))),
                          DataCell(Text('\$${doc.revenue.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: theme.primaryColor, fontWeight: FontWeight.bold))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => DoctorDetailsModal.show(context, doc, isReadOnly: isReceptionist),
                                  icon: const Icon(Icons.calendar_month_outlined, size: 16),
                                  label: Text(context.tr('working_schedule')),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.primaryColor,
                                    side: BorderSide(color: theme.primaryColor),
                                  ),
                                ),
                                if (!isReceptionist) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, color: theme.primaryColor),
                                    tooltip: context.tr('edit_doctor'),
                                    onPressed: () => _showEditDoctorDialog(doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                    tooltip: context.tr('delete_doctor'),
                                    onPressed: () => _confirmDeleteDoctor(context, doc),
                                  ),
                                ],
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
        ],
      ),
    );
  }
}
