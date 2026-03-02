import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-04 — My Room Screen
//
// Displays:
//   • Room details (hostel, number, floor, bed)
//   • Roommate info card
//   • QR code placeholder (scan to identify room)
//   • Navigate to hostel button
// ─────────────────────────────────────────────────────────────────────────────

class MyRoomScreen extends ConsumerWidget {
  const MyRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

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
            // ── Room Details Card ─────────────────────────────
            _RoomDetailsCard(user: user),

            const SizedBox(height: 16),

            // ── Roommate Card ─────────────────────────────────
            const _RoommateCard(),

            const SizedBox(height: 16),

            // ── QR Code Card ──────────────────────────────────
            _QRCodeCard(roomNumber: user?.roomNumber ?? 'U-204'),

            const SizedBox(height: 16),

            // ── Navigate Button ───────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Navigate to Hostel'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening maps navigation to Unity Hall...'),
                  ),
                );
              },
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
  const _RoomDetailsCard({this.user});

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(
                    Icons.meeting_room_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.roomNumber ?? 'U-204',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user?.hostel ?? 'Unity Hall',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _detailRow(Icons.layers_outlined, 'Floor', '2nd Floor'),
            const SizedBox(height: 10),
            _detailRow(Icons.single_bed_rounded, 'Bed', 'Bed A'),
            const SizedBox(height: 10),
            _detailRow(Icons.people_outline, 'Capacity', '2 students'),
            const SizedBox(height: 10),
            _detailRow(
              Icons.check_circle_outline,
              'Status',
              'Occupied',
              valueColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

// ── Roommate Card ─────────────────────────────────────────────────────────────

class _RoommateCard extends StatelessWidget {
  const _RoommateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Roommate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.info.withOpacity(0.15),
                  child: const Text(
                    'AO',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ama Owusu',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'ama.owusu@ashesi.edu.gh',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Bed B · Year 2',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── QR Code Card ──────────────────────────────────────────────────────────────

class _QRCodeCard extends StatelessWidget {
  final String roomNumber;
  const _QRCodeCard({required this.roomNumber});

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Scan this to identify your room or share with maintenance staff',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // QR code placeholder — in a real app, use qr_flutter package:
            // QrImageView(data: roomNumber, version: QrVersions.auto, size: 140)
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
                  const Icon(
                    Icons.qr_code_2_rounded,
                    size: 72,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roomNumber,
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
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
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
