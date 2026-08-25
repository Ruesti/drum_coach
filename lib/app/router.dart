import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/local/settings_service.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/learning/daily_routine_screen.dart';
import '../features/lessons/collection_screen.dart';
import '../features/lessons/lesson_detail_screen.dart';
import '../features/lessons/lessons_screen.dart';
import '../features/lessons/models/rudiment.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/practice/practice_session_screen.dart';
import '../features/program/program_screen.dart';
import '../features/program/program_setup_screen.dart';
import '../features/coaching/exercise_generator_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';

// /program, /metronome, /settings, /coaching/exercise-generator etc. are
// top-level GoRoutes declared as siblings of the StatefulShellRoute, meant
// to push on top of the whole shell (covering the bottom nav bar). Without
// an explicit navigatorKey on GoRouter + a matching parentNavigatorKey on
// each of those routes, go_router places them onto the shell branch's own
// nested Navigator instead of the root one — colliding with that branch's
// auto-keyed page and crashing with a duplicate-Page-key assertion (a known
// go_router pitfall, flutter/flutter#156585 and similar).
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
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
      parentNavigatorKey: _rootNavigatorKey,
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
      path: '/program',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const ProgramScreen(),
    ),
    GoRoute(
      path: '/program/setup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const ProgramSetupScreen(),
    ),
    GoRoute(
      path: '/collection/:name',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final name = state.pathParameters['name'];
        final collection = ExerciseCollection.values.firstWhere(
          (c) => c.name == name,
          orElse: () => ExerciseCollection.rudimentEtudes,
        );
        return CollectionScreen(collection: collection);
      },
    ),
    // Top-level (outside the bottom-nav shell) so it can be pushed from any
    // route — collection, program, lessons — without go_router raising a
    // duplicate page-key assertion for a shell-branch route pushed from the
    // root navigator. Runs as a focused full-screen session.
    GoRoute(
      path: '/practice/:rudimentId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => PracticeSessionScreen(
        rudimentId: state.pathParameters['rudimentId']!,
        isFromRoutine: false,
        targetBpm: int.tryParse(state.uri.queryParameters['bpm'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/metronome',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const MetronomeScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/coaching/exercise-generator',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const ExerciseGeneratorScreen(),
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
