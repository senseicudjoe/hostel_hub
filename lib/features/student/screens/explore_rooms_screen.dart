import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/room_model.dart';

class ExploreRoomsScreen extends ConsumerStatefulWidget {
  const ExploreRoomsScreen({super.key});

  @override
  ConsumerState<ExploreRoomsScreen> createState() => _ExploreRoomsScreenState();
}

class _ExploreRoomsScreenState extends ConsumerState<ExploreRoomsScreen> {
  String _hostelFilter = 'All';
  /// When true, list only rooms that can be booked (`RoomModel.isAvailable`).
  bool _bookableOnly = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Rooms'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(roomsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Could not load rooms.\n$e'),
          ),
        ),
        data: (rooms) {
          final hostelNames = rooms.map((r) => r.hostelName).toSet().toList()
            ..sort();
          final hostelOptions = <String>['All', ...hostelNames];
          final effectiveHostel = _hostelFilter == 'All' ||
                  hostelNames.contains(_hostelFilter)
              ? _hostelFilter
              : 'All';

          final filtered = rooms.where((r) {
            if (_bookableOnly && !r.isAvailable) return false;
            if (effectiveHostel != 'All' &&
                r.hostelName != effectiveHostel) {
              return false;
            }
            return true;
          }).toList()
            ..sort((a, b) {
              final h = a.hostelName.compareTo(b.hostelName);
              if (h != 0) return h;
              return a.roomNumber.compareTo(b.roomNumber);
            });

          return Column(
            children: [
              _FiltersBar(
                hostelFilter: effectiveHostel,
                hostelOptions: hostelOptions,
                bookableOnly: _bookableOnly,
                onHostelChanged: (v) => setState(() => _hostelFilter = v),
                onBookableOnlyChanged: (v) =>
                    setState(() => _bookableOnly = v),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyRooms()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final room = filtered[index];
                          return _RoomCard(
                            room: room,
                            canBook: user?.role == AppConstants.roleStudent,
                            onBook: user == null
                                ? null
                                : () => _confirmAndBook(context, room),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmAndBook(BuildContext context, RoomModel room) async {
    if (!room.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This room cannot be booked right now.')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final hasRoom =
        user.roomNumber.trim().isNotEmpty && user.hostel.trim().isNotEmpty;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasRoom ? 'Change room?' : 'Book this room?'),
        content: Text(
          hasRoom
              ? 'You currently have ${user.roomNumber} (${user.hostel}).\n\nSwitch to ${room.roomNumber} (${room.hostelName})?'
              : 'Book ${room.roomNumber} (${room.hostelName}) now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(hasRoom ? 'Switch' : 'Book'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(content: Text('Booking room...')),
    );

    try {
      final fs = ref.read(firestoreServiceProvider);

      if (hasRoom) {
        final alloc = await fs.getStudentAllocation(user.uid);
        final allocationId = alloc?['allocationId'] as String?;
        final oldRoomId = alloc?['roomId'] as String?;
        if (allocationId != null && oldRoomId != null) {
          await fs.deallocateRoom(allocationId, user.uid, oldRoomId);
        }
      }

      await fs.allocateRoom(
        studentUid: user.uid,
        roomId: room.roomId,
        hostelName: room.hostelName,
        roomNumber: room.roomNumber,
        capacity: room.capacity,
        currentOccupants: room.currentOccupants,
      );

      ref.read(currentUserProvider.notifier).state = user.copyWith(
        hostel: room.hostelName,
        roomNumber: room.roomNumber,
      );

      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Room booked successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(content: Text('Could not book: $e')),
      );
    }
  }
}

class _FiltersBar extends StatelessWidget {
  final String hostelFilter;
  final List<String> hostelOptions;
  final bool bookableOnly;
  final ValueChanged<String> onHostelChanged;
  final ValueChanged<bool> onBookableOnlyChanged;

  const _FiltersBar({
    required this.hostelFilter,
    required this.hostelOptions,
    required this.bookableOnly,
    required this.onHostelChanged,
    required this.onBookableOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        border: Border(bottom: BorderSide(color: AppColors.dividerOf(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: hostelFilter,
              decoration: const InputDecoration(
                labelText: 'Hostel',
                isDense: true,
              ),
              items: hostelOptions
                  .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                  .toList(),
              onChanged: (v) => onHostelChanged(v ?? 'All'),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMutedOf(context),
                ),
              ),
              Switch(
                value: bookableOnly,
                onChanged: onBookableOnlyChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final bool canBook;
  final VoidCallback? onBook;

  const _RoomCard({
    required this.room,
    required this.canBook,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final String availability;
    final Color statusColor;
    if (room.status == AppConstants.roomMaintenance) {
      availability = 'Maintenance';
      statusColor = AppColors.warning;
    } else if (room.isAvailable) {
      availability =
          '${room.capacity - room.currentOccupants} spot(s) left';
      statusColor = AppColors.success;
    } else {
      availability = 'Occupied / full';
      statusColor = AppColors.textSecondary;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.meeting_room_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomNumber,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textOf(context),
                        ),
                      ),
                      Text(
                        room.hostelName,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    availability,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPill(
                  icon: Icons.layers_outlined,
                  label: 'Floor ${room.floor}',
                ),
                const SizedBox(width: 8),
                _InfoPill(
                  icon: Icons.people_outline,
                  label: '${room.currentOccupants}/${room.capacity}',
                ),
                const Spacer(),
                if (canBook)
                  ElevatedButton(
                    onPressed: room.isAvailable ? onBook : null,
                    // Override the global Size.fromHeight(52) theme (= Size(∞, 52))
                    // which causes infinite-width layout inside a Row → blank card.
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(88, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(room.isAvailable ? 'Book' : 'Unavailable'),
                  ),
              ],
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputOf(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMutedOf(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No rooms found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing the hostel filter or showing all rooms.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}