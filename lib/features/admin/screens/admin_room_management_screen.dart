import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/room_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-13 — Admin room management (Firestore rooms collection)
// ─────────────────────────────────────────────────────────────────────────────

class AdminRoomManagementScreen extends ConsumerStatefulWidget {
  const AdminRoomManagementScreen({super.key});

  @override
  ConsumerState<AdminRoomManagementScreen> createState() =>
      _AdminRoomManagementScreenState();
}

class _AdminRoomManagementScreenState
    extends ConsumerState<AdminRoomManagementScreen> {
  String? _hostelFilter;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
      ),
      body: async.when(
        data: (rooms) {
          final hostels = rooms.map((r) => r.hostelName).toSet().toList()
            ..sort();
          final effective =
              _hostelFilter ?? (hostels.isNotEmpty ? hostels.first : null);
          final filtered = effective == null
              ? rooms
              : rooms.where((r) => r.hostelName == effective).toList();

          int count(String status) =>
              filtered.where((r) => r.status == status).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hostels.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: hostels
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(h.split(' ').first),
                              selected: effective == h,
                              onSelected: (_) =>
                                  setState(() => _hostelFilter = h),
                              selectedColor: AppColors.primaryLight,
                              checkmarkColor: AppColors.primary,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Occupied ${count(AppConstants.roomOccupied)} · '
                  'Available ${count(AppConstants.roomAvailable)} · '
                  'Maintenance ${count(AppConstants.roomMaintenance)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No rooms in Firestore for this filter.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final r = filtered[i];
                          return _RoomTile(room: r);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final RoomModel room;

  const _RoomTile({required this.room});

  Color _statusColor() {
    switch (room.status) {
      case AppConstants.roomOccupied:
        return AppColors.success;
      case AppConstants.roomMaintenance:
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    room.roomNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              room.hostelName,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '${room.currentOccupants}/${room.capacity} occupants',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
