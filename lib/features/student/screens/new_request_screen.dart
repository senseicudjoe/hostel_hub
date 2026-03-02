import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-06 — New Maintenance Request Screen
//
// Students fill in:
//   • Category (dropdown)
//   • Title
//   • Description
//   • Photo attachments (simulated — would use image_picker in real app)
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

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategory;
  bool _hasPhoto = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    // Simulate network call.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request submitted! You\'ll be notified of updates.'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Auto-filled Room Info ─────────────────────────
            _RoomInfoBanner(
              hostel: user?.hostel ?? 'Unity Hall',
              room: user?.roomNumber ?? 'U-204',
            ),

            const SizedBox(height: 20),

            // ── Category ──────────────────────────────────────
            _SectionLabel(label: 'Category *'),
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
            _SectionLabel(label: 'Issue Title *'),
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
            _SectionLabel(label: 'Description *'),
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
            _SectionLabel(label: 'Photos (optional)'),
            const SizedBox(height: 8),
            _PhotoPicker(
              hasPhoto: _hasPhoto,
              onPickCamera: () {
                setState(() => _hasPhoto = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera would open here')),
                );
              },
              onPickGallery: () {
                setState(() => _hasPhoto = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gallery would open here')),
                );
              },
              onRemove: () => setState(() => _hasPhoto = false),
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
        border:
            Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.meeting_room_rounded,
              color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Text(
            'Room auto-filled: $room — $hostel',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final bool hasPhoto;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  const _PhotoPicker({
    required this.hasPhoto,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Camera button
        _PickerButton(
          icon: Icons.camera_alt_rounded,
          label: 'Camera',
          onTap: onPickCamera,
        ),
        const SizedBox(width: 10),

        // Gallery button
        _PickerButton(
          icon: Icons.photo_library_rounded,
          label: 'Gallery',
          onTap: onPickGallery,
        ),

        if (hasPhoto) ...[
          const SizedBox(width: 10),
          // Photo preview thumbnail (simulated)
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Icon(Icons.image_rounded,
                    color: AppColors.primary, size: 32),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
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
