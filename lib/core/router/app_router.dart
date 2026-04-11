import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_model.dart';
import '../constants/app_constants.dart';
import '../providers/app_providers.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/student/screens/student_shell_screen.dart';
import '../../features/student/screens/student_dashboard_screen.dart';
import '../../features/student/screens/explore_rooms_screen.dart';
import '../../features/student/screens/my_room_screen.dart';
import '../../features/student/screens/maintenance_list_screen.dart';
import '../../features/student/screens/new_request_screen.dart';
import '../../features/student/screens/request_detail_screen.dart';
import '../../features/student/screens/announcements_screen.dart';
import '../../features/student/screens/profile_screen.dart';
import '../../features/admin/screens/admin_shell_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_room_management_screen.dart';
import '../../features/admin/screens/admin_maintenance_screen.dart';
import '../../features/admin/screens/compose_announcement_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER PROVIDER
//
// The app uses go_router for declarative navigation.
// There are two StatefulShellRoutes (tab shells):
//   1. Student shell: Home / Explore / My Room / Maintenance / Profile
//   2. Admin shell:   Dashboard / Rooms / Maintenance / Announcements / Profile
//
// Detail screens (e.g., maintenance/:id) live inside their branch so the
// bottom nav stays visible — a common pattern in mobile apps.
// ─────────────────────────────────────────────────────────────────────────────

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen<UserModel?>(currentUserProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final loc = state.matchedLocation;

      if (user != null) {
        final isAdmin = user.role == AppConstants.roleAdmin;

        // ── Email verification gate ────────────────────────────────────────
        // Students must verify their email before accessing the app.
        // Admin accounts are provisioned externally and exempt from this check.
        final emailVerified =
            FirebaseAuth.instance.currentUser?.emailVerified ?? true;
        if (!isAdmin && !emailVerified) {
          return loc == '/verify-email' ? null : '/verify-email';
        }
        if (loc == '/verify-email') {
          return isAdmin ? '/admin' : '/home';
        }
        // ──────────────────────────────────────────────────────────────────

        if (loc == '/splash' || loc == '/onboarding') {
          return isAdmin ? '/admin' : '/home';
        }
        if (loc == '/login' || loc == '/register') {
          return isAdmin ? '/admin' : '/home';
        }
        if (isAdmin) {
          final onStudentShell = loc == '/home' ||
              loc.startsWith('/room') ||
              (loc.startsWith('/maintenance') && !loc.startsWith('/admin')) ||
              loc == '/profile' ||
              loc == '/announcements';
          if (onStudentShell) {
            return loc == '/announcements'
                ? '/admin/announcements'
                : '/admin';
          }
        } else {
          if (loc.startsWith('/admin')) return '/home';
        }
        return null;
      }

      final authPublic = loc == '/splash' ||
          loc == '/onboarding' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/verify-email';
      if (!authPublic) return '/login';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Student Shell ─────────────────────────────────────────────────────
      // StatefulShellRoute.indexedStack keeps each tab's navigation stack
      // alive when you switch tabs — so state is preserved.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0 — Home / Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const StudentDashboardScreen(),
            ),
          ]),

          // Tab 1 — Explore rooms (booking)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExploreRoomsScreen(),
            ),
          ]),

          // Tab 2 — My Room
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/room',
              builder: (context, state) => const MyRoomScreen(),
            ),
          ]),

          // Tab 3 — Maintenance (with sub-routes for new & detail)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/maintenance',
              builder: (context, state) => const MaintenanceListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const NewRequestScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => RequestDetailScreen(
                    requestId: state.pathParameters['id'] ?? '',
                  ),
                ),
              ],
            ),
          ]),

          // Tab 4 — Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      // ── Standalone Student routes ─────────────────────────────────────────
      GoRoute(
        path: '/announcements',
        builder: (context, state) => const AnnouncementsScreen(),
      ),

      // ── Admin Shell ───────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0 — Admin Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ]),

          // Tab 1 — Room Management
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/rooms',
              builder: (context, state) => const AdminRoomManagementScreen(),
            ),
          ]),

          // Tab 2 — Maintenance Management
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/maintenance',
              builder: (context, state) => const AdminMaintenanceScreen(),
            ),
          ]),

          // Tab 3 — Announcements (admin can compose from here)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/announcements',
              builder: (context, state) => const AnnouncementsScreen(),
              routes: [
                GoRoute(
                  path: 'compose',
                  builder: (context, state) =>
                      const ComposeAnnouncementScreen(),
                ),
              ],
            ),
          ]),

          // Tab 4 — Profile (shared with student)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
