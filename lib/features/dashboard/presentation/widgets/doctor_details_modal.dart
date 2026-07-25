import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/doctor_schedule_model.dart';
import '../../data/models/doctor_service_model.dart';
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

class _DoctorDetailsModalState extends State<DoctorDetailsModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<DoctorSchedule> _schedules = [];
  List<DoctorService> _services = [];

  // Add Schedule Controllers
  String _selectedDay = 'monday';
  final _startTimeController = TextEditingController(text: '09:00');
  final _endTimeController = TextEditingController(text: '17:00');
  final _durationController = TextEditingController(text: '30');

  // Add Service Controllers
  final _serviceNameController = TextEditingController();
  final _servicePriceController = TextEditingController(text: '50.0');

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
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _durationController.dispose();
    _serviceNameController.dispose();
    _servicePriceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<DashboardRepository>();
      final results = await Future.wait([
        repo.fetchDoctorSchedules(widget.doctor.id),
        repo.fetchDoctorServices(widget.doctor.id),
      ]);

      if (mounted) {
        setState(() {
          _schedules = results[0] as List<DoctorSchedule>;
          _services = results[1] as List<DoctorService>;
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

  Future<void> _addService() async {
    final name = _serviceNameController.text.trim();
    final price = double.tryParse(_servicePriceController.text.trim()) ?? 0.0;

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid service name and price.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    try {
      final repo = context.read<DashboardRepository>();
      await repo.addDoctorService(widget.doctor.id, name, price);
      _serviceNameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service added successfully!'), backgroundColor: AppColors.success),
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

  Future<void> _deleteService(int serviceId) async {
    try {
      final repo = context.read<DashboardRepository>();
      await repo.deleteDoctorService(widget.doctor.id, serviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service removed.'), backgroundColor: AppColors.info),
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
            child: Icon(Icons.medical_services, color: primaryColor),
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
        height: 500,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              indicatorColor: primaryColor,
              tabs: [
                Tab(icon: const Icon(Icons.calendar_month), text: context.tr('working_schedule')),
                Tab(icon: const Icon(Icons.clean_hands_outlined), text: context.tr('services_and_fees')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildScheduleTab(isDark, primaryColor),
                            _buildServicesTab(isDark, primaryColor),
                          ],
                        ),
            ),
          ],
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

  Widget _buildScheduleTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('current_working_days'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
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
          const Divider(height: 32),
          Text(context.tr('add_schedule_day'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDay,
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
    );
  }

  Widget _buildServicesTab(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('offered_services'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_services.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(context.tr('no_services_configured'), style: const TextStyle(fontStyle: FontStyle.italic)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final srv = _services[index];
                return Card(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.medical_services_outlined, color: AppColors.info),
                    title: Text(srv.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('\$${srv.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      onPressed: () => _deleteService(srv.id),
                    ),
                  ),
                );
              },
            ),
          const Divider(height: 32),
          Text(context.tr('add_service'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _serviceNameController,
                  decoration: InputDecoration(labelText: context.tr('service_name')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _servicePriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: context.tr('price')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: Text(context.tr('add_service')),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
