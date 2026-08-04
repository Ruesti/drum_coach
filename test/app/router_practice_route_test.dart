import 'package:drum_coach/app/router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression guard for the "start an exercise from the training program"
/// crash: `'!keyReservation.contains(key)': is not true` (navigator.dart).
///
/// `/practice/:rudimentId` is a full-screen route pushed from TWO different
/// navigator contexts:
///   - the Lessons detail screen, which lives inside the shell, and
///   - the training program screen, which sits on the ROOT navigator.
///
/// If the route is nested inside a StatefulShellBranch, pushing it from the
/// root-navigator program screen collides with that branch's own page key and
/// trips Navigator's duplicate-page-key assertion. It must therefore be a
/// root-navigator route (top-level, with a parentNavigatorKey).
void main() {
  final topLevelPaths = <String>{};
  final pathsInsideShellBranches = <String>{};
  final parentKeyByPath = <String, GlobalKey<NavigatorState>?>{};

  void walk(List<RouteBase> routes, {required bool insideBranch}) {
    for (final route in routes) {
      if (route is GoRoute) {
        if (insideBranch) {
          pathsInsideShellBranches.add(route.path);
        } else {
          topLevelPaths.add(route.path);
        }
        parentKeyByPath[route.path] = route.parentNavigatorKey;
        walk(route.routes, insideBranch: insideBranch);
      } else if (route is StatefulShellRoute) {
        for (final branch in route.branches) {
          walk(branch.routes, insideBranch: true);
        }
      } else if (route is ShellRouteBase) {
        walk(route.routes, insideBranch: insideBranch);
      }
    }
  }

  setUpAll(() => walk(router.configuration.routes, insideBranch: false));

  test('/practice/:rudimentId is a top-level route, not nested in a shell branch', () {
    expect(topLevelPaths, contains('/practice/:rudimentId'),
        reason: 'practice must be a top-level (root-navigator) route so it can '
            'be pushed from both the Lessons detail screen and the training '
            'program screen without a duplicate-page-key crash');
    expect(
      pathsInsideShellBranches.where((p) => p.contains('practice')),
      isEmpty,
      reason: 'no /practice route may live inside a StatefulShellBranch — that '
          'is exactly what caused the keyReservation crash',
    );
  });

  test('/practice/:rudimentId is bound to a parent (root) navigator key', () {
    expect(parentKeyByPath['/practice/:rudimentId'], isNotNull,
        reason: 'a root-navigator route needs an explicit parentNavigatorKey so '
            'go_router places it on the root navigator, above the shell');
  });
}
