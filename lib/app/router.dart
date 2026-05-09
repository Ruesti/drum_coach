import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/local/settings_service.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/learning/daily_routine_screen.dart';
import '../features/lessons/lesson_detail_screen.dart';
import '../features/lessons/lessons_screen.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/practice/practice_session_screen.dart';
import '../features/stats/stats_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (!SettingsService.isOnboardingDone && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, _) => OnboardingScreen(
        onComplete: () => context.go('/'),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const DashboardScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/routine',
            builder: (_, __) => const DailyRoutineScreen(),
            routes: [
              GoRoute(
                path: ':rudimentId',
                builder: (_, state) => PracticeSessionScreen(
                  rudimentId: state.pathParameters['rudimentId']!,
                  isFromRoutine: true,
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/lessons',
            builder: (_, __) => const LessonsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => LessonDetailScreen(
                  rudimentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/practice/:rudimentId',
            builder: (_, state) => PracticeSessionScreen(
              rudimentId: state.pathParameters['rudimentId']!,
              isFromRoutine: false,
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/stats',
            builder: (_, __) => const StatsScreen(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/metronome',
      builder: (_, __) => const MetronomeScreen(),
    ),
  ],
);

class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: 'Routine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Lessons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
