import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-14 — Admin Maintenance Management
//
// Full list of all maintenance requests across all hostels.
// Features:
//   • Filter by status (All / Pending / In Progress / Resolved)
//   • Search by request ID or title
//   • Assign to staff via bottom sheet
//   • Priority flags
// ─────────────────────────────────────────────────────────────────────────────

final _allRequests = [
  _AdminRequest(
    id: 'REQ-001', title: 'Broken ceiling fan', category: 'Electrical',
    status: 'in_progress', room: 'U-204', hostel: 'Unity Hall',
    submittedBy: 'Kofi Mensah', date: 'Feb 15', assignedTo: 'Kweku Asante',
    priority: 'high',
  ),
  _AdminRequest(
    id: 'REQ-002', title: 'Leaking pipe under sink', category: 'Plumbing',
    status: 'pending', room: 'U-204', hostel: 'Unity Hall',
    submittedBy: 'Kofi Mensah', date: 'Feb 18', assignedTo: '',
    priority: 'medium',
  ),
  _AdminRequest(
    id: 'REQ-003', title: 'Broken window lock', category: 'General',
    status: 'resolved', room: 'U-204', hostel: 'Unity Hall',
    submittedBy: 'Kofi Mensah', date: 'Feb 10', assignedTo: 'Yaw Darko',
    priority: 'low',
  ),
  _AdminRequest(
    id: 'REQ-006', title: 'Broken door hinge', category: 'Structural',
    status: 'pending', room: 'F-102', hostel: 'Freedom Hall',
    submittedBy: 'Abena Osei', date: 'Feb 19', assignedTo: '',
    priority: 'medium',
  ),
  _AdminRequest(
    id: 'REQ-007', title: 'No electricity in bathroom', category: 'Electrical',
    status: 'acknowledged', room: 'I-301', hostel: 'Independence Hall',
    submittedBy: 'Kwame Boateng', date: 'Feb 21', assignedTo: '',
    priority: 'high',
  ),
  _AdminRequest(
    id: 'REQ-008', title: 'Mold on ceiling', category: 'Cleaning',
    status: 'assigned', room: 'F-205', hostel: 'Freedom Hall',
    submittedBy: 'Ama Sarpong', date: 'Feb 17', assignedTo: 'Cleaning Team',
    priority: 'medium',
  ),
];

class _AdminRequest {
  final String id, title, category, status, room, hostel;
  final String submittedBy, date, assignedTo, priority;
  const _AdminRequest({
    required this.id, required this.title, required this.category,
    required this.status, required this.room, required this.hostel,
    required this.submittedBy, required this.date, required this.assignedTo,
    required this.priority,
  });
}

class AdminMaintenanceScreen extends StatefulWidget {
  const AdminMaintenanceScreen({super.key});

  @override
  State<AdminMaintenanceScreen> createState() =>
      _AdminMaintenanceScreenState();
}

class _AdminMaintenanceScreenState extends State<AdminMaintenanceScreen> {
  String _statusFilter = 'All';
  String _searchQuery = '';

  List<_AdminRequest> get _filtered {
    return _allRequests.where((r) {
      final matchesStatus = _statusFilter == 'All' ||
          r.status.toLowerCase().contains(_statusFilter.toLowerCase()) ||
          (_statusFilter == 'Pending' && r.status == 'pending') ||
          (_statusFilter == 'In Progress' && r.status == 'in_progress') ||
          (_statusFilter == 'Resolved' && r.status == 'resolved');

      final matchesSearch = _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery) ||
          r.id.toLowerCase().contains(_searchQuery) ||
          r.submittedBy.toLowerCase().contains(_searchQuery);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export CSV',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exporting to CSV...')),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search by request ID, title, or student...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),

          // ── Status filter chips ──────────────────────────
          Container(
            color: Colors.white,
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

          // ── Count ─────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filtered.length} request${_filtered.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ── Request list ─────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('No requests match your filter',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) => _AdminRequestCard(
                      request: _filtered[i],
                      onAssign: () =>
                          _showAssignSheet(context, _filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAssignSheet(BuildContext context, _AdminRequest req) {
    const staff = ['Kweku Asante', 'Yaw Darko', 'Cleaning Team', 'Kojo Aidoo'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign ${req.id}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(req.title,
                style: const TextStyle(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            const Text(
              'Select Staff Member',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...staff.map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(s[0],
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  title: Text(s,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: req.assignedTo == s
                      ? const Text('Currently assigned',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('${req.id} assigned to $s')),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Request Card
// ─────────────────────────────────────────────────────────────────────────────

class _AdminRequestCard extends StatelessWidget {
  final _AdminRequest request;
  final VoidCallback onAssign;

  const _AdminRequestCard({required this.request, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    final (priorityColor, priorityLabel) = switch (request.priority) {
      'high' => (AppColors.error, 'High'),
      'medium' => (AppColors.warning, 'Med'),
      _ => (AppColors.success, 'Low'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Priority flag
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  request.id,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                StatusChip(status: request.status),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              request.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            // Metadata row
            Wrap(
              spacing: 8,
              children: [
                _metaTag(Icons.apartment_rounded,
                    '${request.hostel} · ${request.room}'),
                _metaTag(Icons.person_outline, request.submittedBy),
                _metaTag(Icons.calendar_today_outlined, request.date),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                if (request.assignedTo.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.engineering_rounded,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          request.assignedTo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      'Unassigned',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: onAssign,
                  child: Text(
                    request.assignedTo.isEmpty ? 'Assign' : 'Reassign',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
