import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/room_model.dart';
import '../../../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-04 — My Room Screen
// ─────────────────────────────────────────────────────────────────────────────

class MyRoomScreen extends ConsumerWidget {
  const MyRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roomAsync = ref.watch(myRoomProvider);
    final roommatesAsync = ref.watch(roommatesProvider);
    final hasRoom =
        (user?.roomNumber.trim().isNotEmpty ?? false) &&
        (user?.hostel.trim().isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('My Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasRoom) ...[
              _NoRoomCard(onExplore: () => context.go('/explore')),
              const SizedBox(height: 16),
            ],

            // ── Room details ─────────────────────────────────────
            roomAsync.when(
              loading: () => hasRoom
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink(),
              error: (_, __) =>
                  _RoomDetailsCard(user: user, room: null, hasRoom: hasRoom),
              data: (room) =>
                  _RoomDetailsCard(user: user, room: room, hasRoom: hasRoom),
            ),

            // ── Room photos ──────────────────────────────────────
            if (hasRoom)
              roomAsync.maybeWhen(
                data: (room) {
                  if (room == null || room.imageUrls.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _RoomPhotosCard(imageUrls: room.imageUrls),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

            // ── Roommates ────────────────────────────────────────
            if (hasRoom) ...[
              const SizedBox(height: 16),
              roommatesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (roommates) => _RoommatesCard(roommates: roommates),
              ),
            ],

            const SizedBox(height: 16),

            OutlinedButton.icon(
              icon: const Icon(Icons.search_rounded),
              label: Text(hasRoom ? 'Explore other rooms' : 'Explore rooms'),
              onPressed: () => context.go('/explore'),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── No Room Card ──────────────────────────────────────────────────────────────

class _NoRoomCard extends StatelessWidget {
  final VoidCallback onExplore;
  const _NoRoomCard({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No room assigned yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore available rooms and book one.',
                    style: TextStyle(color: AppColors.textMutedOf(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onExplore,
              child: const Text('Explore'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Room Details Card ─────────────────────────────────────────────────────────

class _RoomDetailsCard extends StatelessWidget {
  final dynamic user;
  final RoomModel? room;
  final bool hasRoom;

  const _RoomDetailsCard({this.user, required this.room, required this.hasRoom});

  String _floorLabel() {
    if (room == null) return '—';
    final f = room!.floor;
    if (f <= 0) return '—';
    return 'Floor $f';
  }

  String _statusLabel() {
    if (room == null) return hasRoom ? 'Assigned' : 'Unassigned';
    switch (room!.status) {
      case AppConstants.roomAvailable:
        return 'Available';
      case AppConstants.roomOccupied:
        return 'Occupied';
      case AppConstants.roomMaintenance:
        return 'Maintenance';
      default:
        return room!.status;
    }
  }

  Color _statusColor() {
    if (room == null) {
      return hasRoom ? AppColors.success : AppColors.warning;
    }
    switch (room!.status) {
      case AppConstants.roomMaintenance:
        return AppColors.warning;
      case AppConstants.roomOccupied:
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomNumber = room?.roomNumber ??
        (hasRoom ? user?.roomNumber?.toString() ?? '' : 'Not Assigned');
    final hostel =
        room?.hostelName ?? (hasRoom ? user?.hostel?.toString() ?? '' : '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        roomNumber,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textOf(context),
                        ),
                      ),
                      Text(
                        hostel.isNotEmpty
                            ? hostel
                            : 'Book a room to see details',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _detailRow(context, Icons.layers_outlined, 'Floor',
                hasRoom ? _floorLabel() : '—'),
            const SizedBox(height: 10),
            _detailRow(
              context,
              Icons.people_outline,
              'Occupancy',
              room != null
                  ? '${room!.currentOccupants} / ${room!.capacity} students'
                  : (hasRoom ? '—' : '—'),
            ),
            const SizedBox(height: 10),
            _detailRow(
              context,
              Icons.meeting_room_outlined,
              'Room type',
              room != null && room!.capacity > 1
                  ? 'Shared (${room!.capacity} beds)'
                  : 'Single',
            ),
            const SizedBox(height: 10),
            _detailRow(
              context,
              Icons.check_circle_outline,
              'Room status',
              _statusLabel(),
              valueColor: _statusColor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMutedOf(context)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppColors.textMutedOf(context)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textOf(context),
          ),
        ),
      ],
    );
  }
}

// ── Room Photos Card ──────────────────────────────────────────────────────────

class _RoomPhotosCard extends StatelessWidget {
  final List<String> imageUrls;
  const _RoomPhotosCard({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () => _showFullScreen(context, i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[i],
                        width: 220,
                        height: 180,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 220,
                          color: AppColors.dividerOf(context),
                          child: const Center(
                              child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 220,
                          color: AppColors.dividerOf(context),
                          child: const Icon(Icons.broken_image_outlined,
                              size: 40, color: AppColors.textHint),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context, int initial) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenGallery(
          imageUrls: imageUrls,
          initialIndex: initial,
        ),
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const _FullScreenGallery(
      {required this.imageUrls, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.imageUrls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrls[i],
              fit: BoxFit.contain,
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Roommates Card ────────────────────────────────────────────────────────────

class _RoommatesCard extends StatelessWidget {
  final List<UserModel> roommates;
  const _RoommatesCard({required this.roommates});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Occupants',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 12),
            if (roommates.isEmpty)
              Text(
                'You\'re the only one assigned to this room right now.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMutedOf(context),
                ),
              )
            else
              ...roommates.map((r) => _RoommateRow(roommate: r)),
          ],
        ),
      ),
    );
  }
}

class _RoommateRow extends StatelessWidget {
  final UserModel roommate;
  const _RoommateRow({required this.roommate});

  @override
  Widget build(BuildContext context) {
    final initials = roommate.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: roommate.profileImageUrl.isNotEmpty
                ? CachedNetworkImageProvider(roommate.profileImageUrl)
                : null,
            child: roommate.profileImageUrl.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roommate.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOf(context),
                  ),
                ),
                Text(
                  roommate.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
