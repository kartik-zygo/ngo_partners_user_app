import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';

class _Slide {
  final String icon;
  final String title;
  final String sub;
  final List<Color> gradient;
  const _Slide({
    required this.icon,
    required this.title,
    required this.sub,
    required this.gradient,
  });
}

const _slides = [
  _Slide(
    icon: '📂',
    title: 'Manage Your Cases\nEffortlessly',
    sub: 'Track every filing stage, upload documents, and stay updated in one clean dashboard.',
    gradient: [Color(0xFF1D4ED8), Color(0xFF0891B2)],
  ),
  _Slide(
    icon: '🚀',
    title: 'Launch Services\nWith Confidence',
    sub: 'Get expert-assisted registrations and compliance services with clear timelines and support.',
    gradient: [Color(0xFF10B981), Color(0xFF06B6D4)],
  ),
  _Slide(
    icon: '🛡️',
    title: 'Get Support\nAt Every Step',
    sub: 'Raise support tickets, receive alerts, and resolve document issues faster with guided help.',
    gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ),
];

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int idx) {
    _animCtrl.reset();
    setState(() => _current = idx);
    _animCtrl.forward();
  }

  void _goTo(int idx) {
    if (idx == _current) return;
    _pageCtrl.animateToPage(
      idx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _goTo(_current + 1);
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_current];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Illustration area — PageView handles swipe ───────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) =>
                      _IllustrationPage(slide: _slides[index]),
                ),
                // Skip button overlaid on PageView
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                      child: GestureDetector(
                        onTap: widget.onFinish,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Skip',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content area ─────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Dots indicator (tappable)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      return GestureDetector(
                        onTap: () => _goTo(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _current ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: i == _current
                                ? LinearGradient(colors: _slides[i].gradient)
                                : null,
                            color: i == _current
                                ? null
                                : AppColors.borderSubtle,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  // Title — animated on page change
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          slide.title,
                          style: AppTextStyles.displayMedium.copyWith(
                            height: 1.25,
                            fontSize: 28,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle — animated on page change
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          slide.sub,
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.7,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    child: Row(
                      children: [
                        if (_current > 0) ...[
                          Expanded(
                            flex: 1,
                            child: OutlineGoldButton(
                              label: 'Back',
                              onTap: () => _goTo(_current - 1),
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: GoldButton(
                            label: _current < _slides.length - 1
                                ? 'Next'
                                : 'Get Started',
                            onTap: _next,
                            icon: _current < _slides.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.rocket_launch_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Each page rendered inside the PageView
class _IllustrationPage extends StatelessWidget {
  final _Slide slide;
  const _IllustrationPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                slide.gradient[0].withValues(alpha: 0.12),
                slide.gradient[1].withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Top-right blob
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.gradient[0].withValues(alpha: 0.12),
            ),
          ),
        ),
        // Top-left blob
        Positioned(
          top: 40,
          left: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.gradient[1].withValues(alpha: 0.10),
            ),
          ),
        ),
        // Central emoji icon with gradient circle
        Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: slide.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.gradient[0].withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Center(
              child: Text(slide.icon, style: const TextStyle(fontSize: 64)),
            ),
          ),
        ),
      ],
    );
  }
}


