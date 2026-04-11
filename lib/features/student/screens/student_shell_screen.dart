import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Student Shell
//
// This is the persistent scaffold that wraps all student tab screens.
// The NavigationBar at the bottom lets students switch between:
//   Home → Explore → My Room → Requests → Profile
//
// StatefulShellRoute keeps each tab's state alive — so if you scroll
// down on the Maintenance list and switch tabs, your scroll position
// is remembered when you come back.
// ─────────────────────────────────────────────────────────────────────────────

class StudentShell extends StatelessWidget {
  /// go_router provides this object to control which tab is active.
  final StatefulNavigationShell navigationShell;
  final List<GlobalKey<NavigatorState>> branchNavigatorKeys;

  const StudentShell({
    super.key,
    required this.navigationShell,
    required this.branchNavigatorKeys,
  });

  @override
  Widget build(BuildContext context) {
    final currentNavigator =
        branchNavigatorKeys[navigationShell.currentIndex].currentState;
    final currentBranchCanPop = currentNavigator?.canPop() ?? false;
    final shouldAllowSystemPop =
        navigationShell.currentIndex == 0 || currentBranchCanPop;

    return PopScope(
      canPop: shouldAllowSystemPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        // The body IS the currently selected tab's screen.
        body: navigationShell,

        // Bottom navigation bar — 5 destinations.
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            // goBranch switches to the selected tab.
            // Setting initialLocation = true navigates to the tab root
            // when you tap the already-selected tab (useful to go back to top).
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
              // tooltip: '' disables the long-press tooltip. Without this,
              // Flutter tries to show a Tooltip using an Overlay that isn't
              // reachable from the bottomNavigationBar slot inside a nested
              // go_router shell, causing a "No Overlay widget found" crash.
              tooltip: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'Explore',
              tooltip: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room_rounded),
              label: 'My Room',
              tooltip: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build_rounded),
              label: 'Requests',
              tooltip: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
              tooltip: '',
            ),
          ],
        ),
      ),
    );
  }
}
