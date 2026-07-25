class DoctorSchedule {
  final int id;
  final int doctorId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int durationPerPatient;

  DoctorSchedule({
    required this.id,
    required this.doctorId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.durationPerPatient,
  });

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    return DoctorSchedule(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      doctorId: json['doctor_id'] is int ? json['doctor_id'] : int.tryParse(json['doctor_id'].toString()) ?? 0,
      dayOfWeek: json['day_of_week'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      durationPerPatient: json['duration_per_patient'] is int
          ? json['duration_per_patient']
          : int.tryParse(json['duration_per_patient'].toString()) ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'duration_per_patient': durationPerPatient,
    };
  }
}
