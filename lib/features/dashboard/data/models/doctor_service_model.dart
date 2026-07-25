class DoctorService {
  final int id;
  final int doctorId;
  final String serviceName;
  final double price;

  DoctorService({
    required this.id,
    required this.doctorId,
    required this.serviceName,
    required this.price,
  });

  factory DoctorService.fromJson(Map<String, dynamic> json) {
    return DoctorService(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      doctorId: json['doctor_id'] is int ? json['doctor_id'] : int.tryParse(json['doctor_id'].toString()) ?? 0,
      serviceName: json['service_name'] ?? '',
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'service_name': serviceName,
      'price': price,
    };
  }
}
