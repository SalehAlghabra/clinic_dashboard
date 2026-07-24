import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_dashboard/main.dart';
import 'package:clinic_dashboard/core/services/storage_service.dart';
import 'package:clinic_dashboard/core/api/api_client.dart';
import 'package:clinic_dashboard/features/auth/data/repositories/auth_repository.dart';
import 'package:clinic_dashboard/features/dashboard/data/repositories/dashboard_repository.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final storageService = StorageService();
    final apiClient = ApiClient(storageService: storageService);
    final authRepository = AuthRepository(apiClient: apiClient, storageService: storageService);
    final dashboardRepository = DashboardRepository(apiClient: apiClient);

    await tester.pumpWidget(MyApp(
      storageService: storageService,
      authRepository: authRepository,
      dashboardRepository: dashboardRepository,
    ));

    expect(find.byType(MyApp), findsOneWidget);
  });
}
