import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/hostel_assets.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/room_model.dart';

class ExploreRoomsScreen extends ConsumerStatefulWidget {
  const ExploreRoomsScreen({super.key});

  @override
  ConsumerState<ExploreRoomsScreen> createState() => _ExploreRoomsScreenState();
}

class _HostelSummary {
  const _HostelSummary({
    required this.name,
    this.assetCoverPath,
    required this.coverUrl,
    required this.roomCount,
  });

  final String name;
  /// Bundled hero image (preferred over network when set).
  final String? assetCoverPath;
  final String? coverUrl;
  final int roomCount;
}

List<_HostelSummary> _summarizeHostels(List<RoomModel> rooms) {
  final map = <String, List<RoomModel>>{};
  for (final r in rooms) {
    if (r.hostelName.trim().isEmpty) continue;
    map.putIfAbsent(r.hostelName, () => []).add(r);
  }
  final names = map.keys.toList()..sort();
  return names.map((name) {
    final rs = map[name]!;
    String? url;
    for (final r in rs) {
      if (r.imageUrls.isNotEmpty) {
        url = r.imageUrls.first;
        break;
      }
    }
    return _HostelSummary(
      name: name,
      assetCoverPath: HostelAssets.coverAssetPath(name),
      coverUrl: url,
      roomCount: rs.length,
    );
  }).toList();
}

class _ExploreRoomsScreenState extends ConsumerState<ExploreRoomsScreen> {
  /// `null` = show hostel cards only. Non-null = show rooms for this hostel.
  String? _selectedHostel;

  bool _bookableOnly = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _selectedHostel != null
            ? IconButton(
                tooltip: 'All hostels',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  _selectedHostel = null;
                  _bookableOnly = false;
                }),
              )
            : null,
        title: Text(_selectedHostel ?? 'Explore Rooms'),
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
          if (rooms.isEmpty) {
            return const _EmptyHostels();
          }

          if (_selectedHostel == null) {
            final summaries = _summarizeHostels(rooms);
            if (summaries.isEmpty) {
              return const _EmptyHostels();
            }
            return _HostelGrid(
              summaries: summaries,
              onHostelTap: (name) => setState(() => _selectedHostel = name),
            );
          }

          final hostelRooms = rooms
              .where((r) => r.hostelName == _selectedHostel)
              .toList()
            ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

          final filtered = hostelRooms.where((r) {
            if (_bookableOnly && !r.isAvailable) return false;
            return true;
          }).toList();

          return Column(
            children: [
              _BookableFilterBar(
                bookableOnly: _bookableOnly,
                onBookableOnlyChanged: (v) =>
                    setState(() => _bookableOnly = v),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyRooms()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final room = filtered[index];
                          final isCurrentRoom =
                              user != null &&
                              user.hostel.trim() == room.hostelName &&
                              user.roomNumber.trim() == room.roomNumber;
                          return _RoomCard(
                            room: room,
                            canBook: user?.role == AppConstants.roleStudent,
                            isCurrentRoom: isCurrentRoom,
                            onBook: user == null || isCurrentRoom
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
    messenger.showSnackBar(const SnackBar(content: Text('Booking room...')));

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
      messenger.showSnackBar(SnackBar(content: Text('Could not book: $e')));
    }
  }
}

class _HostelGrid extends StatelessWidget {
  const _HostelGrid({
    required this.summaries,
    required this.onHostelTap,
  });

  final List<_HostelSummary> summaries;
  final ValueChanged<String> onHostelTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: summaries.length,
      itemBuilder: (context, i) {
        final h = summaries[i];
        return _HostelCard(summary: h, onTap: () => onHostelTap(h.name));
      },
    );
  }
}

class _HostelCard extends StatelessWidget {
  const _HostelCard({required this.summary, required this.onTap});

  final _HostelSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardOf(context),
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (summary.assetCoverPath != null &&
                      summary.assetCoverPath!.trim().isNotEmpty)
                    Image.asset(
                      summary.assetCoverPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _HostelPlaceholder(label: summary.name),
                    )
                  else if (summary.coverUrl != null &&
                      summary.coverUrl!.trim().isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: summary.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.inputOf(context),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _HostelPlaceholder(
                        label: summary.name,
                      ),
                    )
                  else
                    _HostelPlaceholder(label: summary.name),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            summary.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${summary.roomCount} room${summary.roomCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostelPlaceholder extends StatelessWidget {
  const _HostelPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apartment_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label.split(' ').first,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookableFilterBar extends StatelessWidget {
  const _BookableFilterBar({
    required this.bookableOnly,
    required this.onBookableOnlyChanged,
  });

  final bool bookableOnly;
  final ValueChanged<bool> onBookableOnlyChanged;

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
            child: Text(
              'Rooms in this hostel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ),
          Text(
            'Bookable only',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMutedOf(context),
            ),
          ),
          Switch(value: bookableOnly, onChanged: onBookableOnlyChanged),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final bool canBook;
  final bool isCurrentRoom;
  final VoidCallback? onBook;

  const _RoomCard({
    required this.room,
    required this.canBook,
    required this.isCurrentRoom,
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
      availability = '${room.capacity - room.currentOccupants} spot(s) left';
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
                  child: const Icon(
                    Icons.meeting_room_rounded,
                    color: AppColors.primary,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
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
                    onPressed: room.isAvailable && !isCurrentRoom
                        ? onBook
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(88, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      isCurrentRoom
                          ? 'Current Room'
                          : room.isAvailable
                          ? 'Book'
                          : 'Unavailable',
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
              'No rooms match',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try turning off “Bookable only” or pick another hostel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHostels extends StatelessWidget {
  const _EmptyHostels();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment_outlined,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 14),
            Text(
              'No hostels to explore yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Rooms will appear here once they are added in Firestore.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}
