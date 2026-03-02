import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-09 — My Shuttle Bookings
//
// Shows the student's upcoming and past shuttle bookings.
// Upcoming bookings show a cancel option.
// Past bookings are greyed out.
// ─────────────────────────────────────────────────────────────────────────────

final _upcomingBookings = [
  {
    'id': 'BK-001',
    'route': 'Main Gate → Academic Block',
    'time': '14:30',
    'date': 'Mon, Feb 23',
    'status': 'confirmed',
    'seat': '5',
  },
  {
    'id': 'BK-002',
    'route': 'Hostels → Academic Block',
    'time': '07:30',
    'date': 'Tue, Feb 24',
    'status': 'confirmed',
    'seat': '3',
  },
];

final _pastBookings = [
  {
    'id': 'BK-003',
    'route': 'Main Gate → Academic Block',
    'time': '08:30',
    'date': 'Fri, Feb 21',
    'status': 'confirmed',
    'seat': '12',
  },
  {
    'id': 'BK-004',
    'route': 'Academic Block → Main Gate',
    'time': '17:30',
    'date': 'Thu, Feb 20',
    'status': 'cancelled',
    'seat': '—',
  },
];

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        body: TabBarView(
          children: [
            _BookingList(
              bookings: _upcomingBookings,
              showCancel: true,
            ),
            _BookingList(
              bookings: _pastBookings,
              showCancel: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;
  final bool showCancel;

  const _BookingList({required this.bookings, required this.showCancel});

  @override
  State<_BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<_BookingList> {
  final Set<String> _cancelled = {};

  @override
  Widget build(BuildContext context) {
    if (widget.bookings.isEmpty) {
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
      itemCount: widget.bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final b = widget.bookings[i];
        final isCancelled = _cancelled.contains(b['id']);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_bus_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['route'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${b['time']} · ${b['date']}',
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
                    StatusChip(
                      status: isCancelled ? 'cancelled' : b['status'] as String,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Boarding pass info
                Row(
                  children: [
                    _InfoPill(
                        icon: Icons.event_seat_rounded,
                        label: 'Seat ${b['seat']}'),
                    const SizedBox(width: 8),
                    _InfoPill(
                        icon: Icons.confirmation_num_outlined,
                        label: b['id'] as String),
                    const Spacer(),
                    if (widget.showCancel && !isCancelled)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          setState(() => _cancelled.add(b['id'] as String));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking cancelled'),
                            ),
                          );
                        },
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
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
