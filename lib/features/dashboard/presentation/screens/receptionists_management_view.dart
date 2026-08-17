import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/reports_models.dart';
import '../../data/repositories/dashboard_repository.dart';

class ReceptionistsManagementView extends StatefulWidget {
  const ReceptionistsManagementView({super.key});

  @override
  State<ReceptionistsManagementView> createState() => _ReceptionistsManagementViewState();
}

class _ReceptionistsManagementViewState extends State<ReceptionistsManagementView> {
  List<Map<String, dynamic>> _receptionists = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReceptionists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReceptionists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = context.read<DashboardRepository>();
      final list = await repo.fetchReceptionists();
      if (mounted) {
        setState(() {
          _receptionists = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = parseErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _showAddReceptionistDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'password123');
    final phoneController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text(context.tr('add_receptionist')),
              content: SizedBox(
                width: 400,
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
                        controller: passwordController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(labelText: context.tr('password')),
                      ),
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
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();
                          final phone = phoneController.text.trim();
                          if (name.isEmpty || email.isEmpty || password.isEmpty) return;

                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();
                            await repo.createReceptionist(
                              name: name,
                              email: email,
                              password: password,
                              phone: phone,
                            );
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _loadReceptionists();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('receptionist_created_success')),
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
                      : Text(context.tr('create_account')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteReceptionist(Map<String, dynamic> receptionist) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(context.tr('delete_receptionist')),
          content: Text('Are you sure you want to delete "${receptionist['name']}"? This action cannot be undone.'),
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
                  await repo.deleteStaff(receptionist['id'] as int);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                    _loadReceptionists();
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(
                        content: Text(dialogCtx.tr('receptionist_deleted_success')),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(content: Text(parseErrorMessage(e)), backgroundColor: AppColors.danger),
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

  void _showEditReceptionistDialog(Map<String, dynamic> receptionist) {
    final id = receptionist['id'] as int? ?? 0;
    final initialName = (receptionist['name'] ?? '').toString();
    final initialEmail = (receptionist['email'] ?? '').toString();
    final initialPhone = (receptionist['phone'] ?? '').toString();
    final currentPicUrl = parseProfilePictureUrl(receptionist['profile_picture_url'], receptionist['profile_picture']);

    final nameController = TextEditingController(text: initialName);
    final emailController = TextEditingController(text: initialEmail);
    final phoneController = TextEditingController(text: initialPhone);

    Uint8List? selectedPhotoBytes;
    String? selectedPhotoName;
    bool isStaffOverride = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final primaryColor = Theme.of(context).primaryColor;
            final emailChanged = emailController.text.trim().toLowerCase() != initialEmail.toLowerCase();

            return AlertDialog(
              title: Text(context.tr('edit_receptionist')),
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
                                  : (currentPicUrl != null ? NetworkImage(currentPicUrl) : null),
                              child: (selectedPhotoBytes == null && currentPicUrl == null)
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
                        decoration: InputDecoration(labelText: context.tr('full_name')),
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

                            if (selectedPhotoBytes != null && selectedPhotoName != null) {
                              await repo.updateStaffProfilePicture(
                                userId: id,
                                fileBytes: selectedPhotoBytes!,
                                fileName: selectedPhotoName!,
                              );
                            }

                            await repo.updateStaff(
                              id: id,
                              name: name,
                              email: newEmail,
                              phone: phone,
                              staffOverride: isStaffOverride,
                            );

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _loadReceptionists();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('receptionist_updated_success')),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
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

  void _showUpdateProfilePictureDialog(Map<String, dynamic> receptionist) {
    Uint8List? selectedBytes;
    String? selectedFileName;
    bool isSubmitting = false;
    final userId = receptionist['id'] as int? ?? 0;
    final currentPicUrl = receptionist['profile_picture_url'] as String?;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final primaryColor = Theme.of(context).primaryColor;
            return AlertDialog(
              title: Text(context.tr('update_profile_picture')),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: primaryColor.withValues(alpha: 0.15),
                      backgroundImage: selectedBytes != null
                          ? MemoryImage(selectedBytes!) as ImageProvider
                          : (currentPicUrl != null ? NetworkImage(currentPicUrl) : null),
                      child: (selectedBytes == null && currentPicUrl == null)
                          ? Icon(Icons.person, size: 44, color: primaryColor)
                          : null,
                    ),
                    const SizedBox(height: 16),
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
                              selectedBytes = file.bytes;
                              selectedFileName = file.name;
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                        selectedFileName ?? context.tr('choose_photo_device'),
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
                  onPressed: (isSubmitting || selectedBytes == null)
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();
                            await repo.updateStaffProfilePicture(
                              userId: userId,
                              fileBytes: selectedBytes!,
                              fileName: selectedFileName!,
                            );
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _loadReceptionists();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('profile_picture_updated')),
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
                      : Text(context.tr('save_changes')),
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

    final searchQuery = _searchController.text.trim().toLowerCase();
    final filtered = searchQuery.isEmpty
        ? _receptionists
        : _receptionists.where((r) {
            final name = (r['name'] ?? '').toString().toLowerCase();
            final email = (r['email'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) || email.contains(searchQuery);
          }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    context.tr('receptionists'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('manage_receptionists'),
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
                    onPressed: _loadReceptionists,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(context.tr('refresh')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddReceptionistDialog,
                    icon: const Icon(Icons.person_add),
                    label: Text(context.tr('add_receptionist')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search bar
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
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.tr('search_by_name_email'),
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

          // Table
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                        child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    )
                  else if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: Text(context.tr('no_receptionists_found'))),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(context.tr('full_name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.tr('email'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.tr('phone'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.tr('created'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(context.tr('actions'), style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((r) {
                          final profilePictureUrl = parseProfilePictureUrl(r['profile_picture_url'], r['profile_picture']);

                          return DataRow(cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                                    child: ClipOval(
                                      child: (profilePictureUrl != null)
                                          ? Image.network(
                                              profilePictureUrl,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, e, st) => Icon(Icons.person, size: 18, color: theme.primaryColor),
                                            )
                                          : Icon(Icons.person, size: 18, color: theme.primaryColor),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(r['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DataCell(Text(r['email']?.toString() ?? '')),
                            DataCell(Text(r['phone']?.toString().isNotEmpty == true ? r['phone'].toString() : '-')),
                            DataCell(Text(r['created_at']?.toString() ?? '-')),
                             DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.info),
                                    tooltip: context.tr('edit_receptionist'),
                                    onPressed: () => _showEditReceptionistDialog(r),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.photo_camera_outlined, color: theme.primaryColor),
                                    tooltip: context.tr('update_profile_picture'),
                                    onPressed: () => _showUpdateProfilePictureDialog(r),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                    tooltip: context.tr('delete'),
                                    onPressed: () => _confirmDeleteReceptionist(r),
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
