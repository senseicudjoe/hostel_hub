import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/session_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget: full UI from `core/router/app_router.dart` (splash → onboarding → login,
/// then student or admin shells with all tab screens).
class HostelHubApp extends ConsumerWidget {
  const HostelHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'HostelHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) =>
          SessionBootstrap(child: child ?? const SizedBox.shrink()),
    );
  }
}
