import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// S-01 — Onboarding Screen
//
// A 3-slide PageView carousel shown once when the user first opens the app.
// Each slide explains a key feature. Ends with a "Get Started" CTA.
// ─────────────────────────────────────────────────────────────────────────────

// Data model for a single onboarding slide.
class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

const _slides = [
  _Slide(
    icon: Icons.build_circle_rounded,
    title: 'Maintenance Made Easy',
    subtitle:
        'Report broken fixtures, track status in real time, and get notified when your issue is resolved.',
    color: Color(0xFFA53A3E),
  ),
  _Slide(
    icon: Icons.directions_bus_rounded,
    title: 'Book Your Shuttle',
    subtitle:
        'View live schedules, check available seats, and secure your spot on the campus shuttle in seconds.',
    color: Color(0xFF1565C0),
  ),
  _Slide(
    icon: Icons.apartment_rounded,
    title: 'Your Room, Your Hub',
    subtitle:
        'View hostel details, scan room QR codes, and stay connected with official announcements.',
    color: Color(0xFF2E7D32),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Last slide — navigate to login.
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ─────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Skip'),
              ),
            ),

            // ── Slides ───────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _SlideView(slide: _slides[index]),
              ),
            ),

            // ── Page indicators ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── CTA button ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _nextPage,
                child: Text(isLast ? 'Get Started' : 'Next'),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// A single onboarding slide — icon, title, and subtitle.
class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 72, color: slide.color),
          ),

          const SizedBox(height: 40),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
