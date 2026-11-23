import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/dashboard/screens/farmer_main_screen.dart';
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
import '../features/veterinary/screens/vet_main_screen.dart';
import '../features/veterinary/screens/vet_request_detail_screen.dart';
import '../features/veterinary/screens/vet_consult_screen.dart';
import '../features/veterinary/screens/vet_report_form_screen.dart';
import '../features/reports/screens/disease_report_form_screen.dart';
import '../features/reports/screens/disease_report_list_screen.dart';
import '../features/announcements/screens/announcement_list_screen.dart';
import '../features/announcements/screens/announcement_detail_screen.dart';
import '../features/assistant/screens/assistant_screen.dart';
import '../features/auth/screens/profile_edit_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final status = authProvider.status;
      if (status == AuthStatus.unknown) return null;
      final isAuth = status == AuthStatus.authenticated;
      final publicRoutes = {'/login', '/register', '/forgot-password'};
      final isPublic = publicRoutes.contains(state.matchedLocation);
      if (!isAuth && !isPublic) return '/login';
      if (isAuth && isPublic) {
        // Route vets to their own dashboard
        return authProvider.user?.isVet == true
            ? '/vet-dashboard'
            : '/dashboard';
      }
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // ── Farmer dashboard ──────────────────────────────────────────────
      GoRoute(path: '/dashboard', builder: (_, __) => const FarmerMainScreen()),
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

      // ── Veterinary assistance (farmer side) ───────────────────────────
      GoRoute(path: '/vets', builder: (_, __) => const VetDirectoryScreen()),
      GoRoute(
        path: '/assistance',
        builder: (_, __) => const AssistanceRequestListScreen(),
      ),
      GoRoute(
        path: '/assistance/new',
        builder: (_, __) => const AssistanceRequestFormScreen(),
      ),

      // ── Disease reports (farmer side) ─────────────────────────────────
      GoRoute(
        path: '/reports',
        builder: (_, __) => const DiseaseReportListScreen(),
      ),
      GoRoute(
        path: '/reports/new',
        builder: (_, __) => const DiseaseReportFormScreen(),
      ),

      // ── Announcements ─────────────────────────────────────────────────
      GoRoute(
        path: '/announcements',
        builder: (_, __) => const AnnouncementListScreen(),
      ),
      GoRoute(
        path: '/announcements/:id',
        builder: (_, state) => AnnouncementDetailScreen(
          announcementId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // ── AI Health Assistant ───────────────────────────────────────────
      GoRoute(
        path: '/assistant',
        builder: (_, __) => const AssistantScreen(),
      ),

      // ── Vet dashboard ─────────────────────────────────────────────────
      GoRoute(
        path: '/vet-dashboard',
        builder: (_, __) => const VetMainScreen(),
      ),
      GoRoute(
        path: '/vet/requests/:id',
        builder: (_, state) => VetRequestDetailScreen(
          requestId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/vet/consult/:requestId',
        builder: (_, state) => VetConsultScreen(
          requestId: int.parse(state.pathParameters['requestId']!),
        ),
      ),
      GoRoute(
        path: '/vet/reports/new',
        builder: (_, __) => const VetReportFormScreen(),
      ),

      // ── Profile edit (shared — farmer and vet) ────────────────────────
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const ProfileEditScreen(),
      ),
    ],
  );
}
