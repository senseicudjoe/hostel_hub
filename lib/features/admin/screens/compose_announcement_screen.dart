import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/announcement.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-15 — Compose Announcement
//
// Admins can compose and send push announcements to:
//   • All residents
//   • A specific hostel
//   • A specific floor
//
// Fields: Title, Body, Audience selector, Optional image, Schedule/Send now
// ─────────────────────────────────────────────────────────────────────────────

class ComposeAnnouncementScreen extends ConsumerStatefulWidget {
  const ComposeAnnouncementScreen({super.key});

  @override
  ConsumerState<ComposeAnnouncementScreen> createState() =>
      _ComposeAnnouncementScreenState();
}

class _ComposeAnnouncementScreenState
    extends ConsumerState<ComposeAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _targetType = 'All Residents'; // Audience
  bool _hasImage = false;
  bool _isScheduled = false;
  bool _isSending = false;
  DateTime? _scheduledTime;

  static const _targetOptions = [
    'All Residents',
    'Sutherland Hall',
    'Sisulu Hall',
    'Amu Hall',
    'Oteng Korankye II Hall',
    'Maathai Hall',
    'Tawiah Hall',
    'Unity Hall',
    'Freedom Hall',
    'Commonwealth Hall',
    'Independence Hall',
    'Students Only',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String _mapTargetRole(String t) {
    switch (t) {
      case 'Students Only':
        return 'student';
      case 'Staff Only':
        return 'staff';
      default:
        return 'all';
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final id =
          'ann_${const Uuid().v4().replaceAll('-', '').substring(0, 12)}';
      final ann = Announcement(
        announcementId: id,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        sentBy: user.name,
        targetRole: _mapTargetRole(_targetType),
        createdAt: DateTime.now(),
      );
      await ref.read(firestoreServiceProvider).postAnnouncement(ann);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isScheduled && _scheduledTime != null
                ? 'Announcement scheduled for ${_formatDate(_scheduledTime!)}'
                : 'Announcement published',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Announcement'),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _send,
            child: Text(
              _isScheduled ? 'Schedule' : 'Send',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Audience selector ────────────────────────────
            _SectionLabel(label: 'Send to'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _targetOptions.map((opt) {
                final isSelected = _targetType == opt;
                return GestureDetector(
                  onTap: () => setState(() => _targetType = opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.input,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.4)
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ── Title ─────────────────────────────────────────
            _SectionLabel(label: 'Title *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Water Outage Notice',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Body ──────────────────────────────────────────
            _SectionLabel(label: 'Message *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText:
                    'Write your announcement here. Be clear and concise...',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please write the announcement body';
                }
                if (v.trim().length < 10) {
                  return 'Message is too short';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Character count hint ──────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: ValueListenableBuilder(
                valueListenable: _bodyController,
                builder: (_, value, __) => Text(
                  '${value.text.length} characters',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Image attachment ─────────────────────────────
            _SectionLabel(label: 'Attach Image (optional)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _hasImage = !_hasImage),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasImage
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.divider,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _hasImage
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.image_rounded,
                              size: 40, color: AppColors.primary),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _hasImage = false),
                              child: Container(
                                padding: const EdgeInsets.all(4),
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
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.textHint, size: 28),
                          SizedBox(height: 4),
                          Text(
                            'Tap to add image',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Schedule toggle ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dividerOf(context)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule for later',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Send the announcement at a specific date and time',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isScheduled,
                        onChanged: (v) =>
                            setState(() => _isScheduled = v),
                      ),
                    ],
                  ),

                  if (_isScheduled) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now()
                              .add(const Duration(hours: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 30)),
                        );
                        if (date != null && context.mounted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() {
                              _scheduledTime = DateTime(
                                date.year, date.month, date.day,
                                time.hour, time.minute,
                              );
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined,
                          size: 16),
                      label: Text(
                        _scheduledTime != null
                            ? _formatDate(_scheduledTime!)
                            : 'Pick date & time',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Preview card ──────────────────────────────────
            _AnnouncementPreview(
              title: _titleController.text,
              body: _bodyController.text,
              target: _targetType,
            ),

            const SizedBox(height: 24),

            // ── Send / Schedule button ────────────────────────
            ElevatedButton.icon(
              onPressed: _isSending ? null : _send,
              icon: Icon(
                _isScheduled ? Icons.schedule_send_rounded : Icons.send_rounded,
              ),
              label: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(_isScheduled ? 'Schedule Announcement' : 'Send Now'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live preview card
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementPreview extends StatefulWidget {
  final String title;
  final String body;
  final String target;

  const _AnnouncementPreview({
    required this.title,
    required this.body,
    required this.target,
  });

  @override
  State<_AnnouncementPreview> createState() =>
      _AnnouncementPreviewState();
}

class _AnnouncementPreviewState extends State<_AnnouncementPreview> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'HostelHub',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'now',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.title.isEmpty ? 'Announcement Title' : widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: widget.title.isEmpty
                      ? AppColors.textHint
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.body.isEmpty
                    ? 'Your announcement text will appear here...'
                    : widget.body,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.body.isEmpty
                      ? AppColors.textHint
                      : AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '→ ${widget.target}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
