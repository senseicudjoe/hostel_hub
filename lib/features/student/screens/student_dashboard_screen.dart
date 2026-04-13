import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/announcement.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/time_of_day_greeting.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/async_refresh.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-03 — Student Dashboard
//
// Announcements: Firestore via [announcementsForRoleProvider].
// ─────────────────────────────────────────────────────────────────────────────

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  String _friendlyAnnouncementError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission-denied')) {
      return 'Announcements are unavailable for your account right now.';
    }
    return 'Announcements are unavailable right now.';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final announcementsAsync = ref.watch(
      announcementsForRoleProvider(AppConstants.roleStudent),
    );
    final firstName = user?.name.split(' ').first ?? 'Student';
    final now = DateTime.now();
    final greeting = timeOfDayGreeting(now.hour);
    final dateStr = DateFormat('EEEE, d MMMM').format(now);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refreshProvider(
          announcementsForRoleProvider(AppConstants.roleStudent),
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        color: Colors.white.withValues(alpha: 0.8),
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
                onPressed: () => context.go('/home/announcements'),
              ),
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
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOf(context),
                  ),
                ),
                const SizedBox(height: 12),
                _QuickActionGrid(),

                const SizedBox(height: 20),

                // ── Announcements ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Announcements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOf(context),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home/announcements'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                announcementsAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No announcements yet.',
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      );
                    }
                    final ticker = list.map((a) => '📢 ${a.title}').toList();
                    return _AnnouncementTicker(
                      message: ticker.first,
                      onTap: () => context.go('/home/announcements'),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _AnnouncementStatusCard(
                      message: _friendlyAnnouncementError(e),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                ..._announcementPreviews(context, announcementsAsync),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
        ),
      ),
    );
  }

  List<Widget> _announcementPreviews(
    BuildContext context,
    AsyncValue<List<Announcement>> announcementsAsync,
  ) {
    return announcementsAsync.maybeWhen(
      data: (list) {
        if (list.isEmpty) return <Widget>[];
        return list.take(2).map((a) {
          final date = DateFormat('MMM d').format(a.createdAt);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => context.go('/home/announcements'),
              behavior: HitTestBehavior.opaque,
              child: _AnnouncementPreviewCard(
                title: a.title,
                body: a.body,
                date: date,
                isUnread: false,
              ),
            ),
          );
        }).toList();
      },
      orElse: () => <Widget>[],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Card widget
// ─────────────────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  final dynamic user;
  const _RoomCard({this.user});

  bool get _hasRoom =>
      (user?.roomNumber?.toString().trim().isNotEmpty ?? false) &&
      (user?.hostel?.toString().trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    if (!_hasRoom) {
      // ── No room booked yet ──────────────────────────────
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.dividerOf(context),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hotel_outlined,
                  color: AppColors.warning, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No room booked yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOf(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Browse available rooms and book one.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => context.go('/explore'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(72, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Explore'),
            ),
          ],
        ),
      );
    }

    // ── Room assigned ───────────────────────────────────
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
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.roomNumber ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.hostel ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/room'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
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
          onTap: () => context.push('/maintenance/new'),
        ),
        _QuickActionTile(
          icon: Icons.meeting_room_rounded,
          label: 'Rooms',
          color: const Color(0xFF1565C0),
          onTap: () => context.go('/explore'),
        ),
        _QuickActionTile(
          icon: Icons.hotel_rounded,
          label: 'My\nRoom',
          color: const Color(0xFF2E7D32),
          onTap: () => context.go('/room'),
        ),
        _QuickActionTile(
          icon: Icons.campaign_rounded,
          label: 'Announce-\nments',
          color: const Color(0xFF6A1B9A),
          onTap: () => context.go('/home/announcements'),
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
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
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
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
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textOf(context),
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

class _AnnouncementStatusCard extends StatelessWidget {
  final String message;

  const _AnnouncementStatusCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textHint, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ),
        ],
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
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMutedOf(context),
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
