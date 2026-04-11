import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/async_refresh.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/announcement.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-10 — Announcements (Firestore)
// ─────────────────────────────────────────────────────────────────────────────

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final Set<String> _expanded = {};

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission-denied')) {
      return 'Announcements are unavailable for this account right now.';
    }
    return 'Could not load announcements right now.';
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final role = ref.watch(userRoleProvider);
    final async = ref.watch(announcementsForRoleProvider(role));
    final pullHeight = MediaQuery.sizeOf(context).height * 0.55;

    Future<void> onPull() =>
        ref.refreshProvider(announcementsForRoleProvider(role));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Announcements'),
            async.maybeWhen(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${list.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: onPull,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: pullHeight,
                    child: Center(
                      child: Text(
                        'No announcements yet.',
                        style:
                            TextStyle(color: AppColors.textMutedOf(context)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: onPull,
            child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final a = list[index];
              final id = a.announcementId;
              final isExpanded = _expanded.contains(id);
              return _AnnouncementCard(
                announcement: a,
                isExpanded: isExpanded,
                onToggle: () {
                  setState(() {
                    if (isExpanded) {
                      _expanded.remove(id);
                    } else {
                      _expanded.add(id);
                    }
                  });
                },
              );
            },
            ),
          );
        },
        loading: () => RefreshIndicator(
          onRefresh: onPull,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        error: (e, _) => RefreshIndicator(
          onRefresh: onPull,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              SizedBox(
                height: pullHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      size: 44,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _friendlyError(e),
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppColors.textMutedOf(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/announcements/compose'),
              icon: const Icon(Icons.add),
              label: const Text('Compose'),
            )
          : null,
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
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
    final dateStr = DateFormat('MMM d, y').format(a.createdAt);

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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textOf(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              a.sentBy,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMutedOf(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' · ',
                              style: TextStyle(
                                color: AppColors.textMutedOf(context),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMutedOf(context),
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
                    color: AppColors.textMutedOf(context),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  a.body,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMutedOf(context),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputOf(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 13,
                        color: AppColors.textMutedOf(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        a.targetRole,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedOf(context),
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
