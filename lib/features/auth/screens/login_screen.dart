import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-02 — Login Screen
//
// Supports:
//  • Email + password login (Firebase Auth)
//  • Biometric button (UI only — shows a SnackBar, needs local_auth package)
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Real Firebase login ───────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref
          .read(authServiceProvider)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      if (user == null) {
        setState(
          () => _errorMessage =
              'No profile found in the database for this account. '
              'If you just registered, wait a moment and try again, '
              'or contact SLE.',
        );
        return;
      }

      ref.read(currentUserProvider.notifier).state = user;
      if (user.role == AppConstants.roleAdmin) {
        context.go('/admin');
      } else {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (!mounted) return;
      if (user == null) {
        // User cancelled the Google picker — do nothing
        setState(() => _isLoading = false);
        return;
      }
      ref.read(currentUserProvider.notifier).state = user;
      if (user.role == AppConstants.roleAdmin) {
        context.go('/admin');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword(BuildContext context) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email above first.')),
      );
      return;
    }
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo & heading ──────────────────────────────
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textOf(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to your HostelHub account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMutedOf(context),
                ),
              ),

              const SizedBox(height: 40),

              // ── Login Form ──────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        hintText: 'you@ashesi.edu.gh',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!v.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Create account'),
                        ),
                        TextButton(
                          onPressed: () => _forgotPassword(context),
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Sign In button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Divider ─────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMutedOf(
                          context,
                        ).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              // ── Google Sign-In ────────────────────────────────
              _GoogleSignInButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
              ),

              const SizedBox(height: 12),

              // ── Biometric button ──────────────────────────────
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Biometric login available after first sign-in',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.fingerprint),
                label: const Text('Use Biometrics'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google Sign-In Button
// Follows Google's branding guidelines: white/surface background, Google G logo
// rendered as coloured text segments, "Sign in with Google" label.
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleSignInButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        side: BorderSide(
          color: isDark ? const Color(0xFF444444) : const Color(0xFFDDDDDD),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google "G" logo — four coloured segments via RichText
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              children: [
                TextSpan(
                  text: 'G',
                  style: TextStyle(color: Color(0xFF4285F4)),
                ),
                TextSpan(
                  text: 'o',
                  style: TextStyle(color: Color(0xFFEA4335)),
                ),
                TextSpan(
                  text: 'o',
                  style: TextStyle(color: Color(0xFFFBBC05)),
                ),
                TextSpan(
                  text: 'g',
                  style: TextStyle(color: Color(0xFF4285F4)),
                ),
                TextSpan(
                  text: 'l',
                  style: TextStyle(color: Color(0xFF34A853)),
                ),
                TextSpan(
                  text: 'e',
                  style: TextStyle(color: Color(0xFFEA4335)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Sign in with Google',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF3C4043),
            ),
          ),
        ],
      ),
    );
  }
}
