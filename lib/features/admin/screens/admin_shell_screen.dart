import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Shell
//
// Persistent scaffold for admin-role users.
// 5 tabs: Dashboard / Rooms / Maintenance / Announcements / Profile
// ─────────────────────────────────────────────────────────────────────────────

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<GlobalKey<NavigatorState>> branchNavigatorKeys;

  const AdminShell({
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
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment_rounded),
              label: 'Rooms',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build_rounded),
              label: 'Maintenance',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'Announce',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
