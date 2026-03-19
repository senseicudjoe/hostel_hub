import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Student Shell
//
// This is the persistent scaffold that wraps all student tab screens.
// The NavigationBar at the bottom lets students switch between:
//   Home → Room → Maintenance → Shuttle → Profile
//
// StatefulShellRoute keeps each tab's state alive — so if you scroll
// down on the Maintenance list and switch tabs, your scroll position
// is remembered when you come back.
// ─────────────────────────────────────────────────────────────────────────────

class StudentShell extends StatelessWidget {
  /// go_router provides this object to control which tab is active.
  final StatefulNavigationShell navigationShell;

  const StudentShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body IS the currently selected tab's screen.
      body: navigationShell,

      // Bottom navigation bar — 5 destinations matching the PRD.
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
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room_rounded),
            label: 'My Room',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build_rounded),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus_rounded),
            label: 'Shuttle',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
