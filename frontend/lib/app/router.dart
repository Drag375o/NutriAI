import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/placeholder_screen.dart';
import '../features/shell/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/today',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderScreen(
              phase: 'PHASE 4',
              title: 'Today',
              message: 'Your weight, BMI, and the day\'s plan at a glance, '
                  'with one place to ask NutriAI anything.',
            ),
          ),
        ),
        GoRoute(
          path: '/plan',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderScreen(
              phase: 'PHASE 6',
              title: 'Plan',
              message: 'Meals built around your goal, your preferences, and '
                  'the food you actually eat.',
            ),
          ),
        ),
        GoRoute(
          path: '/coach',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderScreen(
              phase: 'PHASE 5',
              title: 'Coach',
              message: 'Ask NutriAI about your meals, goals, or nutrition. '
                  'Every conversation is saved here.',
            ),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderScreen(
              phase: 'PHASE 7',
              title: 'Progress',
              message: 'Start tracking your weight to see how it moves over '
                  'time, against the goal you set.',
            ),
          ),
        ),
        GoRoute(
          path: '/health',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderScreen(
              phase: 'PHASE 3',
              title: 'Health',
              message: 'Your measurements, BMI, and the health information '
                  'NutriAI uses to personalise its advice.',
            ),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: PlaceholderScreen(
              phase: 'PHASE 8',
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