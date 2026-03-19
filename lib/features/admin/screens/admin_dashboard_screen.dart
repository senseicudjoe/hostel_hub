import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-12 — Admin Dashboard
//
// Overview for SLE administrators:
//   • KPI cards (total requests, pending, resolved, occupancy)
//   • Bar chart — requests by category
//   • Line chart — weekly request trend
//   • Recent activity feed
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──────────────────────────────────────
            Text(
              'Good morning, ${user?.name.split(' ').first ?? 'Admin'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Here\'s what\'s happening in your hostels today',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 20),

            // ── KPI Cards ─────────────────────────────────────
            const _SectionTitle('Overview'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: const [
                _KpiCard(
                  title: 'Total Requests',
                  value: '47',
                  change: '+12 this week',
                  up: true,
                  icon: Icons.build_rounded,
                  color: AppColors.info,
                ),
                _KpiCard(
                  title: 'Pending',
                  value: '12',
                  change: '−3 since yesterday',
                  up: false,
                  icon: Icons.schedule_rounded,
                  color: AppColors.warning,
                ),
                _KpiCard(
                  title: 'Resolved',
                  value: '28',
                  change: '+8 this week',
                  up: true,
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                _KpiCard(
                  title: 'Occupancy',
                  value: '94%',
                  change: '+2% vs last sem',
                  up: true,
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Bar Chart — Requests by Category ─────────────
            const _SectionTitle('Requests by Category'),
            const SizedBox(height: 10),
            _CategoryBarChart(),

            const SizedBox(height: 20),

            // ── Line Chart — Weekly Trend ─────────────────────
            const _SectionTitle('Weekly Trend'),
            const SizedBox(height: 10),
            _WeeklyTrendChart(),

            const SizedBox(height: 20),

            // ── Recent Activity ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle('Recent Activity'),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._activityItems.map((item) => _ActivityTile(item: item)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI Card
// ─────────────────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool up;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.change,
    required this.up,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Icon(
                  up ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: up ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 10,
                      color: up ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bar Chart — Requests by Category
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBarChart extends StatelessWidget {
  // (category label, count, color)
  static const _data = [
    ('Electric.', 14, AppColors.warning),
    ('Plumbing', 11, AppColors.info),
    ('Furniture', 8, AppColors.success),
    ('Cleaning', 7, AppColors.primary),
    ('General', 7, AppColors.statusAcknowledged),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 18,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _data[index].$1,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _data.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: d.$2.toDouble(),
                      color: d.$3,
                      width: 32,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Line Chart — Weekly Trend
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyTrendChart extends StatelessWidget {
  static const _spots = [
    FlSpot(0, 4),
    FlSpot(1, 7),
    FlSpot(2, 5),
    FlSpot(3, 9),
    FlSpot(4, 6),
    FlSpot(5, 11),
    FlSpot(6, 8),
  ];

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 14,
              lineBarsData: [
                LineChartBarData(
                  spots: _spots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= _days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _days[i],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Feed
// ─────────────────────────────────────────────────────────────────────────────

class _Activity {
  final String message;
  final String time;
  final String status;
  final IconData icon;
  const _Activity(this.message, this.time, this.status, this.icon);
}

const _activityItems = [
  _Activity('REQ-005 submitted by Kofi Mensah', '5 min ago', 'submitted',
      Icons.add_circle_outline),
  _Activity('REQ-001 status → In Progress', '23 min ago', 'in_progress',
      Icons.sync_rounded),
  _Activity('REQ-003 marked as Resolved', '1 hour ago', 'resolved',
      Icons.check_circle_outline),
  _Activity('New booking: 14:30 Main Gate route', '2 hours ago', 'confirmed',
      Icons.directions_bus_rounded),
];

class _ActivityTile extends StatelessWidget {
  final _Activity item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon,
                size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  item.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(status: item.status),
        ],
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
