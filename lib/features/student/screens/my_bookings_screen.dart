import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/shuttle_booking.dart';
import '../../../shared/widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-09 — My Shuttle Bookings (Firestore)
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentShuttleBookingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: async.when(
          data: (bookings) {
            final now = DateTime.now();
            final upcoming = bookings
                .where((b) =>
                    b.status != AppConstants.statusCancelled &&
                    b.bookingTime.isAfter(now.subtract(const Duration(hours: 1))))
                .toList();
            final past = bookings
                .where((b) =>
                    b.bookingTime.isBefore(now.subtract(const Duration(hours: 1))) ||
                    b.status == AppConstants.statusCancelled)
                .toList();

            return TabBarView(
              children: [
                _BookingList(
                  bookings: upcoming,
                  showCancel: true,
                  ref: ref,
                ),
                _BookingList(
                  bookings: past,
                  showCancel: false,
                  ref: ref,
                ),
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<ShuttleBooking> bookings;
  final bool showCancel;
  final WidgetRef ref;

  const _BookingList({
    required this.bookings,
    required this.showCancel,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_outlined,
                size: 56, color: AppColors.textHint),
            SizedBox(height: 12),
            Text(
              'No bookings yet',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final b = bookings[index];
        final dateStr = DateFormat('EEE, MMM d').format(b.bookingTime);
        final timeStr = DateFormat('HH:mm').format(b.bookingTime);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${b.pickupPoint} → ${b.destination}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    StatusChip(status: b.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$dateStr · $timeStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (showCancel && b.status == 'confirmed') ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(firestoreServiceProvider)
                              .cancelShuttleBooking(b.bookingId, b.scheduleId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking cancelled')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
