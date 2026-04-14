import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/cache/app_image_caches.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/async_refresh.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/maintenance_request.dart';
import '../../../shared/widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-05 — Maintenance List Screen
//
// Data: Firestore via [studentMaintenanceRequestsProvider].
// ─────────────────────────────────────────────────────────────────────────────

class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MaintenanceRequest> _filter(List<MaintenanceRequest> all, int tabIndex) {
    if (tabIndex == 0) return all;
    const want = ['pending', 'in_progress', 'resolved'];
    final s = want[tabIndex - 1];
    return all.where((r) => r.status == s).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentMaintenanceRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Maintenance'),
      ),
      body: Column(
        children: [
          // Offline queue banner — visible when requests are waiting to sync
          const _PendingSyncBanner(),

          // Tab bar strip — sits below the AppBar
          Container(
            color: AppColors.cardOf(context),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'In Progress'),
                Tab(text: 'Resolved'),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: async.when(
              data: (requests) => TabBarView(
                controller: _tabController,
                children: List.generate(4, (i) {
                  final filtered = _filter(requests, i);
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refreshProvider(studentMaintenanceRequestsProvider),
                    child: _RequestList(requests: filtered),
                  );
                }),
              ),
              loading: () => RefreshIndicator(
                onRefresh: () =>
                    ref.refreshProvider(studentMaintenanceRequestsProvider),
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
                onRefresh: () =>
                    ref.refreshProvider(studentMaintenanceRequestsProvider),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.55,
                      child: Center(
                        child: Text(
                          'Could not load requests.\n$e',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/maintenance/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<MaintenanceRequest> requests;
  const _RequestList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No requests here',
                    style: TextStyle(
                      color: AppColors.textMutedOf(context),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _RequestCard(request: requests[index]);
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final MaintenanceRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final categoryIcon = _categoryIcon(request.category);
    final dateStr = DateFormat('MMM d, y').format(request.createdAt);
    final roomLabel = request.roomNumber.isNotEmpty ? request.roomNumber : '—';

    return GestureDetector(
      onTap: () => context.push('/maintenance/${request.requestId}'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            request.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textOf(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status: request.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOf(context),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 13,
                          color: AppColors.textMutedOf(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          roomLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.textMutedOf(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ],
                    ),
                    if (request.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            for (final url in request.imageUrls.take(3))
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    cacheManager: AppImageCaches.maintenance,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppColors.primaryLight,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: 48,
                                      height: 48,
                                      color: AppColors.input,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (request.imageUrls.length > 3)
                              Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.input,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${request.imageUrls.length - 3}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMutedOf(context),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'furniture':
        return Icons.chair_rounded;
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.build_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending Sync Banner
//
// Shown at the top of the list when there are requests in the offline queue.
// Disappears automatically once the queue is flushed.
// ─────────────────────────────────────────────────────────────────────────────

class _PendingSyncBanner extends ConsumerWidget {
  const _PendingSyncBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingRequestCountProvider);
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? true;

    if (count == 0) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(count),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isOnline
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.warning.withValues(alpha: 0.12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: isOnline
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.success,
                    )
                  : const Icon(
                      Icons.cloud_off_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isOnline
                    ? 'Syncing $count offline ${count == 1 ? 'request' : 'requests'}…'
                    : '$count ${count == 1 ? 'request' : 'requests'} queued — will sync when back online',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
