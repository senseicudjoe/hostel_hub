import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/async_refresh.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/maintenance_request.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-06 — New Maintenance Request Screen
//
// Students fill in:
//   • Category (dropdown)
//   • Title
//   • Description
//   • Photo attachments (camera or gallery — real image_picker integration)
//   • Auto-filled room info (read-only)
// ─────────────────────────────────────────────────────────────────────────────

const _categories = [
  'Electrical',
  'Plumbing',
  'Furniture',
  'Cleaning',
  'Network / Wi-Fi',
  'Structural',
  'General',
];

const _maxPhotos = 3;

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _uuid = const Uuid();

  String? _selectedCategory;
  final List<File> _pickedFiles = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    if (_pickedFiles.length >= _maxPhotos) return;
    try {
      final file = await ref
          .read(storageServiceProvider)
          .pickImage(fromCamera: true);
      if (file != null && mounted) {
        setState(() => _pickedFiles.add(file));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    if (_pickedFiles.length >= _maxPhotos) return;
    try {
      final remaining = _maxPhotos - _pickedFiles.length;
      final files = await ref
          .read(storageServiceProvider)
          .pickMultipleImages(maxCount: remaining);
      if (files.isNotEmpty && mounted) {
        setState(() => _pickedFiles.addAll(files));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open gallery: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() => _pickedFiles.removeAt(index));
  }

  // ── Submit ────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to submit.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Check connectivity before attempting any network calls.
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline =
          connectivity.any((r) => r != ConnectivityResult.none);

      final fs = ref.read(firestoreServiceProvider);
      final requestId =
          'req_${_uuid.v4().replaceAll('-', '').substring(0, 12)}';
      final now = DateTime.now();

      if (isOnline) {
        // ── Online path — normal submit with image upload ──────────────
        final alloc = await fs.getStudentAllocation(user.uid);
        final roomId =
            alloc?['roomId'] as String? ?? 'unassigned_${user.uid}';

        List<String> imageUrls = [];
        if (_pickedFiles.isNotEmpty) {
          imageUrls = await ref
              .read(storageServiceProvider)
              .uploadMaintenanceImages(user.uid, requestId, _pickedFiles);
        }

        final request = MaintenanceRequest(
          requestId: requestId,
          studentUid: user.uid,
          roomId: roomId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _selectedCategory ?? 'General',
          roomNumber: user.roomNumber,
          hostelName: user.hostel,
          imageUrls: imageUrls,
          status: AppConstants.statusPending,
          createdAt: now,
          updatedAt: now,
        );

        await fs.submitMaintenanceRequest(request);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted! You\'ll be notified of updates.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // ── Offline path — save to Hive queue, sync later ──────────────
        // Images are skipped when offline; they can be added after sync.
        final pendingMap = {
          'requestId': requestId,
          'studentUid': user.uid,
          'roomId': 'unassigned_${user.uid}',
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'category': _selectedCategory ?? 'General',
          'roomNumber': user.roomNumber,
          'hostelName': user.hostel,
          'imageUrls': <String>[],
          'status': AppConstants.statusPending,
          'assignedTo': '',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        await ref.read(offlineServiceProvider).savePendingRequest(pendingMap);

        // Keep the badge count in sync.
        ref.read(pendingRequestCountProvider.notifier).state =
            ref.read(offlineServiceProvider).pendingCount;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You\'re offline — request saved and will sync automatically when you reconnect.',
            ),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 4),
          ),
        );
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Request')),
      body: RefreshIndicator(
        onRefresh: () => ref.reloadCurrentUserFromFirestore(),
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
            // ── Auto-filled Room Info (only when student has a room) ──────
            if (user != null &&
                user.hostel.isNotEmpty &&
                user.roomNumber.isNotEmpty) ...[
              _RoomInfoBanner(
                hostel: user.hostel,
                room: user.roomNumber,
              ),
              const SizedBox(height: 20),
            ],

            // ── Category ──────────────────────────────────────
            const _SectionLabel(label: 'Category *'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('Select a category'),
              decoration: const InputDecoration(),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) =>
                  v == null ? 'Please select a category' : null,
            ),

            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────
            const _SectionLabel(label: 'Issue Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Broken ceiling fan',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (v.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────
            const _SectionLabel(label: 'Description *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Describe the issue in detail — what happened, when it started, how it affects you...',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please describe the issue';
                }
                if (v.trim().length < 20) {
                  return 'Please provide more detail (min 20 characters)';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Photo Attachments ─────────────────────────────
            _SectionLabel(
              label: 'Photos (optional · max $_maxPhotos)',
            ),
            const SizedBox(height: 8),
            _PhotoPicker(
              pickedFiles: _pickedFiles,
              maxPhotos: _maxPhotos,
              onPickCamera: _pickFromCamera,
              onPickGallery: _pickFromGallery,
              onRemove: _removePhoto,
            ),

            const SizedBox(height: 24),

            // ── Priority hint ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Priority is automatically suggested based on category. You\'ll be notified when a staff member is assigned.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Submit Button ─────────────────────────────────
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Submit Request'),
            ),

            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _RoomInfoBanner extends StatelessWidget {
  final String hostel;
  final String room;
  const _RoomInfoBanner({required this.hostel, required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.meeting_room_rounded,
              color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$room — $hostel',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo Picker ──────────────────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  final List<File> pickedFiles;
  final int maxPhotos;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final ValueChanged<int> onRemove;

  const _PhotoPicker({
    required this.pickedFiles,
    required this.maxPhotos,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final canAdd = pickedFiles.length < maxPhotos;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Camera button — hidden once limit is reached
        if (canAdd)
          _PickerButton(
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            onTap: onPickCamera,
          ),

        // Gallery button — hidden once limit is reached
        if (canAdd)
          _PickerButton(
            icon: Icons.photo_library_rounded,
            label: 'Gallery',
            onTap: onPickGallery,
          ),

        // Real image thumbnails
        ...List.generate(
          pickedFiles.length,
          (i) => _Thumbnail(
            file: pickedFiles[i],
            onRemove: () => onRemove(i),
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _Thumbnail({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.input,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}