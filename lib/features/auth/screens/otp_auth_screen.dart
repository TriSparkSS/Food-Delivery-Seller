import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../widgets/auth_components.dart';

class OtpAuthScreen extends StatefulWidget {
  const OtpAuthScreen({
    required this.phoneNumber,
    required this.otp,
    required this.controllers,
    required this.focusNodes,
    required this.otpComplete,
    required this.onOtpChanged,
    required this.onBack,
    required this.onChangeNumber,
    required this.onVerify,
    this.loading = false,
    super.key,
  });

  final String phoneNumber;
  final String? otp;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool otpComplete;
  final ValueChanged<String> onOtpChanged;
  final VoidCallback onBack;
  final VoidCallback onChangeNumber;
  final VoidCallback onVerify;
  final bool loading;

  @override
  State<OtpAuthScreen> createState() => _OtpAuthScreenState();
}

class _OtpAuthScreenState extends State<OtpAuthScreen> {
  static const _initialSeconds = 120;

  Timer? _timer;
  int _remainingSeconds = _initialSeconds;

  String get _timerLabel {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _startTimer(notify: false);
  }

  @override
  void didUpdateWidget(covariant OtpAuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneNumber != widget.phoneNumber) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer({bool notify = true}) {
    _timer?.cancel();
    if (notify && mounted) {
      setState(() => _remainingSeconds = _initialSeconds);
    } else {
      _remainingSeconds = _initialSeconds;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        return;
      }

      setState(() => _remainingSeconds--);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final muted = TextStyle(
      color: palette.mutedText,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );

    return AuthPageScaffold(
      showBack: true,
      onBack: widget.onBack,
      child: AuthEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeaderBlock(
              stepIndex: 1,
              showStepIndicator: false,
              icon: const Icon(
                Icons.lock_open_rounded,
                color: Colors.amber,
                size: 38,
              ),
              title: 'Verify OTP',
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Code sent to '),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.otp != null) ...[
                      const TextSpan(text: '\nOTP: '),
                      TextSpan(
                        text: widget.otp,
                        style: TextStyle(
                          color: palette.greenDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            OtpCodeFields(
              controllers: widget.controllers,
              focusNodes: widget.focusNodes,
              onChanged: widget.onOtpChanged,
            ),
            const SizedBox(height: 26),
            LinkedSentence(
              parts: [
                TextSpan(text: "Didn't receive code? ", style: muted),
                if (_remainingSeconds > 0)
                  TextSpan(
                    text: 'Resend in $_timerLabel',
                    style: muted.copyWith(
                      color: palette.greenDark,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: _startTimer,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        child: Text(
                          'Resend code',
                          style: muted.copyWith(
                            color: palette.greenDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 34),
            PrimaryAuthButton(
              label: 'Verify',
              enabled: widget.otpComplete,
              loading: widget.loading,
              onPressed: widget.onVerify,
            ),
            const SizedBox(height: 30),
            LinkedSentence(
              parts: [
                TextSpan(text: 'Wrong number? ', style: muted),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: widget.onChangeNumber,
                    child: Text(
                      'Change',
                      style: muted.copyWith(
                        color: palette.greenDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
