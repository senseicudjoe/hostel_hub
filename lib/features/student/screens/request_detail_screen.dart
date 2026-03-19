import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-07 — Maintenance Request Detail
//
// Shows the full details of a single maintenance request including:
//   • Title, category, status chip
//   • Metadata (room, submitted date)
//   • Status timeline (stepper showing each stage)
//   • Photo attachments
//   • Comments placeholder
// ─────────────────────────────────────────────────────────────────────────────

// All the stages a maintenance request goes through.
const _stages = [
  'Submitted',
  'Acknowledged',
  'Assigned',
  'In Progress',
  'Resolved',
];

// Maps each stage to its status string for colour lookup.
const _stageStatuses = [
  'submitted',
  'acknowledged',
  'assigned',
  'in_progress',
  'resolved',
];

class RequestDetailScreen extends StatelessWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  // Find mock data matching the id (falls back to default).
  Map<String, dynamic> get _request => _mockData[requestId] ??
      _mockData.values.first;

  @override
  Widget build(BuildContext context) {
    final req = _request;
    final currentStageIndex = _stageStatuses.indexOf(req['status'] as String);

    return Scaffold(
      appBar: AppBar(
        title: Text(req['id'] as String),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    req['title'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(status: req['status'] as String),
              ],
            ),

            const SizedBox(height: 16),

            // ── Metadata chips ───────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                    icon: Icons.label_outline,
                    label: req['category'] as String),
                _MetaChip(
                    icon: Icons.meeting_room_outlined,
                    label: req['room'] as String),
                _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: req['date'] as String),
              ],
            ),

            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────
            const _CardSection(title: 'Description'),
            const SizedBox(height: 8),
            Text(
              req['description'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 20),

            // ── Photo Attachments ─────────────────────────────
            if (req['hasPhoto'] == true) ...[
              const _CardSection(title: 'Attached Photos'),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: List.generate(
                    2,
                    (i) => Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.primary, size: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Status Timeline ───────────────────────────────
            const _CardSection(title: 'Status Timeline'),
            const SizedBox(height: 12),
            _StatusTimeline(
              stages: _stages,
              currentIndex: currentStageIndex,
            ),

            const SizedBox(height: 20),

            // ── Assigned Staff ────────────────────────────────
            if (req['assignedTo'] != null &&
                (req['assignedTo'] as String).isNotEmpty) ...[
              const _CardSection(title: 'Assigned Staff'),
              const SizedBox(height: 8),
              _StaffCard(name: req['assignedTo'] as String),
              const SizedBox(height: 20),
            ],

            // ── Comments placeholder ──────────────────────────
            const _CardSection(title: 'Comments'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.input,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'No comments yet.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Timeline Widget
// ─────────────────────────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final List<String> stages;
  final int currentIndex;

  const _StatusTimeline({
    required this.stages,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stages.length, (i) {
        final isDone = i <= currentIndex;
        final isCurrent = i == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: dot + line ─────────────────────────
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  // Circle dot
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.primary : AppColors.divider,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: AppColors.primary, width: 3)
                          : null,
                    ),
                    child: isDone && !isCurrent
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 12)
                        : null,
                  ),
                  // Vertical line (not after last item)
                  if (i < stages.length - 1)
                    Container(
                      width: 2,
                      height: 32,
                      color: i < currentIndex
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Right: label ──────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16),
              child: Text(
                stages[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isDone
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _CardSection extends StatelessWidget {
  final String title;
  const _CardSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final String name;
  const _StaffCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.success.withOpacity(0.15),
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const Text('Maintenance Staff',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock detail data (keyed by request id)
// ─────────────────────────────────────────────────────────────────────────────

final _mockData = {
  'REQ-001': {
    'id': 'REQ-001',
    'title': 'Broken ceiling fan',
    'category': 'Electrical',
    'status': 'in_progress',
    'room': 'U-204',
    'date': 'Feb 15, 2026',
    'description':
        'The ceiling fan in room U-204 is making a loud grinding noise and sometimes stops working entirely. It started two weeks ago and has been getting worse. The room gets very hot at night without the fan.',
    'hasPhoto': true,
    'assignedTo': 'Kweku Asante',
  },
  'REQ-002': {
    'id': 'REQ-002',
    'title': 'Leaking pipe under sink',
    'category': 'Plumbing',
    'status': 'pending',
    'room': 'U-204',
    'date': 'Feb 18, 2026',
    'description':
        'Water is dripping steadily from the pipe joint under the bathroom sink. There is already some water damage on the cabinet floor.',
    'hasPhoto': false,
    'assignedTo': '',
  },
  'REQ-003': {
    'id': 'REQ-003',
    'title': 'Broken window lock',
    'category': 'General',
    'status': 'resolved',
    'room': 'U-204',
    'date': 'Feb 10, 2026',
    'description': 'The window lock was broken and the window could not be secured at night.',
    'hasPhoto': false,
    'assignedTo': 'Maintenance Team',
  },
  'REQ-004': {
    'id': 'REQ-004',
    'title': 'No hot water',
    'category': 'Plumbing',
    'status': 'acknowledged',
    'room': 'U-204',
    'date': 'Feb 20, 2026',
    'description': 'Hot water has not been available for 3 days. Cold showers only.',
    'hasPhoto': false,
    'assignedTo': '',
  },
  'REQ-005': {
    'id': 'REQ-005',
    'title': 'Power socket not working',
    'category': 'Electrical',
    'status': 'submitted',
    'room': 'U-204',
    'date': 'Feb 22, 2026',
    'description': 'The power socket near my study desk has stopped working. I cannot charge my laptop.',
    'hasPhoto': true,
    'assignedTo': '',
  },
};
