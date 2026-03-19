import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-05 — Maintenance List Screen
//
// Shows all maintenance requests submitted by the student.
// Tab filters: All / Pending / In Progress / Resolved
// FAB to submit a new request.
// ─────────────────────────────────────────────────────────────────────────────

// Mock data — in a real app this comes from FirestoreService.getStudentMaintenanceRequests()
final _mockRequests = [
  {
    'id': 'REQ-001',
    'title': 'Broken ceiling fan',
    'category': 'Electrical',
    'status': 'in_progress',
    'room': 'U-204',
    'date': 'Feb 15, 2026',
    'description':
        'The ceiling fan in room U-204 is making a loud grinding noise and sometimes stops working entirely.',
  },
  {
    'id': 'REQ-002',
    'title': 'Leaking pipe under sink',
    'category': 'Plumbing',
    'status': 'pending',
    'room': 'U-204',
    'date': 'Feb 18, 2026',
    'description':
        'Water is dripping steadily from the pipe joint under the bathroom sink.',
  },
  {
    'id': 'REQ-003',
    'title': 'Broken window lock',
    'category': 'General',
    'status': 'resolved',
    'room': 'U-204',
    'date': 'Feb 10, 2026',
    'description': 'The window lock is broken and the window cannot be secured.',
  },
  {
    'id': 'REQ-004',
    'title': 'No hot water',
    'category': 'Plumbing',
    'status': 'acknowledged',
    'room': 'U-204',
    'date': 'Feb 20, 2026',
    'description': 'Hot water has not been available for 3 days.',
  },
  {
    'id': 'REQ-005',
    'title': 'Power socket not working',
    'category': 'Electrical',
    'status': 'submitted',
    'room': 'U-204',
    'date': 'Feb 22, 2026',
    'description': 'The power socket near my study desk has stopped working.',
  },
];

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen>
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

  List<Map<String, dynamic>> _filtered(String? status) {
    if (status == null) return _mockRequests;
    return _mockRequests
        .where((r) => r['status'] == status)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestList(requests: _filtered(null)),
          _RequestList(requests: _filtered('pending')),
          _RequestList(requests: _filtered('in_progress')),
          _RequestList(requests: _filtered('resolved')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/maintenance/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Request List
// ─────────────────────────────────────────────────────────────────────────────

class _RequestList extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  const _RequestList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'No requests here',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _RequestCard(request: requests[index]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Request Card
// ─────────────────────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final categoryIcon = _categoryIcon(request['category'] as String);

    return GestureDetector(
      onTap: () => context.go('/maintenance/${request['id']}'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
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
                            request['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status: request['status'] as String),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request['description'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.meeting_room_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          request['room'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          request['date'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
