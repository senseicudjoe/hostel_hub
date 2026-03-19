import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-13 — Admin Room Management
//
// Grid view of all rooms, colour-coded by status:
//   🟢 Occupied   🔵 Available   🟡 Maintenance
//
// Filter chips by hostel, and a summary row at the top.
// ─────────────────────────────────────────────────────────────────────────────

// Room statuses
enum _RoomStatus { occupied, available, maintenance }

class _Room {
  final String number;
  final _RoomStatus status;
  final String occupant; // Empty if available
  const _Room(this.number, this.status, [this.occupant = '']);
}

// Mock hostel data — 3 hostels with 16 rooms each.
final _hostels = {
  'Unity Hall': _generateRooms('U', [
    _RoomStatus.occupied, _RoomStatus.occupied, _RoomStatus.occupied,
    _RoomStatus.available, _RoomStatus.occupied, _RoomStatus.occupied,
    _RoomStatus.maintenance, _RoomStatus.occupied, _RoomStatus.occupied,
    _RoomStatus.occupied, _RoomStatus.available, _RoomStatus.occupied,
    _RoomStatus.occupied, _RoomStatus.occupied, _RoomStatus.available,
    _RoomStatus.occupied,
  ]),
  'Freedom Hall': _generateRooms('F', [
    _RoomStatus.occupied, _RoomStatus.available, _RoomStatus.occupied,
    _RoomStatus.occupied, _RoomStatus.available, _RoomStatus.occupied,
    _RoomStatus.occupied, _RoomStatus.occupied, _RoomStatus.maintenance,
    _RoomStatus.occupied, _RoomStatus.occupied, _RoomStatus.occupied,
    _RoomStatus.available, _RoomStatus.occupied, _RoomStatus.occupied,
    _RoomStatus.occupied,
  ]),
  'Independence Hall': _generateRooms('I', [
    _RoomStatus.occupied, _RoomStatus.occupied, _RoomStatus.available,
    _RoomStatus.occupied, _RoomStatus.occupied, _RoomStatus.occupied,
    _RoomStatus.occupied, _RoomStatus.available, _RoomStatus.occupied,
    _RoomStatus.maintenance, _RoomStatus.occupied, _RoomStatus.occupied,
    _RoomStatus.occupied, _RoomStatus.available, _RoomStatus.occupied,
    _RoomStatus.occupied,
  ]),
};

List<_Room> _generateRooms(String prefix, List<_RoomStatus> statuses) {
  return statuses.asMap().entries.map((e) {
    final floor = e.key ~/ 4 + 1;
    final num = (e.key % 4 + 1).toString().padLeft(2, '0');
    return _Room('$prefix-$floor$num', e.value,
        e.value == _RoomStatus.occupied ? 'Resident' : '');
  }).toList();
}

class AdminRoomManagementScreen extends StatefulWidget {
  const AdminRoomManagementScreen({super.key});

  @override
  State<AdminRoomManagementScreen> createState() =>
      _AdminRoomManagementScreenState();
}

class _AdminRoomManagementScreenState
    extends State<AdminRoomManagementScreen> {
  String _selectedHostel = 'Unity Hall';

  List<_Room> get _rooms => _hostels[_selectedHostel] ?? [];

  int _count(_RoomStatus s) => _rooms.where((r) => r.status == s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Hostel filter chips ───────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _hostels.keys
                  .map((h) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(h.split(' ').first),
                          selected: _selectedHostel == h,
                          onSelected: (_) =>
                              setState(() => _selectedHostel = h),
                          selectedColor: AppColors.primaryLight,
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedHostel == h
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const Divider(height: 1),

          // ── Stats row ────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _StatBadge(
                    count: _count(_RoomStatus.occupied),
                    label: 'Occupied',
                    color: AppColors.success),
                const SizedBox(width: 12),
                _StatBadge(
                    count: _count(_RoomStatus.available),
                    label: 'Available',
                    color: AppColors.info),
                const SizedBox(width: 12),
                _StatBadge(
                    count: _count(_RoomStatus.maintenance),
                    label: 'Maintenance',
                    color: AppColors.warning),
                const Spacer(),
                Text(
                  '${_rooms.length} rooms',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Room Grid ────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: _rooms.length,
              itemBuilder: (context, index) {
                return _RoomCell(
                  room: _rooms[index],
                  onTap: () => _showRoomDetail(context, _rooms[index]),
                );
              },
            ),
          ),

          // ── Legend ───────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                _LegendDot(color: AppColors.success, label: 'Occupied'),
                SizedBox(width: 16),
                _LegendDot(color: AppColors.info, label: 'Available'),
                SizedBox(width: 16),
                _LegendDot(color: AppColors.warning, label: 'Maintenance'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomDetail(BuildContext context, _Room room) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Room ${room.number}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _statusChip(room.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _selectedHostel,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (room.status == _RoomStatus.occupied)
              const Text('Resident assigned. Tap Reassign to change.'),
            if (room.status == _RoomStatus.available)
              const Text('This room is available for allocation.'),
            if (room.status == _RoomStatus.maintenance)
              const Text(
                  'This room is undergoing maintenance and unavailable.'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Opening assignment for ${room.number}')),
                      );
                    },
                    child: Text(
                      room.status == _RoomStatus.occupied
                          ? 'Reassign'
                          : 'Assign',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(_RoomStatus s) {
    final (label, color) = switch (s) {
      _RoomStatus.occupied => ('Occupied', AppColors.success),
      _RoomStatus.available => ('Available', AppColors.info),
      _RoomStatus.maintenance => ('Maintenance', AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Cell (grid item)
// ─────────────────────────────────────────────────────────────────────────────

class _RoomCell extends StatelessWidget {
  final _Room room;
  final VoidCallback onTap;
  const _RoomCell({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, icon) = switch (room.status) {
      _RoomStatus.occupied => (
          AppColors.success.withOpacity(0.12),
          AppColors.success,
          Icons.person_rounded,
        ),
      _RoomStatus.available => (
          AppColors.info.withOpacity(0.12),
          AppColors.info,
          Icons.meeting_room_outlined,
        ),
      _RoomStatus.maintenance => (
          AppColors.warning.withOpacity(0.12),
          AppColors.warning,
          Icons.build_rounded,
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 4),
            Text(
              room.number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatBadge(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count $label',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
