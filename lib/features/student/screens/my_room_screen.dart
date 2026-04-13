import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cache/app_image_caches.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/async_refresh.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/room_model.dart';
import '../../../models/user_model.dart';

/// Passed as [GoRouterState.extra] when opening [RoomPhotoGalleryScreen].
class RoomPhotoGalleryExtra {
  final List<String> imageUrls;
  final int initialIndex;

  const RoomPhotoGalleryExtra({
    required this.imageUrls,
    required this.initialIndex,
  });
}

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Room'),
      ),
      body: !hasRoom
          ? RefreshIndicator(
              onRefresh: () => ref.reloadCurrentUserFromFirestore(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: _NoRoomAssignedBody(
                        onExplore: () => context.go('/explore'),
                        onHome: () => context.go('/home'),
                      ),
                    ),
                  );
                },
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.refreshProvider(myRoomProvider);
                await ref.refreshProvider(roommatesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  roomAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) =>
                        _RoomDetailsCard(user: user, room: null, hasRoom: hasRoom),
                    data: (room) =>
                        _RoomDetailsCard(user: user, room: room, hasRoom: hasRoom),
                  ),
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
                  const SizedBox(height: 16),
                  roommatesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (roommates) => _RoommatesCard(roommates: roommates),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Explore other rooms'),
                    onPressed: () => context.go('/explore'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            ),
    );
  }
}

// ── No room assigned (full-page, matches Explore empty-state style) ─────────

class _NoRoomAssignedBody extends StatelessWidget {
  const _NoRoomAssignedBody({
    required this.onExplore,
    required this.onHome,
  });

  final VoidCallback onExplore;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.bed_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'No room yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textOf(context),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Open Explore to browse hostels and book a bed. Your room details, photos, and roommates will show up here once you are assigned.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textMutedOf(context),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onExplore,
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Go to Explore'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to home'),
                ),
              ),
            ],
          ),
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
    context.push(
      '/room/gallery',
      extra: RoomPhotoGalleryExtra(
        imageUrls: imageUrls,
        initialIndex: initial,
      ),
    );
  }
}

/// Full-screen swipe gallery for room photos (opened via go_router).
class RoomPhotoGalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const RoomPhotoGalleryScreen({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<RoomPhotoGalleryScreen> createState() => _RoomPhotoGalleryScreenState();
}

class _RoomPhotoGalleryScreenState extends State<RoomPhotoGalleryScreen> {
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
        itemBuilder: (context, i) => InteractiveViewer(
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
                ? CachedNetworkImageProvider(
                    roommate.profileImageUrl,
                    cacheManager: AppImageCaches.profile,
                  )
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
