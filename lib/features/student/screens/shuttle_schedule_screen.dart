import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/shuttle_booking.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-08 — Shuttle schedules (Firestore: active schedules with departureTime)
// ─────────────────────────────────────────────────────────────────────────────

class ShuttleScheduleScreen extends ConsumerWidget {
  const ShuttleScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shuttleSchedulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuttle'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/shuttle/bookings'),
            icon: const Icon(Icons.bookmark_outlined,
                color: Colors.white, size: 18),
            label: const Text(
              'My Bookings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: async.when(
        data: (schedules) {
          if (schedules.isEmpty) {
            return const Center(
              child: Text(
                'No shuttle schedules yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final m = schedules[index];
              return _ScheduleCard(map: m, ref: ref);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load schedules.\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> map;
  final WidgetRef ref;

  const _ScheduleCard({required this.map, required this.ref});

  @override
  Widget build(BuildContext context) {
    final scheduleId = map['scheduleId'] as String? ?? '';
    final routeName = map['routeName'] as String? ??
        map['name'] as String? ??
        'Campus shuttle';
    final pickup = map['pickupPoint'] as String? ?? '';
    final dest = map['destination'] as String? ?? '';
    final dep = map['departureTime'];
    DateTime when;
    if (dep is Timestamp) {
      when = dep.toDate();
    } else {
      when = DateTime.now();
    }
    final total =
        (map['totalSeats'] ?? map['capacity'] ?? 20) as int;
    final booked = (map['bookedSeats'] ?? 0) as int;
    final avail = (total - booked).clamp(0, total);
    final timeStr = DateFormat('HH:mm').format(when);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (pickup.isNotEmpty || dest.isNotEmpty)
              Text(
                '$pickup → $dest',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '$avail / $total seats',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: total > 0 ? booked / total : 0,
              backgroundColor: AppColors.divider,
              minHeight: 6,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: avail <= 0
                    ? null
                    : () => _book(context, ref, scheduleId, pickup, dest),
                child: const Text('Book seat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _book(
    BuildContext context,
    WidgetRef ref,
    String scheduleId,
    String pickup,
    String dest,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to book a seat.')),
      );
      return;
    }
    if (scheduleId.isEmpty) return;

    try {
      final bookingId =
          'bk_${const Uuid().v4().replaceAll('-', '').substring(0, 12)}';
      final booking = ShuttleBooking(
        bookingId: bookingId,
        studentUid: user.uid,
        scheduleId: scheduleId,
        pickupPoint: pickup,
        destination: dest,
        bookingTime: DateTime.now(),
      );
      await ref.read(firestoreServiceProvider).bookShuttle(booking);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seat booked'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }
}
