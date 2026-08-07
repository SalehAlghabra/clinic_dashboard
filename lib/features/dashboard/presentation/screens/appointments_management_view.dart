import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_events_states.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_events_states.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/reports_models.dart';
import '../widgets/searchable_dropdown_field.dart';

class AppointmentsManagementView extends StatefulWidget {
  const AppointmentsManagementView({super.key});

  @override
  State<AppointmentsManagementView> createState() => _AppointmentsManagementViewState();
}

class _AppointmentsManagementViewState extends State<AppointmentsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  List<AppointmentReportItem> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<DashboardRepository>();
      final list = await repo.fetchAppointmentsReport();
      setState(() {
        _appointments = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showBookForPatientDialog() {
    int? selectedPatientId;
    int? selectedDoctorId;
    DateTime selectedDate = DateTime.now();
    String? selectedSlot;
    Set<String> workingDays = {};
    final notesController = TextEditingController();

    List<PatientReportItem> patients = [];
    List<DoctorReportItem> doctors = [];
    List<String> availableSlots = [];
    bool loadingPatients = true;
    bool loadingSlots = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final repo = context.read<DashboardRepository>();

            if (patients.isEmpty && loadingPatients) {
              Future.microtask(() async {
                final pts = await repo.fetchPatientsReport();
                final docs = await repo.fetchDoctorsReport();
                setDialogState(() {
                  patients = pts;
                  doctors = docs;
                  loadingPatients = false;
                });
              });
            }

            Future<void> onDoctorSelected(int docId) async {
              setDialogState(() {
                selectedDoctorId = docId;
                loadingSlots = true;
                availableSlots = [];
                selectedSlot = null;
                workingDays = {};
              });

              try {
                final schedules = await repo.fetchDoctorSchedules(docId);
                final days = schedules.map((s) => s.dayOfWeek.toLowerCase()).toSet();

                DateTime targetDate = DateTime.now();
                if (days.isNotEmpty) {
                  for (int i = 0; i < 90; i++) {
                    final checkDate = DateTime.now().add(Duration(days: i));
                    final dayName = DateFormat('EEEE').format(checkDate).toLowerCase();
                    if (days.contains(dayName)) {
                      targetDate = checkDate;
                      break;
                    }
                  }
                }

                final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
                final slots = await repo.fetchAvailableSlots(docId, dateStr);

                setDialogState(() {
                  workingDays = days;
                  selectedDate = targetDate;
                  availableSlots = slots;
                  loadingSlots = false;
                });
              } catch (_) {
                setDialogState(() => loadingSlots = false);
              }
            }

            Future<void> loadSlotsForDate(int docId, DateTime dt) async {
              setDialogState(() {
                loadingSlots = true;
                availableSlots = [];
                selectedSlot = null;
              });
              try {
                final dateStr = DateFormat('yyyy-MM-dd').format(dt);
                final slots = await repo.fetchAvailableSlots(docId, dateStr);
                setDialogState(() {
                  availableSlots = slots;
                  loadingSlots = false;
                });
              } catch (_) {
                setDialogState(() => loadingSlots = false);
              }
            }

            return AlertDialog(
              title: Text(context.tr('book_for_patient')),
              content: SizedBox(
                width: 480,
                child: loadingPatients
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SearchableDropdownField<int>(
                              value: selectedPatientId,
                              labelText: context.tr('patient_name'),
                              hintText: context.tr('search_patients'),
                              items: patients.map((p) {
                                return DropdownItem<int>(
                                  value: p.id,
                                  label: p.patientName,
                                  subtitle: p.phone.isNotEmpty ? p.phone : p.email,
                                );
                              }).toList(),
                              onChanged: (val) => setDialogState(() => selectedPatientId = val),
                            ),
                            const SizedBox(height: 12),
                            SearchableDropdownField<int>(
                              value: selectedDoctorId,
                              labelText: context.tr('doctor_name'),
                              hintText: context.tr('search_by_doctor_name_specialization'),
                              items: doctors.map((d) {
                                return DropdownItem<int>(
                                  value: d.id,
                                  label: d.doctorName,
                                  subtitle: '${d.specialization} — \$${d.consultationFee.toStringAsFixed(2)}',
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  onDoctorSelected(val);
                                } else {
                                  setDialogState(() {
                                    selectedDoctorId = null;
                                    availableSlots = [];
                                    selectedSlot = null;
                                    workingDays = {};
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedDoctorId == null
                                        ? '${context.tr('appointment_date')}: —'
                                        : '${context.tr('appointment_date')}: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: selectedDoctorId == null
                                      ? null
                                      : () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(const Duration(days: 90)),
                                            selectableDayPredicate: (DateTime day) {
                                              if (workingDays.isEmpty) return true;
                                              final dayName = DateFormat('EEEE').format(day).toLowerCase();
                                              return workingDays.contains(dayName);
                                            },
                                          );
                                          if (picked != null) {
                                            setDialogState(() => selectedDate = picked);
                                            loadSlotsForDate(selectedDoctorId!, picked);
                                          }
                                        },
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text(context.tr('select_date')),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (selectedDoctorId == null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Please select a doctor to view working dates & time slots.',
                                  style: TextStyle(fontSize: 12, color: theme.hintColor, fontStyle: FontStyle.italic),
                                ),
                              )
                            else if (loadingSlots)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (availableSlots.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(context.tr('no_available_slots'), style: const TextStyle(color: AppColors.danger)),
                              )
                            else
                              DropdownButtonFormField<String>(
                                initialValue: selectedSlot,
                                decoration: const InputDecoration(labelText: 'Available Time Slot'),
                                items: availableSlots.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s,
                                    child: Text(s),
                                  );
                                }).toList(),
                                onChanged: (val) => setDialogState(() => selectedSlot = val),
                              ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: notesController,
                              decoration: InputDecoration(labelText: context.tr('additional_note')),
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
                  onPressed: (isSubmitting || selectedPatientId == null || selectedDoctorId == null || selectedSlot == null)
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await repo.bookAppointment(
                              patientId: selectedPatientId!,
                              doctorId: selectedDoctorId!,
                              date: DateFormat('yyyy-MM-dd').format(selectedDate),
                              time: selectedSlot!,
                              notes: notesController.text.trim(),
                            );
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _loadAppointments();
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
                      : Text(context.tr('book_for_patient')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRescheduleDialog(AppointmentReportItem appt) {
    DateTime selectedDate = DateTime.now();
    try {
      selectedDate = DateTime.parse(appt.appointmentDate);
    } catch (_) {}

    String? selectedSlot;
    List<String> availableSlots = [];
    Set<String> workingDays = {};
    bool loadingSlots = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final repo = context.read<DashboardRepository>();

            Future<void> loadSlots(DateTime dt) async {
              setDialogState(() {
                loadingSlots = true;
                availableSlots = [];
                selectedSlot = null;
              });
              try {
                if (workingDays.isEmpty) {
                  final schedules = await repo.fetchDoctorSchedules(appt.doctorId);
                  workingDays = schedules.map((s) => s.dayOfWeek.toLowerCase()).toSet();
                }
                final dateStr = DateFormat('yyyy-MM-dd').format(dt);
                final slots = await repo.fetchAvailableSlots(appt.doctorId, dateStr);
                setDialogState(() {
                  availableSlots = slots;
                  loadingSlots = false;
                });
              } catch (_) {
                setDialogState(() => loadingSlots = false);
              }
            }

            if (availableSlots.isEmpty && !loadingSlots) {
              Future.microtask(() => loadSlots(selectedDate));
            }

            return AlertDialog(
              title: Text(context.tr('reschedule_appointment')),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient: ${appt.patientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Doctor: ${appt.doctorName}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                              selectableDayPredicate: (DateTime day) {
                                if (workingDays.isEmpty) return true;
                                final dayName = DateFormat('EEEE').format(day).toLowerCase();
                                return workingDays.contains(dayName);
                              },
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                              loadSlots(picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: Text(context.tr('select_date')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (loadingSlots)
                      const Center(child: CircularProgressIndicator())
                    else if (availableSlots.isEmpty)
                      const Text('No available time slots on this date.', style: TextStyle(color: AppColors.danger))
                    else
                      DropdownButtonFormField<String>(
                        initialValue: selectedSlot,
                        decoration: const InputDecoration(labelText: 'New Time Slot'),
                        items: availableSlots.map((s) {
                          return DropdownMenuItem<String>(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedSlot = val),
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
                  onPressed: (isSubmitting || selectedSlot == null)
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await repo.rescheduleAppointment(
                              appointmentId: appt.id,
                              date: DateFormat('yyyy-MM-dd').format(selectedDate),
                              time: selectedSlot!,
                            );
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _loadAppointments();
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
                      : Text(context.tr('reschedule_appointment')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCancelDialog(AppointmentReportItem appt) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.tr('cancel_appointment')),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${context.tr("appointment")} #${appt.id} - ${appt.patientName}'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(labelText: 'Cancellation Reason (Optional)'),
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
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            final repo = context.read<DashboardRepository>();
                            await repo.cancelAppointment(appt.id, reason: reasonController.text.trim());
                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              _loadAppointments();
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
                      : Text(context.tr('confirm_cancellation')),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
                      SnackBar(
                        content: Text(context.tr('appointment_completed_success')),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _loadAppointments();
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  }
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(parseErrorMessage(e)), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: Text(context.tr('complete_and_invoice')),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(String dateStr, String timeStr) {
    try {
      final parsedDate = DateTime.parse(dateStr);
      final formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);

      final timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final tempTime = DateTime(2026, 1, 1, hour, minute);
        final formattedTime = DateFormat('hh:mm a').format(tempTime);
        return '$formattedDate  •  $formattedTime';
      }
      return '$formattedDate  •  $timeStr';
    } catch (_) {
      return '$dateStr $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    final userRole = authState is Authenticated ? authState.user.role : 'admin';
    final isDoctor = userRole == 'doctor';

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final searchQuery = _searchController.text.trim().toLowerCase();

    final filteredAppointments = _appointments.where((appt) {
      if (_selectedFilter == 'today' && appt.appointmentDate != todayStr) return false;
      if (_selectedFilter == 'pending' && appt.status != 'pending') return false;
      if (_selectedFilter == 'confirmed' && appt.status != 'confirmed') return false;
      if (_selectedFilter == 'completed' && appt.status != 'completed') return false;
      if (_selectedFilter == 'cancelled' && appt.status != 'cancelled') return false;

      if (searchQuery.isNotEmpty) {
        final matchesPatient = appt.patientName.toLowerCase().contains(searchQuery);
        final matchesDoctor = appt.doctorName.toLowerCase().contains(searchQuery);
        final matchesDate = appt.appointmentDate.toLowerCase().contains(searchQuery);
        final matchesStatus = appt.status.toLowerCase().contains(searchQuery);
        return matchesPatient || matchesDoctor || matchesDate || matchesStatus;
      }

      return true;
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
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadAppointments,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(context.tr('refresh')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showBookForPatientDialog,
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('book_for_patient')),
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

          // Search & Filter Card
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
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: context.tr('search_appointments'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchController.clear()),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _selectedFilter == 'all',
                          label: Text(context.tr('filter_all')),
                          onSelected: (_) => setState(() => _selectedFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _selectedFilter == 'today',
                          label: Text(context.tr('todays_appointments')),
                          avatar: const Icon(Icons.today, size: 16),
                          onSelected: (_) => setState(() => _selectedFilter = 'today'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _selectedFilter == 'pending',
                          label: Text(context.tr('filter_pending')),
                          onSelected: (_) => setState(() => _selectedFilter = 'pending'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _selectedFilter == 'confirmed',
                          label: Text(context.tr('filter_confirmed')),
                          onSelected: (_) => setState(() => _selectedFilter = 'confirmed'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _selectedFilter == 'completed',
                          label: Text(context.tr('filter_completed')),
                          onSelected: (_) => setState(() => _selectedFilter = 'completed'),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _selectedFilter == 'cancelled',
                          label: Text(context.tr('filter_cancelled')),
                          onSelected: (_) => setState(() => _selectedFilter = 'cancelled'),
                        ),
                      ],
                    ),
                  ),
                ],
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
                else if (filteredAppointments.isEmpty)
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
                        DataColumn(label: Text(context.tr('date_time'))),
                        DataColumn(label: Text(context.tr('status'))),
                        DataColumn(label: Text(context.tr('actions'))),
                      ],
                      rows: filteredAppointments.map((appt) {
                        Color statusColor = AppColors.warning;
                        if (appt.status == 'completed') statusColor = AppColors.success;
                        if (appt.status == 'confirmed') statusColor = AppColors.info;
                        if (appt.status == 'cancelled') statusColor = AppColors.danger;

                        final isReceptionist = userRole == 'receptionist';
                        final canModify = appt.status == 'pending' || appt.status == 'confirmed';
                        final canRescheduleOrCancel = appt.status == 'pending' || (!isReceptionist && appt.status == 'confirmed');

                        return DataRow(cells: [
                           DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
                                  child: ClipOval(
                                    child: appt.patientProfilePictureUrl != null
                                        ? Image.network(
                                            appt.patientProfilePictureUrl!,
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.person, size: 16, color: theme.primaryColor),
                                          )
                                        : Icon(Icons.person, size: 16, color: theme.primaryColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          DataCell(Text(appt.doctorName)),
                          DataCell(Text('\$${appt.consultationFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('\$${appt.additionalCost.toStringAsFixed(2)}')),
                          DataCell(Text(_formatDateTime(appt.appointmentDate, appt.appointmentTime))),
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canRescheduleOrCancel) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_calendar, color: AppColors.info),
                                    tooltip: 'Reschedule',
                                    onPressed: () => _showRescheduleDialog(appt),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
                                    tooltip: 'Cancel',
                                    onPressed: () => _showCancelDialog(appt),
                                  ),
                                ],
                                if (isDoctor && canModify) ...[
                                  ElevatedButton(
                                    onPressed: () => _showCompleteDialog(context, appt),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    child: Text(context.tr('complete_visit')),
                                  ),
                                ],
                                if (!canModify) const Text('-'),
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
