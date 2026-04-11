import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Email Verification Screen
//
// Shown after registration (and on login if email not yet verified).
// User clicks the link in their inbox, comes back, taps "I've verified".
// ─────────────────────────────────────────────────────────────────────────────

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  String? _message;
  bool _messageIsError = false;

  String get _email =>
      FirebaseAuth.instance.currentUser?.email ?? 'your email';

  Future<void> _checkVerified() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });
    try {
      final verified = await ref.read(authServiceProvider).reloadAndCheckVerified();
      if (!mounted) return;
      if (verified) {
        context.go('/home');
      } else {
        setState(() {
          _messageIsError = true;
          _message =
              'Email not verified yet. Check your inbox and click the link first.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = 'Something went wrong. Try again.';
      });
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _messageIsError = false;
        _message = 'Verification email resent — check your inbox.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = 'Could not resend. Try again in a moment.';
      });
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).logout();
    ref.read(currentUserProvider.notifier).state = null;
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ── Illustration ──────────────────────────────────────
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 46,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Heading ───────────────────────────────────────────
              Text(
                'Check your inbox',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textOf(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMutedOf(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Click the link in the email, then come back and tap the button below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMutedOf(context),
                  height: 1.5,
                ),
              ),

              // ── Feedback message ──────────────────────────────────
              if (_message != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: (_messageIsError
                            ? AppColors.error
                            : AppColors.success)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_messageIsError
                              ? AppColors.error
                              : AppColors.success)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _messageIsError
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 18,
                        color: _messageIsError
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _messageIsError
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Primary action ────────────────────────────────────
              ElevatedButton(
                onPressed: _isChecking ? null : _checkVerified,
                child: _isChecking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text("I've verified my email"),
              ),

              const SizedBox(height: 12),

              // ── Resend ────────────────────────────────────────────
              OutlinedButton(
                onPressed: _isResending ? null : _resend,
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Resend verification email'),
              ),

              const Spacer(),

              // ── Sign out ──────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: _signOut,
                  child: Text(
                    'Use a different account',
                    style: TextStyle(color: AppColors.textMutedOf(context)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
