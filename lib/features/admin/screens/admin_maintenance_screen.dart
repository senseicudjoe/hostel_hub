import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/async_refresh.dart';
import '../../../core/cache/app_image_caches.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/maintenance_request.dart';
import '../../../shared/widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-14 — Admin maintenance (Firestore)
// ─────────────────────────────────────────────────────────────────────────────

class AdminMaintenanceScreen extends ConsumerStatefulWidget {
  const AdminMaintenanceScreen({super.key});

  @override
  ConsumerState<AdminMaintenanceScreen> createState() =>
      _AdminMaintenanceScreenState();
}

class _AdminMaintenanceScreenState
    extends ConsumerState<AdminMaintenanceScreen> {
  String _statusFilter = 'All';
  String _searchQuery = '';

  List<MaintenanceRequest> _applyFilter(List<MaintenanceRequest> all) {
    return all.where((r) {
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Pending' && r.status == 'pending') ||
          (_statusFilter == 'In Progress' && r.status == 'in_progress') ||
          (_statusFilter == 'Resolved' && r.status == 'resolved');

      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          r.title.toLowerCase().contains(q) ||
          r.requestId.toLowerCase().contains(q) ||
          r.studentUid.toLowerCase().contains(q);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allMaintenanceRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
      ),
      body: async.when(
        data: (all) {
          final filtered = _applyFilter(all);
          return Column(
            children: [
              Container(
                color: AppColors.cardOf(context),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: TextField(
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search by ID, title, or student UID...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Container(
                color: AppColors.cardOf(context),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Pending', 'In Progress', 'Resolved']
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(s),
                                selected: _statusFilter == s,
                                onSelected: (_) =>
                                    setState(() => _statusFilter = s),
                                selectedColor: AppColors.primaryLight,
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _statusFilter == s
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const Divider(height: 1),
              Container(
                color: AppColors.surface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length} request${filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.refreshProvider(allMaintenanceRequestsProvider),
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.sizeOf(context).height * 0.55,
                              child: const Center(
                                child: Text(
                                  'No requests match your filter',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final r = filtered[i];
                            return _RequestTile(
                              request: r,
                              onAssign: (name) async {
                                await ref
                                    .read(firestoreServiceProvider)
                                    .updateMaintenanceStatus(
                                      requestId: r.requestId,
                                      status: 'assigned',
                                      assignedTo: name,
                                    );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${r.requestId} assigned to $name',
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => RefreshIndicator(
          onRefresh: () =>
              ref.refreshProvider(allMaintenanceRequestsProvider),
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
              ref.refreshProvider(allMaintenanceRequestsProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: Center(child: Text('$e', textAlign: TextAlign.center)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final MaintenanceRequest request;
  final void Function(String staffName) onAssign;

  const _RequestTile({
    required this.request,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, y').format(request.createdAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.requestId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${request.category} · ${request.hostelName.isNotEmpty ? request.hostelName : '—'} · ${request.roomNumber.isNotEmpty ? request.roomNumber : '—'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              'Student: ${request.studentUid}',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            Text(dateStr,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            if (request.assignedTo.isNotEmpty)
              Text('Assigned: ${request.assignedTo}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.success)),
            if (request.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: request.imageUrls.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: request.imageUrls[i],
                      cacheManager: AppImageCaches.maintenance,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.inputOf(context),
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.inputOf(context),
                        child: const Icon(Icons.broken_image_outlined, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _pickStaff(context),
                child: const Text('Assign staff'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickStaff(BuildContext context) {
    const staff = ['Kweku Asante', 'Yaw Darko', 'Cleaning Team', 'Kojo Aidoo'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: staff
              .map(
                (s) => ListTile(
                  title: Text(s),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAssign(s);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
