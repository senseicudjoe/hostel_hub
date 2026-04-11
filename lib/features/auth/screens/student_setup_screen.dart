import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/room_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StudentSetupScreen
//
// A 3-step post-registration onboarding flow shown once per account.
// After the user verifies their email the router redirects here because
// user.setupComplete == false.  On completion setupComplete is written to
// Firestore, currentUserProvider is updated, and the router unblocks /home.
//
// Step 1 — About You    (student ID, phone, year, programme)
// Step 2 — Your Room    (hostel + room picker, or skip)
// Step 3 — All Set!     (summary + "Go to Dashboard" CTA)
// ─────────────────────────────────────────────────────────────────────────────

class StudentSetupScreen extends ConsumerStatefulWidget {
  const StudentSetupScreen({super.key});

  @override
  ConsumerState<StudentSetupScreen> createState() => _StudentSetupScreenState();
}

class _StudentSetupScreenState extends ConsumerState<StudentSetupScreen> {
  final _pageController = PageController();
  int _step = 0; // 0, 1, 2

  // ── Step-1 form ────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  int _yearOfStudy = 1;
  String _programme = '';

  // ── Step-2 room selection ──────────────────────────────────────────────────
  String _selectedHostel = '';
  RoomModel? _selectedRoom;
  List<RoomModel> _allRooms = [];
  bool _loadingRooms = false;
  String? _roomError;

