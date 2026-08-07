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
    if (url == null || url.toString().isEmpty || url.toString().contains('default-avatar.png')) {
      return null;
    }

    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;

    String relativePath = url.toString();
    if (relativePath.contains('storage/')) {
      final idx = relativePath.indexOf('storage/');
      relativePath = relativePath.substring(idx + 'storage/'.length);
    }
    if (relativePath.startsWith('/')) {
      relativePath = relativePath.substring(1);
    }

    if ((url.toString().startsWith('http://') || url.toString().startsWith('https://')) && !url.toString().contains('storage/')) {
      return url.toString();
    }

    return '$base/api/storage/$relativePath';
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
