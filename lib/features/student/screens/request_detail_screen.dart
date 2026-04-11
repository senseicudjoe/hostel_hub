import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/maintenance_request.dart';
import '../../../shared/widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-07 — Maintenance Request Detail (Firestore)
// ─────────────────────────────────────────────────────────────────────────────

const _stages = [
  'Submitted',
  'Acknowledged',
  'Assigned',
  'In Progress',
  'Resolved',
];

int _timelineIndex(String status) {
  switch (status.toLowerCase()) {
    case 'submitted':
    case 'pending':
      return 0;
    case 'acknowledged':
      return 1;
    case 'assigned':
      return 2;
    case 'in_progress':
      return 3;
    case 'resolved':
      return 4;
    default:
      return 0;
  }
}

class RequestDetailScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(maintenanceRequestProvider(requestId));

    return async.when(
      data: (req) {
        if (req == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Request')),
            body: const Center(child: Text('Request not found.')),
          );
        }
        return _detailBody(context, req);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Request')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Request')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load request.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

Widget _detailBody(BuildContext context, MaintenanceRequest req) {
  final currentStageIndex = _timelineIndex(req.status);
  final dateStr = DateFormat('MMM d, y').format(req.createdAt);
  final roomLabel =
      req.roomNumber.isNotEmpty ? req.roomNumber : '—';

  return Scaffold(
    appBar: AppBar(
      title: Text(req.requestId),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  req.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: req.status),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.label_outline, label: req.category),
              _MetaChip(
                  icon: Icons.meeting_room_outlined, label: roomLabel),
              _MetaChip(
                  icon: Icons.calendar_today_outlined, label: dateStr),
            ],
          ),
          const SizedBox(height: 16),
          const _CardSection(title: 'Description'),
          const SizedBox(height: 8),
          Text(
            req.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          if (req.imageUrls.isNotEmpty) ...[
            const _CardSection(title: 'Attached Photos'),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: req.imageUrls
                    .map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 100,
                              height: 100,
                              color: AppColors.primaryLight,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: AppColors.input,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const _CardSection(title: 'Status Timeline'),
          const SizedBox(height: 12),
          _StatusTimeline(
            stages: _stages,
            currentIndex: currentStageIndex.clamp(0, _stages.length - 1),
          ),
          const SizedBox(height: 20),
          if (req.assignedTo.isNotEmpty) ...[
            const _CardSection(title: 'Assigned Staff'),
            const SizedBox(height: 8),
            _StaffCard(name: req.assignedTo),
            const SizedBox(height: 20),
          ],
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
            SizedBox(
              width: 24,
              child: Column(
                children: [
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
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16),
              child: Text(
                stages[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
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
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
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
