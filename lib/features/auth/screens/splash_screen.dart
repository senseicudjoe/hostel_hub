import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-01 — Splash Screen
//
// Shows the HostelHub branding for a minimum of 2.5 s, then navigates once
// BOTH conditions are true:
//   1. The minimum branding time has elapsed.
//   2. SessionBootstrap has finished (biometric + Firestore fetch complete).
//
// This prevents the old race where the 2.5 s timer fired while the biometric
// OS dialog was still open and currentUserProvider was still null — which used
// to push the signed-in user to /onboarding.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  bool _minTimeReached = false;
  bool _bootstrapDone = false;
  bool _hasNavigated = false; // guard so we only call context.go once

  @override
  void initState() {
    super.initState();

    // Fade-in animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // If there is no Firebase session at all, SessionBootstrap will signal done
    // via a post-frame callback almost immediately.  We still show the splash
    // for the full minimum time so the branding is always visible.
    final hasFirebaseUser = FirebaseAuth.instance.currentUser != null;

    // Minimum display time — always enforced.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _minTimeReached = true;
      _tryNavigate();
    });

    // If there is no existing session we can skip waiting for bootstrap
    // (it will signal done almost immediately anyway, but this avoids a
    // brief extra frame of waiting).
    if (!hasFirebaseUser) {
      _bootstrapDone = true; // will navigate after 2.5 s to /onboarding
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Called whenever _minTimeReached or _bootstrapDone flips — navigates
  /// exactly once when both conditions are satisfied.
  void _tryNavigate() {
    if (!_minTimeReached || !_bootstrapDone || _hasNavigated || !mounted) {
      return;
    }
    _hasNavigated = true;

    final user = ref.read(currentUserProvider);
    if (user != null) {
      context.go(user.role == AppConstants.roleAdmin ? '/admin' : '/home');
    } else {
      // No session (or biometric was cancelled / Firestore unreachable).
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for SessionBootstrap completing.  ref.listen is the correct
    // Riverpod hook for side-effects inside build — it re-runs when the
    // provider value changes.
    ref.listen<bool>(sessionBootstrapDoneProvider, (_, isDone) {
      if (isDone) {
        _bootstrapDone = true;
        _tryNavigate();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'HostelHub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ashesi University',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
