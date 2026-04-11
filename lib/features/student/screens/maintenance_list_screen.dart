import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Maintenance'),
      ),
      body: Column(
        children: [
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
