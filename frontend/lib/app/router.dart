import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/placeholder_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/health/screens/health_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/shell/app_shell.dart';

import '../features/today/screens/today_screen.dart';

import '../features/coach/screens/coach_screen.dart';

import '../features/plan/screens/plan_screen.dart';

import '../features/progress/screens/progress_screen.dart';

/// Bridges Riverpod and go_router: the router re-evaluates its redirect
/// whenever auth state changes.
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
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final atLogin = state.matchedLocation == '/login';

      // Still restoring a stored token: hold position rather than flashing
      // the login screen at someone who is signed in.
      if (auth.status == AuthStatus.checking) return null;

      if (auth.status == AuthStatus.signedOut) {
        return atLogin ? null : '/login';
      }

      return atLogin ? '/today' : null;
    },
    routes: [
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
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlaceholderScreen(
                phase: 'PHASE 10',
                title: 'Profile',
                message: 'Personal details, dietary preferences, appearance, '
                    'and what happens to your data.',
              ),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const PlaceholderScreen(
      title: 'Page not found',
      message: 'That address does not exist. Use the navigation to get back.',
    ),
  );
});