  // ── Submission ─────────────────────────────────────────────────────────────
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _studentIdCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomError = null;
    });
    try {
      final rooms = await ref
          .read(firestoreServiceProvider)
          .getAvailableRooms()
          .first;
      if (mounted) setState(() => _allRooms = rooms);
    } catch (e) {
      if (mounted) setState(() => _roomError = 'Could not load rooms.');
    } finally {
      if (mounted) setState(() => _loadingRooms = false);
    }
  }

  List<RoomModel> get _filteredRooms => _selectedHostel.isEmpty
      ? _allRooms
      : _allRooms.where((r) => r.hostelName == _selectedHostel).toList();

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  bool _validateStep1() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Build the payload — room fields only if the user picked a room.
      final Map<String, dynamic> update = {
        'setupComplete': true,
        'studentId': _studentIdCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'yearOfStudy': _yearOfStudy,
        'programme': _programme,
        'emergencyName': _emergencyNameCtrl.text.trim(),
        'emergencyPhone': _emergencyPhoneCtrl.text.trim(),
      };

      if (_selectedRoom != null) {
        final room = _selectedRoom!;

        // Batch: allocation doc + room occupancy + user hostel/room fields.
        await firestoreService.allocateRoom(
          studentUid: user.uid,
          roomId: room.roomId,
          hostelName: room.hostelName,
          roomNumber: room.roomNumber,
          capacity: room.capacity,
          currentOccupants: room.currentOccupants,
        );

        // allocateRoom already writes hostel/roomNumber to the user doc,
        // but we include them in the update map so the local refresh is accurate.
        update['hostel'] = room.hostelName;
        update['roomNumber'] = room.roomNumber;
      }

      await firestoreService.updateUser(user.uid, update);

      if (!mounted) return;

      // Refresh the local user state so the router gate lifts.
      final refreshed = await firestoreService.getUser(user.uid);
      if (!mounted) return;
      if (refreshed != null) {
        ref.read(currentUserProvider.notifier).state = refreshed;
      }

      // Router redirect will now push /home automatically.
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceOf(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header + progress bar ───────────────────────────────────────
            _Header(step: _step),

            // ── Pages ───────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1PersonalInfo(
                    formKey: _formKey,
                    studentIdCtrl: _studentIdCtrl,
                    phoneCtrl: _phoneCtrl,
                    emergencyNameCtrl: _emergencyNameCtrl,
                    emergencyPhoneCtrl: _emergencyPhoneCtrl,
                    yearOfStudy: _yearOfStudy,
                    programme: _programme,
                    onYearChanged: (v) => setState(() => _yearOfStudy = v),
                    onProgrammeChanged: (v) => setState(() => _programme = v),
                    onNext: () {
                      if (_validateStep1()) _goToStep(1);
                    },
                  ),
                  _Step2RoomSelection(
                    selectedHostel: _selectedHostel,
                    selectedRoom: _selectedRoom,
                    filteredRooms: _filteredRooms,
                    loadingRooms: _loadingRooms,
                    roomError: _roomError,
                    onHostelChanged: (h) => setState(() {
                      _selectedHostel = h;
                      _selectedRoom = null;
                    }),
                    onRoomSelected: (r) => setState(() => _selectedRoom = r),
                    onRetry: _loadRooms,
                    onBack: () => _goToStep(0),
                    onNext: () => _goToStep(2),
                  ),
                  _Step3Summary(
                    studentId: _studentIdCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                    yearOfStudy: _yearOfStudy,
                    programme: _programme,
                    emergencyName: _emergencyNameCtrl.text.trim(),
                    selectedRoom: _selectedRoom,
                    saving: _saving,
                    onBack: () => _goToStep(1),
                    onSubmit: _submit,
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

// ─────────────────────────────────────────────────────────────────────────────
// Header — step labels + animated progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.step});

  final int step;

  static const _labels = ['About You', 'Your Room', 'All Set!'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step label row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${step + 1} of 3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _labels[step],
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOf(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Hostel Hub logo mark
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segmented progress bar
          Row(
            children: List.generate(3, (i) {
              final active = i <= step;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.dividerOf(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Personal Info
// ─────────────────────────────────────────────────────────────────────────────

class _Step1PersonalInfo extends StatelessWidget {
  const _Step1PersonalInfo({
    required this.formKey,
    required this.studentIdCtrl,
    required this.phoneCtrl,
    required this.emergencyNameCtrl,
    required this.emergencyPhoneCtrl,
    required this.yearOfStudy,
    required this.programme,
    required this.onYearChanged,
    required this.onProgrammeChanged,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController studentIdCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emergencyNameCtrl;
  final TextEditingController emergencyPhoneCtrl;
  final int yearOfStudy;
  final String programme;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<String> onProgrammeChanged;
  final VoidCallback onNext;

  static const _years = [
    (value: 1, label: 'Year 1'),
    (value: 2, label: 'Year 2'),
    (value: 3, label: 'Year 3'),
    (value: 4, label: 'Year 4'),
  ];

  static const _programmes = [
    'Computer Science',
    'Business Administration',
    'Engineering',
    'Management Information Systems',
    'Electrical & Electronic Engineering',
    'Mechanical Engineering',
    'Economics',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us a bit about yourself so we can personalise your experience.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMutedOf(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            _SectionLabel('Academic Details'),
            const SizedBox(height: 12),

            // Student ID
            TextFormField(
              controller: studentIdCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Student ID / Index Number',
                hintText: 'e.g. AS/0123/24',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Year of study chips
            const Text(
              'Year of Study',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _years.map((y) {
                final selected = yearOfStudy == y.value;
                return ChoiceChip(
                  label: Text(y.label),
                  selected: selected,
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textOf(context),
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (_) => onYearChanged(y.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Programme dropdown
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: programme.isEmpty ? null : programme,
              decoration: const InputDecoration(
                labelText: 'Programme / Major',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              hint: const Text('Select your programme'),
              items: _programmes
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => onProgrammeChanged(v ?? ''),
            ),
            const SizedBox(height: 28),

            _SectionLabel('Contact Information'),
            const SizedBox(height: 12),

            // Phone
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]'))],
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g. +233 20 123 4567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 28),

            _SectionLabel('Emergency Contact'),
            const SizedBox(height: 4),
            Text(
              'Someone we can reach if there is an urgent issue with your accommodation.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedOf(context),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: emergencyNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                hintText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emergencyPhoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]'))],
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
                hintText: 'e.g. +233 24 987 6543',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: onNext,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continue'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Room Selection
// ─────────────────────────────────────────────────────────────────────────────

class _Step2RoomSelection extends StatelessWidget {
  const _Step2RoomSelection({
    required this.selectedHostel,
    required this.selectedRoom,
    required this.filteredRooms,
    required this.loadingRooms,
    required this.roomError,
    required this.onHostelChanged,
    required this.onRoomSelected,
    required this.onRetry,
    required this.onBack,
    required this.onNext,
  });

  final String selectedHostel;
  final RoomModel? selectedRoom;
  final List<RoomModel> filteredRooms;
  final bool loadingRooms;
  final String? roomError;
  final ValueChanged<String> onHostelChanged;
  final ValueChanged<RoomModel> onRoomSelected;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick your hostel and room. You can also skip and book later from the Explore tab.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMutedOf(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Hostel filter chips
              const Text(
                'Select Hostel',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _HostelChip(
                      label: 'All',
                      selected: selectedHostel.isEmpty,
                      onTap: () => onHostelChanged(''),
                    ),
                    ...AppConstants.hostels.map((h) => _HostelChip(
                          label: h,
                          selected: selectedHostel == h,
                          onTap: () => onHostelChanged(h),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Room list
        Expanded(
          child: loadingRooms
              ? const Center(child: CircularProgressIndicator())
              : roomError != null
                  ? _ErrorRetry(message: roomError!, onRetry: onRetry)
                  : filteredRooms.isEmpty
                      ? _EmptyRooms(hostel: selectedHostel)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: filteredRooms.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final room = filteredRooms[i];
                            final isSelected = selectedRoom?.roomId == room.roomId;
                            return _RoomCard(
                              room: room,
                              selected: isSelected,
                              onTap: () => onRoomSelected(room),
                            );
                          },
                        ),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              if (selectedRoom != null)
                ElevatedButton(
                  onPressed: onNext,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Book & Continue'),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              if (selectedRoom != null) const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onNext,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.dividerOf(context)),
                  foregroundColor: AppColors.textMutedOf(context),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Skip for now'),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onBack,
                child: const Text('← Back'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HostelChip extends StatelessWidget {
  const _HostelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.dividerOf(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textOf(context),
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.selected,
    required this.onTap,
  });
  final RoomModel room;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spotsLeft = room.capacity - room.currentOccupants;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight
              : AppColors.cardOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.dividerOf(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Room icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.meeting_room_rounded,
                color: selected
                    ? AppColors.primary
                    : AppColors.textMutedOf(context),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room ${room.roomNumber}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOf(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${room.hostelName} · Floor ${room.floor}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 13,
                        color: AppColors.textMutedOf(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} left of ${room.capacity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Selected indicator
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: AppColors.textMutedOf(context)),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(color: AppColors.textMutedOf(context))),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.hostel});
  final String hostel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hotel_outlined,
                size: 48, color: AppColors.textMutedOf(context)),
            const SizedBox(height: 12),
            Text(
              hostel.isEmpty
                  ? 'No rooms available at the moment.'
                  : 'No rooms available in $hostel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Summary & Confirm
// ─────────────────────────────────────────────────────────────────────────────

class _Step3Summary extends StatelessWidget {
  const _Step3Summary({
    required this.studentId,
    required this.phone,
    required this.yearOfStudy,
    required this.programme,
    required this.emergencyName,
    required this.selectedRoom,
    required this.saving,
    required this.onBack,
    required this.onSubmit,
  });

  final String studentId;
  final String phone;
  final int yearOfStudy;
  final String programme;
  final String emergencyName;
  final RoomModel? selectedRoom;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Celebration banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 10),
                const Text(
                  'You\'re all set!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Here\'s a summary of your profile. Tap "Complete Setup" to go to your dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Profile summary card
          _SummaryCard(
            title: 'Academic Details',
            icon: Icons.school_outlined,
            rows: [
              ('Student ID', studentId),
              ('Year of Study', 'Year $yearOfStudy'),
              if (programme.isNotEmpty) ('Programme', programme),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Contact',
            icon: Icons.phone_outlined,
            rows: [
              ('Phone', phone),
              if (emergencyName.isNotEmpty)
                ('Emergency Contact', emergencyName),
            ],
          ),
          const SizedBox(height: 12),

          // Room summary (or skip notice)
          if (selectedRoom != null)
            _SummaryCard(
              title: 'Room Booking',
              icon: Icons.meeting_room_rounded,
              rows: [
                ('Hostel', selectedRoom!.hostelName),
                ('Room', selectedRoom!.roomNumber),
                ('Floor', 'Floor ${selectedRoom!.floor}'),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dividerOf(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: AppColors.textMutedOf(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No room booked yet. You can explore and book from the dashboard.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: saving ? null : onSubmit,
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Complete Setup'),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: saving ? null : onBack,
            child: const Text('← Back'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.$1,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.$2,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppColors.primary,
      ),
    );
  }
}
