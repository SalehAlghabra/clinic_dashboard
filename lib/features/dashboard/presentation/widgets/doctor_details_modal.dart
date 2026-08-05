import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/doctor_schedule_model.dart';
import '../../data/models/reports_models.dart';
import '../../data/repositories/dashboard_repository.dart';

class DoctorDetailsModal extends StatefulWidget {
  final DoctorReportItem doctor;

  const DoctorDetailsModal({super.key, required this.doctor});

  static Future<void> show(BuildContext context, DoctorReportItem doctor) {
    return showDialog(
      context: context,
      builder: (dialogContext) => DoctorDetailsModal(doctor: doctor),
    );
  }

  @override
  State<DoctorDetailsModal> createState() => _DoctorDetailsModalState();
}

class _DoctorDetailsModalState extends State<DoctorDetailsModal> {
  bool _isLoading = true;
  String? _errorMessage;

  List<DoctorSchedule> _schedules = [];

  // Add Schedule Controllers
  String _selectedDay = 'monday';
  final _startTimeController = TextEditingController(text: '09:00');
  final _endTimeController = TextEditingController(text: '17:00');
  final _durationController = TextEditingController(text: '30');

  // Edit Doctor Controllers
  late TextEditingController _feeController;
  late TextEditingController _specController;

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  @override
  void initState() {
    super.initState();
    _feeController = TextEditingController(text: widget.doctor.consultationFee.toStringAsFixed(2));
    _specController = TextEditingController(text: widget.doctor.specialization);
    _loadData();
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _durationController.dispose();
    _feeController.dispose();
    _specController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<DashboardRepository>();
      final schedules = await repo.fetchDoctorSchedules(widget.doctor.id);

      if (mounted) {
        setState(() {
          _schedules = schedules;
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

  Future<void> _updateDoctorInfo() async {
    try {
      final repo = context.read<DashboardRepository>();
      final fee = double.tryParse(_feeController.text.trim()) ?? widget.doctor.consultationFee;
      await repo.updateDoctor(
        widget.doctor.id,
        specialization: _specController.text.trim(),
        consultationFee: fee,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor details updated!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: ${e.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _addSchedule() async {
    final start = _startTimeController.text.trim();
    final end = _endTimeController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;

    try {
      final repo = context.read<DashboardRepository>();
      await repo.addDoctorSchedule(widget.doctor.id, _selectedDay, start, end, duration);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule added successfully!'), backgroundColor: AppColors.success),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _deleteSchedule(int scheduleId) async {
    try {
      final repo = context.read<DashboardRepository>();
      await repo.deleteDoctorSchedule(widget.doctor.id, scheduleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule removed.'), backgroundColor: AppColors.info),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withValues(alpha: 0.15),
            backgroundImage: widget.doctor.profilePictureUrl != null ? NetworkImage(widget.doctor.profilePictureUrl!) : null,
            child: widget.doctor.profilePictureUrl == null ? Icon(Icons.person, color: primaryColor) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.doctor.doctorName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(widget.doctor.specialization, style: theme.textTheme.bodyMedium?.copyWith(color: primaryColor)),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Edit Details Section
              Text(context.tr('schedule_and_details'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _specController,
                      decoration: InputDecoration(labelText: context.tr('specialization')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _feeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: context.tr('consultation_fee')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _updateDoctorInfo,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                    child: Text(context.tr('save_changes')),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Doctor Working Schedule Section
              Text(context.tr('working_schedule'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_schedules.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(context.tr('no_schedule_configured'), style: const TextStyle(fontStyle: FontStyle.italic)),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _schedules.length,
                                itemBuilder: (context, index) {
                                  final sch = _schedules[index];
                                  return Card(
                                    color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: Icon(Icons.access_time, color: primaryColor),
                                      title: Text(sch.dayOfWeek.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${sch.startTime} - ${sch.endTime} (${sch.durationPerPatient} ${context.tr('duration_mins')})'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                        onPressed: () => _deleteSchedule(sch.id),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 16),
                            Text(context.tr('add_schedule_day'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedDay,
                                    decoration: InputDecoration(labelText: context.tr('day_of_week')),
                                    items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d.toUpperCase()))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedDay = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _startTimeController,
                                    decoration: InputDecoration(labelText: context.tr('start_time'), hintText: '09:00'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _endTimeController,
                                    decoration: InputDecoration(labelText: context.tr('end_time'), hintText: '17:00'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: context.tr('duration_mins')),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _addSchedule,
                                icon: const Icon(Icons.add),
                                label: Text(context.tr('add_day_schedule')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('close')),
        ),
      ],
    );
  }
}
