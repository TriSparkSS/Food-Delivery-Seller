import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';
import 'store_details_screen.dart';

class ProfileReviewScreen extends StatelessWidget {
  const ProfileReviewScreen({
    required this.authApi,
    required this.tokenStorage,
    this.profile,
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final SellerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final fullName = profile?.ownerFullName ?? 'Seller';
    final initials = profile?.initials ?? 'S';
    final phoneNumber = profile?.phoneNumber ?? 'Not available';
    final email = profile?.email ?? 'Not available';
    final idNumber = profile?.id == null ? 'Not available' : 'SELLER ${profile!.id}';
    final address = profile?.restaurant?.restaurantAddress ?? 'Not available';

    return Scaffold(
      backgroundColor: palette.screen,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.mutedText,
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: palette.softGreen.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: palette.green.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '✅',
                      style: TextStyle(
                        fontSize: 38,
                        color: palette.green,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Documents Verified!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.greenDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We've extracted your information below",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  width: 118,
                  height: 118,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.greenDark,
                    border: Border.all(color: palette.green, width: 3),
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  '📸 Extracted from ID',
                  style: TextStyle(
                    color: palette.greenDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _ProfileField(
                label: 'FULL NAME',
                value: fullName,
                autoFilled: true,
              ),
              const _ProfileField(
                label: 'DATE OF BIRTH',
                value: 'Not available',
                autoFilled: true,
              ),
              _ProfileField(
                label: 'ID NUMBER',
                value: idNumber,
                autoFilled: true,
              ),
              _ProfileField(
                label: 'ADDRESS (FROM ID)',
                value: address,
                autoFilled: true,
              ),
              _ProfileField(
                label: 'PHONE NUMBER',
                value: phoneNumber,
                verified: true,
              ),
              _ProfileField(
                label: 'EMAIL',
                value: email,
                verified: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Review your details above. You can edit any field if the auto-extracted data is incorrect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.mutedText,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 60,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => StoreDetailsScreen(
                          authApi: authApi,
                          tokenStorage: tokenStorage,
                          profile: profile,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Confirm & Continue →',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    this.autoFilled = false,
    this.verified = false,
  });

  final String label;
  final String value;
  final bool autoFilled;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              if (autoFilled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.softGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'AUTO-FILLED',
                    style: TextStyle(
                      color: palette.greenDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: palette.softGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: palette.green.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 19,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (verified)
                  Icon(Icons.check_rounded, color: palette.greenDark, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
