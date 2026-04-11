import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/biometric_auth_service.dart';

class BiometricSettingsScreen extends ConsumerStatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  ConsumerState<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState
    extends ConsumerState<BiometricSettingsScreen> {
  bool _isBusy = false;
  late Future<BiometricStatus> _statusFuture;

  // Kept at class level so it is never disposed while the dialog's pop
  // animation is still running.  Disposing a TextEditingController inside
  // _promptForPassword (right after showDialog returns) caused the crash
  // because the TextField widget is still alive during the slide-out
  // animation and tries to add a listener to the already-disposed controller.
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusFuture = _loadStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<BiometricStatus> _loadStatus() {
    return ref.read(biometricAuthServiceProvider).getStatus();
  }

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    setState(() {
      _statusFuture = _loadStatus();
    });
  }

  /// Returns true if the current Firebase account uses Google Sign-In and has
  /// no email/password provider linked (i.e. they signed up with Google only).
  bool _isGoogleOnlyUser(User firebaseUser) {
    final providers =
        firebaseUser.providerData.map((p) => p.providerId).toSet();
    return providers.contains('google.com') &&
        !providers.contains('password');
  }

  Future<void> _enableBiometric(BiometricStatus status) async {
    final user = ref.read(currentUserProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (user == null || firebaseUser == null) return;

    if (!status.isSupported) {
      _showSnackBar('Biometric authentication is not available on this device.');
      return;
    }

    if (_isGoogleOnlyUser(firebaseUser)) {
      await _enableBiometricGoogle(firebaseUser, user.email);
    } else {
      await _enableBiometricEmail(firebaseUser, user.email);
    }
  }

  /// Enable flow for Google Sign-In accounts — re-authenticates via Google
  /// (no password prompt) then saves a Google credential marker.
  Future<void> _enableBiometricGoogle(
    User firebaseUser,
    String email,
  ) async {
    // Capture messenger before any await.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);

    try {
      // Re-authenticate with Google to confirm identity.
      final googleUser = await GoogleSignIn().signIn();
      if (!mounted) return;
      if (googleUser == null) return; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      if (!mounted) return;

      // Now prompt the device biometric OS dialog.
      final authenticated = await ref
          .read(biometricAuthServiceProvider)
          .authenticate(
            localizedReason:
                'Confirm your identity to enable biometric sign-in for HostelHub',
          );
      if (!mounted) return;

      if (!authenticated) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Biometric confirmation was cancelled.')),
        );
        return;
      }

      // Store a Google credential marker (no password).
      await ref
          .read(biometricAuthServiceProvider)
          .saveGoogleCredential(email: email);
      if (!mounted) return;

      ref.read(biometricEnabledProvider.notifier).setEnabled(true);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Biometric sign-in is enabled on this device.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _refreshStatus();
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not verify your Google account: ${e.message ?? e.code}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Enable flow for email/password accounts — prompts for password and
  /// re-authenticates before saving credentials.
  Future<void> _enableBiometricEmail(User firebaseUser, String email) async {
    // Await the dialog before doing anything else — widget may be rebuilt
    // while the dialog is open, so check mounted immediately after.
    final password = await _promptForPassword(email);
    if (!mounted) return;
    if (password == null || password.isEmpty) return;

    // Capture the messenger NOW, while context is guaranteed to be valid.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      if (!mounted) return;

      final authenticated = await ref
          .read(biometricAuthServiceProvider)
          .authenticate(
            localizedReason:
                'Confirm your identity to enable biometric sign-in for HostelHub',
          );
      if (!mounted) return;

      if (!authenticated) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Biometric confirmation was cancelled.')),
        );
        return;
      }

      await ref
          .read(biometricAuthServiceProvider)
          .saveCredentials(email: email, password: password);
      if (!mounted) return;

      ref.read(biometricEnabledProvider.notifier).setEnabled(true);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Biometric sign-in is enabled on this device.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _refreshStatus();
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'Incorrect password.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        _ => 'Could not verify your password. Please try again.',
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _disableBiometric() async {
    // Capture messenger before any await for the same reason as above.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isBusy = true);
    try {
      await ref.read(biometricAuthServiceProvider).clearCredentials();
      if (!mounted) return;

      ref.read(biometricEnabledProvider.notifier).setEnabled(false);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Biometric sign-in has been turned off.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _refreshStatus();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _testBiometric(BiometricStatus status) async {
    if (!status.isSupported) {
      _showSnackBar(
        'Biometric authentication is not available on this device.',
      );
      return;
    }

    // Capture before the authenticate await — the OS biometric prompt will
    // pause the Flutter activity, and context may be deactivated on return.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isBusy = true);
    try {
      final authenticated = await ref
          .read(biometricAuthServiceProvider)
          .authenticate(
            localizedReason:
                'Authenticate with your device biometrics to test HostelHub sign-in',
          );
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            authenticated
                ? 'Biometric prompt completed successfully.'
                : 'Biometric prompt was cancelled.',
          ),
          backgroundColor: authenticated ? AppColors.success : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<String?> _promptForPassword(String email) async {
    // Reset the shared controller before each use.
    _passwordController.clear();
    var obscureText = true;

    // Wrap content in SingleChildScrollView so the soft keyboard doesn't
    // overflow the dialog (was causing "RenderFlex overflowed by 99897px").
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the password for $email to enable biometric sign-in on this device.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      // Uses the class-level controller — never disposed
                      // while the dialog pop-animation is still running.
                      controller: _passwordController,
                      obscureText: obscureText,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setDialogState(() => obscureText = !obscureText),
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(_passwordController.text.trim()),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
    // No controller.dispose() here — the controller lives with the widget
    // and is disposed in dispose() above when the screen is finally removed.
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final biometricEnabled = ref.watch(biometricEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Login')),
      body: FutureBuilder<BiometricStatus>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final status = snapshot.data!;
          final availabilityText = status.isSupported
              ? _formatBiometricTypes(status.availableBiometrics)
              : 'Unavailable';

          return RefreshIndicator(
            onRefresh: _refreshStatus,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoCard(
                  title: 'Status',
                  children: [
                    _StatusRow(
                      label: 'Device support',
                      value: status.isSupported ? 'Available' : 'Unavailable',
                    ),
                    _StatusRow(
                      label: 'Enrolled methods',
                      value: availabilityText,
                    ),
                    _StatusRow(
                      label: 'HostelHub sign-in',
                      value: biometricEnabled && status.hasStoredCredentials
                          ? 'Enabled'
                          : 'Disabled',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'How it works',
                  children: const [
                    Text(
                      'Enable this on a trusted device after signing in once. HostelHub will store your account password securely on this device and require the system biometric prompt before using it.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isBusy
                      ? null
                      : biometricEnabled && status.hasStoredCredentials
                      ? null
                      : () => _enableBiometric(status),
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: Text(
                    biometricEnabled && status.hasStoredCredentials
                        ? 'Biometric Sign-In Enabled'
                        : 'Enable Biometric Sign-In',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : () => _testBiometric(status),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Test Biometric Prompt'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isBusy || !biometricEnabled
                      ? null
                      : _disableBiometric,
                  icon: const Icon(Icons.lock_reset_outlined),
                  label: const Text('Disable Biometric Sign-In'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatBiometricTypes(List<BiometricType> biometrics) {
    if (biometrics.isEmpty) return 'None enrolled';

    final labels = biometrics
        .map(
          (type) => switch (type) {
            BiometricType.face => 'Face',
            BiometricType.fingerprint => 'Fingerprint',
            BiometricType.strong => 'Strong biometric',
            BiometricType.weak => 'Weak biometric',
            BiometricType.iris => 'Iris',
          },
        )
        .toSet()
        .toList();

    return labels.join(', ');
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textOf(context),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
