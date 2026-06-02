import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../widgets/auth_components.dart';

class OnboardingAuthScreen extends StatefulWidget {
  const OnboardingAuthScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<OnboardingAuthScreen> createState() => _OnboardingAuthScreenState();
}

class _OnboardingAuthScreenState extends State<OnboardingAuthScreen> {
  static const _pages = [
    _OnboardingPageData(
      imagePath: 'assets/images/onboarding_restaurant_setup.png',
      title: 'Set up your restaurant',
      description:
          'Add kitchen details, timings, menu items, prices, and photos so customers know exactly what you serve.',
    ),
    _OnboardingPageData(
      imagePath: 'assets/images/onboarding_orders.png',
      title: 'Manage every order',
      description:
          'Accept new orders, track preparation, and keep delivery status clear from one seller workspace.',
    ),
    _OnboardingPageData(
      imagePath: 'assets/images/onboarding_menu_growth.png',
      title: 'Grow your food business',
      description:
          'Update your menu, highlight best dishes, and review sales insights to make smarter decisions.',
    ),
  ];

  late final PageController _pageController;
  int _activeIndex = 0;

  bool get _isLastPage => _activeIndex == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_isLastPage) {
      widget.onFinished();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Scaffold(
      backgroundColor: const Color(0xFF090B0E),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              child: Image.asset(
                _pages[_activeIndex].imagePath,
                key: ValueKey<String>(_pages[_activeIndex].imagePath),
                fit: BoxFit.cover,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Color(0x11000000),
                    Color(0xEE000000),
                  ],
                  stops: [0, 0.48, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onFinished,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.86),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() => _activeIndex = index);
                        },
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          return _OnboardingPage(data: _pages[index]);
                        },
                      ),
                    ),
                    _OnboardingDots(
                      activeIndex: _activeIndex,
                      total: _pages.length,
                      activeColor: palette.green,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _continue,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isLastPage ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return AuthEntrance(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 16,
              height: 1.42,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 54),
        ],
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({
    required this.activeIndex,
    required this.total,
    required this.activeColor,
  });

  final int activeIndex;
  final int total;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index == activeIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: active ? 28 : 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? activeColor
                : Colors.white.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String description;
}
