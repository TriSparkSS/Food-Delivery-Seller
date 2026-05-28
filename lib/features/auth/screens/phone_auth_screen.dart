import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../widgets/auth_components.dart';

class PhoneAuthScreen extends StatelessWidget {
  const PhoneAuthScreen({
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    required this.onSendOtp,
    required this.onSignup,
    this.loading = false,
    super.key,
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final VoidCallback onSendOtp;
  final VoidCallback onSignup;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      child: AuthEntrance(
        child: _PhoneStepContent(
          controller: controller,
          country: country,
          onCountryChanged: onCountryChanged,
          icon: const Icon(
            Icons.dialpad_rounded,
            color: Colors.white,
            size: 34,
          ),
          title: 'Get Started',
          subtitle: const Text('Enter your phone number to continue'),
          helperText: 'We will send you a 6-digit verification code via SMS',
          buttonLabel: 'Send OTP',
          onSubmit: onSendOtp,
          loading: loading,
          bottomPrompt: AuthAccountPrompt(
            text: "Don't have an account?",
            actionText: 'Sign up',
            onTap: onSignup,
          ),
        ),
      ),
    );
  }
}

class SignupPhoneAuthScreen extends StatelessWidget {
  const SignupPhoneAuthScreen({
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    required this.onSendOtp,
    required this.onBack,
    required this.onSignin,
    this.loading = false,
    super.key,
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final VoidCallback onSendOtp;
  final VoidCallback onBack;
  final VoidCallback onSignin;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      showBack: true,
      onBack: onBack,
      child: AuthEntrance(
        child: _PhoneStepContent(
          controller: controller,
          country: country,
          onCountryChanged: onCountryChanged,
          icon: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 35,
          ),
          title: 'Sign Up',
          subtitle: const Text(
            'Enter your phone number to create your seller account',
          ),
          helperText: 'We will verify your number before creating the account',
          buttonLabel: 'Send OTP',
          onSubmit: onSendOtp,
          loading: loading,
          bottomPrompt: AuthAccountPrompt(
            text: 'Already have an account?',
            actionText: 'Sign in',
            onTap: onSignin,
          ),
        ),
      ),
    );
  }
}

class _PhoneStepContent extends StatelessWidget {
  const _PhoneStepContent({
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.helperText,
    required this.buttonLabel,
    required this.onSubmit,
    required this.loading,
    required this.bottomPrompt,
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final Widget icon;
  final String title;
  final Widget subtitle;
  final String helperText;
  final String buttonLabel;
  final VoidCallback onSubmit;
  final bool loading;
  final Widget bottomPrompt;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final helperStyle = TextStyle(
      color: palette.mutedText,
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeaderBlock(
          stepIndex: 0,
          icon: icon,
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 44),
        const FieldLabel('PHONE NUMBER'),
        const SizedBox(height: 13),
        PhoneNumberField(
          controller: controller,
          country: country,
          onCountryChanged: onCountryChanged,
        ),
        const SizedBox(height: 22),
        Text(helperText, textAlign: TextAlign.center, style: helperStyle),
        const SizedBox(height: 30),
        PrimaryAuthButton(
          label: buttonLabel,
          loading: loading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 32),
        bottomPrompt,
      ],
    );
  }
}
