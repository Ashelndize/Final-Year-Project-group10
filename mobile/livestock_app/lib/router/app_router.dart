import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/farms/screens/farm_list_screen.dart';
import '../features/farms/screens/farm_form_screen.dart';
import '../features/farms/screens/farm_detail_screen.dart';
import '../features/animals/screens/animal_list_screen.dart';
import '../features/animals/screens/animal_form_screen.dart';
import '../features/animals/screens/animal_detail_screen.dart';
import '../features/health/screens/health_list_screen.dart';
import '../features/health/screens/health_form_screen.dart';
import '../features/vaccinations/screens/vaccination_schedule_screen.dart';
import '../features/notifications/screens/notification_screen.dart';
import '../features/veterinary/screens/vet_directory_screen.dart';
import '../features/veterinary/screens/assistance_request_form_screen.dart';
import '../features/veterinary/screens/assistance_request_list_screen.dart';
import '../features/reports/screens/disease_report_form_screen.dart';
import '../features/reports/screens/disease_report_list_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final status = authProvider.status;
      if (status == AuthStatus.unknown) return null;
      final isAuth = status == AuthStatus.authenticated;
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!isAuth && !loggingIn) return '/login';
      if (isAuth && loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/farms', builder: (_, __) => const FarmListScreen()),
      GoRoute(path: '/farms/new', builder: (_, __) => const FarmFormScreen()),
      GoRoute(
        path: '/farms/:id',
        builder: (_, state) =>
            FarmDetailScreen(farmId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/farms/:id/animals',
        builder: (_, state) =>
            AnimalListScreen(farmId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/farms/:farmId/animals/new',
        builder: (_, state) => AnimalFormScreen(
          farmId: int.parse(state.pathParameters['farmId']!),
        ),
      ),
      GoRoute(
        path: '/animals/:id',
        builder: (_, state) => AnimalDetailScreen(
          animalId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/animals/:id/health',
        builder: (_, state) => HealthListScreen(
          animalId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/animals/:id/health/new',
        builder: (_, state) => HealthFormScreen(
          animalId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/vaccinations',
        builder: (_, __) => const VaccinationScheduleScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationScreen(),
      ),
      // Phase 4 — Veterinary assistance
      GoRoute(
        path: '/vets',
        builder: (_, __) => const VetDirectoryScreen(),
      ),
      GoRoute(
        path: '/assistance',
        builder: (_, __) => const AssistanceRequestListScreen(),
      ),
      GoRoute(
        path: '/assistance/new',
        builder: (_, __) => const AssistanceRequestFormScreen(),
      ),
      // Phase 4 — Disease reports
      GoRoute(
        path: '/reports',
        builder: (_, __) => const DiseaseReportListScreen(),
      ),
      GoRoute(
        path: '/reports/new',
        builder: (_, __) => const DiseaseReportFormScreen(),
      ),
    ],
  );
}
