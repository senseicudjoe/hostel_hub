import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-08 — Shuttle Schedule Screen
//
// Students can:
//   • Switch between Today / Tomorrow date tabs
//   • See all shuttle routes with departure times
//   • Check seat availability (progress bar)
//   • Tap "Book" to reserve a seat
// ─────────────────────────────────────────────────────────────────────────────

// Mock shuttle route data.
final _mockRoutes = [
  _ShuttleRoute(
    name: 'Main Gate → Academic Block',
    icon: Icons.directions_bus_rounded,
    color: const Color(0xFF1565C0),
    runs: [
      _Run(time: '07:00', booked: 12, total: 20),
      _Run(time: '08:30', booked: 20, total: 20),
      _Run(time: '10:00', booked: 8, total: 20),
      _Run(time: '12:00', booked: 15, total: 20),
      _Run(time: '14:30', booked: 6, total: 20),
      _Run(time: '16:00', booked: 18, total: 20),
      _Run(time: '18:00', booked: 4, total: 20),
    ],
  ),
  _ShuttleRoute(
    name: 'Hostels → Academic Block',
    icon: Icons.apartment_rounded,
    color: const Color(0xFF2E7D32),
    runs: [
      _Run(time: '07:30', booked: 10, total: 15),
      _Run(time: '09:00', booked: 15, total: 15),
      _Run(time: '11:00', booked: 7, total: 15),
      _Run(time: '13:00', booked: 12, total: 15),
      _Run(time: '15:30', booked: 3, total: 15),
      _Run(time: '17:00', booked: 9, total: 15),
    ],
  ),
  _ShuttleRoute(
    name: 'Academic Block → Main Gate',
    icon: Icons.subdirectory_arrow_left_rounded,
    color: const Color(0xFF6A1B9A),
    runs: [
      _Run(time: '09:00', booked: 5, total: 20),
      _Run(time: '13:00', booked: 11, total: 20),
      _Run(time: '17:30', booked: 16, total: 20),
      _Run(time: '19:00', booked: 8, total: 20),
    ],
  ),
];

class _ShuttleRoute {
  final String name;
  final IconData icon;
  final Color color;
  final List<_Run> runs;
  const _ShuttleRoute(
      {required this.name,
      required this.icon,
      required this.color,
      required this.runs});
}

class _Run {
  final String time;
  final int booked;
  final int total;
  const _Run({required this.time, required this.booked, required this.total});
  bool get isFull => booked >= total;
  int get available => total - booked;
}

class ShuttleScheduleScreen extends StatefulWidget {
  const ShuttleScheduleScreen({super.key});

  @override
  State<ShuttleScheduleScreen> createState() => _ShuttleScheduleScreenState();
}

class _ShuttleScheduleScreenState extends State<ShuttleScheduleScreen> {
  int _dayIndex = 0; // 0 = Today, 1 = Tomorrow
  // Tracks which run the user has booked (routeIndex, runIndex)
  final Set<String> _bookedRuns = {};

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          // ── Day Selector ─────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _DayTab(
                    label: 'Today',
                    sublabel: 'Mon, Feb 23',
                    isSelected: _dayIndex == 0,
                    onTap: () => setState(() => _dayIndex = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DayTab(
                    label: 'Tomorrow',
                    sublabel: 'Tue, Feb 24',
                    isSelected: _dayIndex == 1,
                    onTap: () => setState(() => _dayIndex = 1),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Routes list ───────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockRoutes.length,
              itemBuilder: (context, routeIndex) {
                final route = _mockRoutes[routeIndex];
                return _RouteSection(
                  route: route,
                  routeIndex: routeIndex,
                  bookedRuns: _bookedRuns,
                  onBook: (runIndex) {
                    final key = '$routeIndex-$runIndex';
                    setState(() {
                      if (_bookedRuns.contains(key)) {
                        _bookedRuns.remove(key);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking cancelled'),
                          ),
                        );
                      } else {
                        _bookedRuns.add(key);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Seat booked on ${route.name} at ${route.runs[runIndex].time}'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day Tab ───────────────────────────────────────────────────────────────────

class _DayTab extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayTab({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.input,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.divider,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? AppColors.primary.withOpacity(0.7)
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Route Section ─────────────────────────────────────────────────────────────

class _RouteSection extends StatelessWidget {
  final _ShuttleRoute route;
  final int routeIndex;
  final Set<String> bookedRuns;
  final void Function(int runIndex) onBook;

  const _RouteSection({
    required this.route,
    required this.routeIndex,
    required this.bookedRuns,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: route.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(route.icon, color: route.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  route.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Run cards
        ...route.runs.asMap().entries.map((entry) {
          final runIndex = entry.key;
          final run = entry.value;
          final key = '$routeIndex-$runIndex';
          final isBooked = bookedRuns.contains(key);
          return _RunCard(
            run: run,
            isBooked: isBooked,
            color: route.color,
            onBook: () => onBook(runIndex),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Run Card ──────────────────────────────────────────────────────────────────

class _RunCard extends StatelessWidget {
  final _Run run;
  final bool isBooked;
  final Color color;
  final VoidCallback onBook;

  const _RunCard({
    required this.run,
    required this.isBooked,
    required this.color,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final fillRatio = run.booked / run.total;
    final capacityColor = fillRatio >= 1.0
        ? AppColors.error
        : fillRatio >= 0.8
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 28),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBooked
            ? AppColors.success.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBooked
              ? AppColors.success.withOpacity(0.4)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 48,
            child: Text(
              run.time,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Capacity bar + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.isFull
                      ? 'Full'
                      : '${run.available} seat${run.available == 1 ? '' : 's'} left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: capacityColor,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillRatio.clamp(0.0, 1.0),
                    backgroundColor: capacityColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(capacityColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Book / Cancel button
          SizedBox(
            width: 72,
            child: run.isFull && !isBooked
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Full',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: onBook,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isBooked
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: isBooked
                            ? Border.all(
                                color: AppColors.error.withOpacity(0.3))
                            : null,
                      ),
                      child: Text(
                        isBooked ? 'Cancel' : 'Book',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isBooked
                              ? AppColors.error
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
