import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepository({
    required ApiClient apiClient,
    required StorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService;

  Future<UserModel> login({required String email, required String password}) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data;
    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _storageService.saveToken(token);
    }

    final userData = data['user'] ?? data;
    return UserModel.fromJson(userData);
  }

  Future<UserModel?> getProfile() async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) return null;

      final response = await _apiClient.get(ApiEndpoints.me);
      return UserModel.fromJson(response.data['user'] ?? response.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {}
    await _storageService.clearToken();
  }

  Future<void> createStaff({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    await _apiClient.post(
      ApiEndpoints.createStaff,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      },
    );
  }
}
