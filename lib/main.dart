import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api/api_client.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_events_states.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/data/repositories/dashboard_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/language_cubit.dart';
import 'features/dashboard/presentation/bloc/theme_cubit.dart';
import 'features/dashboard/presentation/bloc/theme_state.dart';
import 'features/dashboard/presentation/screens/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  final apiClient = ApiClient(storageService: storageService);
  final authRepository = AuthRepository(apiClient: apiClient, storageService: storageService);
  final dashboardRepository = DashboardRepository(apiClient: apiClient);

  runApp(MyApp(
    storageService: storageService,
    authRepository: authRepository,
    dashboardRepository: dashboardRepository,
  ));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final AuthRepository authRepository;
  final DashboardRepository dashboardRepository;

  const MyApp({
    super.key,
    required this.storageService,
    required this.authRepository,
    required this.dashboardRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: dashboardRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(storageService: storageService)),
          BlocProvider(create: (_) => LanguageCubit(storageService: storageService)),
          BlocProvider(
            create: (_) => AuthBloc(authRepository: authRepository)..add(CheckAuthStatus()),
          ),
          BlocProvider(
            create: (_) => DashboardBloc(repository: dashboardRepository),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<LanguageCubit, Locale>(
              builder: (context, locale) {
                return MaterialApp(
                  title: 'Clinova',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme(themeState.primaryColor),
                  darkTheme: AppTheme.darkTheme(themeState.primaryColor),
                  themeMode: themeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  locale: locale,
                  supportedLocales: const [
                    Locale('en'),
                    Locale('ar'),
                  ],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      if (authState is Authenticated) {
                        return const AdminDashboardScreen();
                      }
                      // For Unauthenticated, AuthOtpRequired, AuthLoading, or AuthFailure:
                      return const LoginScreen();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
