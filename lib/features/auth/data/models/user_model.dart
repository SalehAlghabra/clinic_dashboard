import '../../../../core/config/app_config.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profilePicture;
  final String? profilePictureUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePicture,
    this.profilePictureUrl,
  });

  static String? _parseProfilePictureUrl(dynamic rawUrl, dynamic rawPath) {
    String? url = rawUrl as String? ?? rawPath as String?;
    if (url == null || url.isEmpty || url.contains('default-avatar.png')) {
      return null;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final base = AppConfig.baseUrl.endsWith('/')
          ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
          : AppConfig.baseUrl;
      final path = url.startsWith('/') ? url : '/$url';
      return '$base$path';
    }

    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      final baseUri = Uri.parse(AppConfig.baseUrl);
      final rawUri = Uri.parse(url);
      final fixedUri = rawUri.replace(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
      );
      return fixedUri.toString();
    }

    return url;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'admin',
      profilePicture: json['profile_picture'],
      profilePictureUrl: _parseProfilePictureUrl(json['profile_picture_url'], json['profile_picture']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profile_picture': profilePicture,
      'profile_picture_url': profilePictureUrl,
    };
  }
}
