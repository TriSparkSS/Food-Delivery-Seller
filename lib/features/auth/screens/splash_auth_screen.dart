import 'package:flutter/material.dart';

import '../widgets/auth_components.dart';

class SplashAuthScreen extends StatelessWidget {
  const SplashAuthScreen({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onContinue,
          child: SplashBackground(
            child: SafeArea(
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
                  child: AuthEntrance(
                    child: Column(
                      children: [
                        const Spacer(flex: 6),
                        const SplashLogoTile(),
                        const SizedBox(height: 32),
                        const Text(
                          'QadamFoodHub Seller',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Manage your restaurant on the go',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 16,
                            height: 1.2,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(flex: 5),
                        const SplashLoadingIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
