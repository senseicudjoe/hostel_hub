import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/room_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-04 — My Room Screen
//
// Shows the student's assigned room from Firestore (allocation → rooms doc)
// when available; otherwise falls back to profile fields (e.g. demo mode).
// ─────────────────────────────────────────────────────────────────────────────

class MyRoomScreen extends ConsumerWidget {
  const MyRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roomAsync = ref.watch(myRoomProvider);
    final hasRoom =
        (user?.roomNumber.trim().isNotEmpty ?? false) &&
        (user?.hostel.trim().isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Room QR',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening QR scanner...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasRoom) ...[
              _NoRoomCard(
                onExplore: () => context.go('/explore'),
              ),
              const SizedBox(height: 16),
            ],

            // ── Room details (from Firestore live room doc when possible) ──
            roomAsync.when(
              loading: () {
                if (!hasRoom) {
                  return const SizedBox.shrink();
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              error: (_, __) => _RoomDetailsCard(
                user: user,
                room: null,
                hasRoom: hasRoom,
              ),
              data: (room) => _RoomDetailsCard(
                user: user,
                room: room,
                hasRoom: hasRoom,
              ),
            ),

            const SizedBox(height: 16),

            // ── Occupancy / sharing (skip extra spinner while main block loads) ──
            if (hasRoom)
              roomAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const _OccupancyPlaceholderCard(),
                data: (room) {
                  if (room == null) return const _OccupancyPlaceholderCard();
                  return _OccupancyCard(room: room);
                },
              ),

            if (hasRoom) const SizedBox(height: 16),

            // ── QR Code ─────────────────────────────────────────────────────────
            if (hasRoom) ...[
              _QRCodeCard(
                roomNumber: user?.roomNumber ?? '',
                qrCode: roomAsync.maybeWhen(
                  data: (r) => r?.qrCode,
                  orElse: () => null,
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton.icon(
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Navigate to Hostel'),
              onPressed: hasRoom
                  ? () {
                      final name = roomAsync.maybeWhen(
                        data: (r) => r?.hostelName,
                        orElse: () => null,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Opening maps to ${name ?? user?.hostel ?? 'hostel'}...',
                          ),
                        ),
                      );
                    }
                  : null,
            ),

            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.search_rounded),
              label: Text(hasRoom ? 'Explore other rooms' : 'Explore rooms'),
              onPressed: () => context.go('/explore'),
            ),
          ],
        ),
      ),
    );
  }
}

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
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No room assigned yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Explore available rooms and book one.',
                    style: TextStyle(color: AppColors.textSecondary),
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

// ── Room Details ─────────────────────────────────────────────────────────────

class _RoomDetailsCard extends StatelessWidget {
  final dynamic user;
  final RoomModel? room;
  final bool hasRoom;

  const _RoomDetailsCard({
    this.user,
    required this.room,
    required this.hasRoom,
  });

  String _floorLabel() {
    if (room == null) return '—';
    final f = room!.floor;
    if (f <= 0) return '—';
    return 'Floor $f';
  }

  String _statusLabel() {
    if (room == null) {
      return hasRoom ? 'Assigned' : 'Unassigned';
    }
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
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        hostel.isNotEmpty
                            ? hostel
                            : 'Book a room to see details',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
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
            _detailRow(
              Icons.layers_outlined,
              'Floor',
              hasRoom ? _floorLabel() : '—',
            ),
            const SizedBox(height: 10),
            _detailRow(
              Icons.people_outline,
              'Occupancy',
              room != null
                  ? '${room!.currentOccupants} / ${room!.capacity} students'
                  : (hasRoom ? '—' : '—'),
            ),
            const SizedBox(height: 10),
            _detailRow(
              Icons.meeting_room_outlined,
              'Room type',
              room != null && room!.capacity > 1
                  ? 'Shared (${room!.capacity} beds)'
                  : 'Single',
            ),
            const SizedBox(height: 10),
            _detailRow(
              Icons.check_circle_outline,
              'Room status',
              _statusLabel(),
              valueColor: _statusColor(),
            ),
            if (hasRoom && room == null) ...[
              const SizedBox(height: 12),
              Text(
                'Full details appear when your booking is synced from the server.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _OccupancyPlaceholderCard extends StatelessWidget {
  const _OccupancyPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.info.withOpacity(0.85)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Room occupancy and sharing details will show here when your booking is loaded from the server.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Occupancy / sharing ─────────────────────────────────────────────────────
class _OccupancyCard extends StatelessWidget {
  final RoomModel room;

  const _OccupancyCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final others = room.currentOccupants - 1;
    final shared = room.capacity > 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your room',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shared
                  ? '${room.capacity}-bed capacity · ${room.currentOccupants} assigned'
                  : 'Single occupancy',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (shared && others > 0) ...[
              const SizedBox(height: 6),
              Text(
                'You share this room with $others other student(s).',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── QR Code Card ──────────────────────────────────────────────────────────────

class _QRCodeCard extends StatelessWidget {
  final String roomNumber;
  final String? qrCode;

  const _QRCodeCard({
    required this.roomNumber,
    this.qrCode,
  });

  @override
  Widget build(BuildContext context) {
    final display = (qrCode != null && qrCode!.trim().isNotEmpty)
        ? qrCode!.trim()
        : roomNumber;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Room QR Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Scan this to identify your room or share with maintenance staff',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2_rounded,
                      size: 72, color: AppColors.textPrimary),
                  const SizedBox(height: 4),
                  Text(
                    display.isNotEmpty ? display : '—',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Share QR Code'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing QR code...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
