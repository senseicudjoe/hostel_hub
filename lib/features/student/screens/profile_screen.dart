import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-11 — Profile & Settings Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Local notification toggle state (stored per-session; wiring to FCM
  // topic subscribe/unsubscribe happens here)
  bool _maintenanceNotifs = true;
  bool _announcementNotifs = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final themeMode = ref.watch(themeModeProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final isDark = themeMode == ThemeMode.dark;

    final initials =
        user?.name
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join() ??
        '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header ───────────────────────────────────
            _ProfileHeader(
              initials: initials,
              name: user?.name ?? '—',
              email: user?.email ?? '—',
              tag: isAdmin
                  ? 'SLE Administrator'
                  : '${user?.hostel ?? ''} · Room ${user?.roomNumber ?? ''}',
              isAdmin: isAdmin,
            ),

            const SizedBox(height: 8),

            // ── Notifications ────────────────────────────────────
            _SectionHeader(title: 'Notifications'),
            _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.build_outlined,
                  title: 'Maintenance Updates',
                  subtitle: 'Get notified when your request status changes',
                  value: _maintenanceNotifs,
                  onChanged: (v) {
                    setState(() => _maintenanceNotifs = v);
                    final ns = ref.read(notificationServiceProvider);
                    if (v) {
                      ns.subscribeToRole(ref.read(userRoleProvider));
                    } else {
                      ns.unsubscribeAll();
                    }
                  },
                ),
                const Divider(height: 1),
                _ToggleTile(
                  icon: Icons.campaign_outlined,
                  title: 'Announcements',
                  subtitle: 'Important notices from SLE',
                  value: _announcementNotifs,
                  onChanged: (v) => setState(() => _announcementNotifs = v),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Preferences ──────────────────────────────────────
            _SectionHeader(title: 'Preferences'),
            _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme throughout the app',
                  value: isDark,
                  onChanged: (v) =>
                      ref.read(themeModeProvider.notifier).setDarkMode(v),
                ),
                const Divider(height: 1),
                _ToggleTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric Login',
                  subtitle: 'Use fingerprint or Face ID to unlock the app',
                  value: biometricEnabled,
                  onChanged: (v) => _toggleBiometric(context, v),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Account ──────────────────────────────────────────
            _SectionHeader(title: 'Account'),
            _SettingsCard(
              children: [
                _ActionTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.info_outline,
                  title: 'About HostelHub',
                  trailing: const Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Sign Out ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                onPressed: () => _confirmSignOut(context, ref),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Biometric toggle ────────────────────────────────────────────────────────

  Future<void> _toggleBiometric(BuildContext context, bool enable) async {
    if (enable) {
      // Verify the device actually supports biometrics before enabling
      try {
        final auth = LocalAuthentication();
        final canCheck = await auth.canCheckBiometrics;
        final isSupported = await auth.isDeviceSupported();
        if (!canCheck && !isSupported) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Biometric authentication is not available on this device.',
                ),
              ),
            );
          }
          return;
        }
        // Do a test authenticate to confirm enrolment
        final confirmed = await auth.authenticate(
          localizedReason: 'Confirm your biometric to enable this feature',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (!confirmed) return;
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not verify biometrics. Please try again.'),
            ),
          );
        }
        return;
      }
    }
    ref.read(biometricEnabledProvider.notifier).setEnabled(enable);
  }

  // ── Change Password dialog ──────────────────────────────────────────────────

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Text('A password reset link will be sent to\n${user.email}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(authServiceProvider).resetPassword(user.email);
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
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── About dialog ────────────────────────────────────────────────────────────

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'HostelHub',
      applicationVersion: '1.0.0',
      applicationLegalese:
          '© 2026 Ashesi University — Team KNCF\n'
          'Built with Flutter & Firebase',
    );
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────────

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of HostelHub?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(authServiceProvider).logout();
      } catch (_) {}
      try {
        await ref.read(notificationServiceProvider).unsubscribeAll();
      } catch (_) {}
      ref.read(currentUserProvider.notifier).state = null;
      if (context.mounted) context.go('/login');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header — theme-aware
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String tag;
  final bool isAdmin;

  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.tag,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardOf(context),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMutedOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isAdmin
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isAdmin ? AppColors.warning : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable layout helpers — theme-aware
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.textMutedOf(context),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.textMutedOf(context), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textOf(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context)),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: AppColors.textMutedOf(context), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textOf(context),
        ),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: AppColors.textMutedOf(context)),
      onTap: onTap,
    );
  }
}
