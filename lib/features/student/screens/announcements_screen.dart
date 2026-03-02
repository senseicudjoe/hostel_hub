import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-10 — Announcements Screen
//
// Shows hostel announcements in chronological order.
// Tapping an announcement expands it.
// Admin users see a "Compose" FAB to post new announcements (routes to S-15).
// ─────────────────────────────────────────────────────────────────────────────

final _mockAnnouncements = [
  _Announcement(
    id: 'ann_001',
    title: 'Water Outage Notice',
    body:
        'There will be a scheduled water outage in Unity Hall and Freedom Hall on Saturday, February 25th from 6AM to 12PM for maintenance work on the main supply pipe. Please store water in advance.',
    date: 'Feb 23, 2026',
    author: 'SLE Office',
    target: 'All Residents',
    isUnread: true,
    icon: Icons.water_drop_outlined,
    iconColor: AppColors.info,
  ),
  _Announcement(
    id: 'ann_002',
    title: 'Hostel Inspection Next Week',
    body:
        'The annual hostel room inspection will take place from Monday to Wednesday next week. Please ensure your rooms are tidy, all electrical appliances are approved, and no prohibited items are present.',
    date: 'Feb 20, 2026',
    author: 'Hostel Manager',
    target: 'All Residents',
    isUnread: true,
    icon: Icons.search_rounded,
    iconColor: AppColors.warning,
  ),
  _Announcement(
    id: 'ann_003',
    title: 'New Shuttle Route from March 1st',
    body:
        'Starting March 1st, a new shuttle route will be added connecting Independence Hall directly to the Academic Block. Departure times: 7:15AM, 12:30PM, and 5:45PM. Check the Shuttle tab for the full schedule.',
    date: 'Feb 18, 2026',
    author: 'SLE Office',
    target: 'Students',
    isUnread: false,
    icon: Icons.directions_bus_rounded,
    iconColor: AppColors.success,
  ),
  _Announcement(
    id: 'ann_004',
    title: 'Laundry Room Schedule Update',
    body:
        'The laundry room hours have been extended. New hours are 6AM to 10PM daily. Please note that the laundry room will be closed for deep cleaning every Sunday from 2PM to 4PM.',
    date: 'Feb 15, 2026',
    author: 'Unity Hall Porter',
    target: 'Unity Hall',
    isUnread: false,
    icon: Icons.local_laundry_service_rounded,
    iconColor: AppColors.primaryDark,
  ),
];

class _Announcement {
  final String id;
  final String title;
  final String body;
  final String date;
  final String author;
  final String target;
  final bool isUnread;
  final IconData icon;
  final Color iconColor;

  const _Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.author,
    required this.target,
    required this.isUnread,
    required this.icon,
    required this.iconColor,
  });
}

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState
    extends ConsumerState<AnnouncementsScreen> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    // Count unread to show in badge.
    final unreadCount =
        _mockAnnouncements.where((a) => a.isUnread).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Announcements'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unreadCount new',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mockAnnouncements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final a = _mockAnnouncements[index];
          final isExpanded = _expanded.contains(a.id);

          return _AnnouncementCard(
            announcement: a,
            isExpanded: isExpanded,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expanded.remove(a.id);
                } else {
                  _expanded.add(a.id);
                }
              });
            },
          );
        },
      ),
      // Admin users get a FAB to compose a new announcement.
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/admin/announcements/compose'),
              icon: const Icon(Icons.add),
              label: const Text('Compose'),
            )
          : null,
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final _Announcement announcement;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AnnouncementCard({
    required this.announcement,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final a = announcement;

    return GestureDetector(
      onTap: onToggle,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: a.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(a.icon, color: a.iconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Unread dot
                            if (a.isUnread)
                              Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                a.title,
                                style: TextStyle(
                                  fontWeight: a.isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              a.author,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              ' · ',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 11),
                            ),
                            Text(
                              a.date,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),

              // Expanded body
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  a.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                // Target audience tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.input,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        a.target,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
