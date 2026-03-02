import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-03 — Student Dashboard
//
// The first thing a student sees after logging in.
//   • Personalised greeting with date
//   • Room summary card
//   • Quick-action grid (4 tiles)
//   • Announcements ticker / preview list
// ─────────────────────────────────────────────────────────────────────────────

// Mock announcements shown in the ticker.
const _announcements = [
  '📢 Water outage in Unity Hall — Saturday 6AM–12PM',
  '🔍 Annual hostel inspection Mon–Wed next week',
  '🚌 New shuttle route added from March 1st',
];

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  int _tickerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final firstName = user?.name.split(' ').first ?? 'Student';
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final dateStr = DateFormat('EEEE, d MMMM').format(now);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing AppBar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$greeting, $firstName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Notification bell
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () => context.go('/announcements'),
              ),
              // Profile circle
              IconButton(
                icon: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => context.go('/profile'),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Room Card ────────────────────────────────
                _RoomCard(user: user),

                const SizedBox(height: 20),

                // ── Quick Actions ────────────────────────────
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _QuickActionGrid(),

                const SizedBox(height: 20),

                // ── Announcements ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Announcements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/announcements'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _AnnouncementTicker(
                  message: _announcements[_tickerIndex],
                  onTap: () => setState(
                    () => _tickerIndex =
                        (_tickerIndex + 1) % _announcements.length,
                  ),
                ),

                const SizedBox(height: 12),
                ..._announcementPreviews,
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Returns a time-appropriate greeting string.
  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Preview cards for recent announcements.
  List<Widget> get _announcementPreviews => const [
    _AnnouncementPreviewCard(
      title: 'Water Outage Notice',
      body:
          'There will be a scheduled water outage in Unity Hall on Saturday from 6AM–12PM.',
      date: 'Today',
      isUnread: true,
    ),
    SizedBox(height: 8),
    _AnnouncementPreviewCard(
      title: 'Hostel Inspection Next Week',
      body:
          'The annual hostel room inspection will take place Mon–Wed next week.',
      date: 'Feb 20',
      isUnread: false,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Card widget
// ─────────────────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  final dynamic user;
  const _RoomCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Room',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.roomNumber ?? 'Not Assigned',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.hostel ?? '—',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Navigate button
          GestureDetector(
            onTap: () => context.go('/room'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action Grid
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _QuickActionTile(
          icon: Icons.build_rounded,
          label: 'Report\nIssue',
          color: const Color(0xFFA53A3E),
          onTap: () => context.go('/maintenance/new'),
        ),
        _QuickActionTile(
          icon: Icons.directions_bus_rounded,
          label: 'Book\nShuttle',
          color: const Color(0xFF1565C0),
          onTap: () => context.go('/shuttle'),
        ),
        _QuickActionTile(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan\nQR',
          color: const Color(0xFF2E7D32),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Scanner — open camera')),
          ),
        ),
        _QuickActionTile(
          icon: Icons.campaign_rounded,
          label: 'Announce-\nments',
          color: const Color(0xFF6A1B9A),
          onTap: () => context.go('/announcements'),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Announcement Ticker
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementTicker extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _AnnouncementTicker({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.campaign_rounded,
              color: AppColors.warning,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.warning, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Announcement Preview Card
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementPreviewCard extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final bool isUnread;

  const _AnnouncementPreviewCard({
    required this.title,
    required this.body,
    required this.date,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread indicator dot
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5, right: 10),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
