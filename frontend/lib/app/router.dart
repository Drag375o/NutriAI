import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/not_found_screen.dart';
import '../features/admin/screens/admin_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/coach/screens/coach_screen.dart';
import '../features/health/screens/health_screen.dart';
import '../features/landing/screens/landing_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/plan/screens/plan_screen.dart';
import '../features/progress/screens/progress_screen.dart';
import '../features/settings/screens/profile_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/today/screens/today_screen.dart';

/// Bridges Riverpod and go_router: the router re-evaluates its redirect
/// whenever auth state changes.
///
/// Deliberately does not listen to the profile. Screens watch that too,
/// and a save landing mid-frame would rebuild the router underneath them,
/// which trips a framework assertion. New accounts are sent to onboarding
/// from the login screen instead.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    // The front page, not the dashboard: a first-time visitor should see
    // what this is before being asked to sign in.
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final atLogin = state.matchedLocation == '/login';
      final atLanding = state.matchedLocation == '/';

      // Still restoring a stored token: hold position rather than flashing
      // the login screen at someone who is signed in.
      if (auth.status == AuthStatus.checking) return null;

      if (auth.status == AuthStatus.signedOut) {
        // The front page and the login form are both reachable signed out.
        // Everything else sends you to the front page.
        return (atLogin || atLanding) ? null : '/';
      }

      // Signed in, so neither the front page nor the login form has
      // anything left to offer.
      return (atLogin || atLanding) ? '/today' : null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LandingScreen()),
      ),

      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),

      // Outside the shell on purpose: onboarding is a focused flow, so the
      // navigation rail would only offer ways to abandon it.
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingScreen()),
      ),

      // Outside the shell: the panel has its own chrome, and an admin
      // managing accounts should not be looking at their own meal plan.
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          // Role is checked here as well as on every endpoint, so a
          // non-admin typing the URL is sent away rather than seeing an
          // empty panel full of failed requests.
          final user = ref.read(authControllerProvider).user;
          return user?.isAdmin == true ? null : '/today';
        },
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AdminScreen()),
      ),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TodayScreen()),
          ),
          GoRoute(
            path: '/plan',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlanScreen()),
          ),
          GoRoute(
            path: '/coach',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CoachScreen()),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProgressScreen()),
          ),
          GoRoute(
            path: '/health',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HealthScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});