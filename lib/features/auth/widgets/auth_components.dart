import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    required this.child,
    this.showBack = false,
    this.onBack,
    super.key,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Scaffold(
      backgroundColor: palette.screen,
      body: LightAuthTextureBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).top -
                    MediaQuery.paddingOf(context).bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 42,
                      child: showBack
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: BackTextButton(onPressed: onBack),
                            )
                          : null,
                    ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LightAuthTextureBackground extends StatelessWidget {
  const LightAuthTextureBackground({required this.child, super.key});

  static const String assetPath = 'assets/images/onboard_background.png';

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AuthPalette>()!;

    if (theme.brightness == Brightness.dark) {
      return ColoredBox(color: palette.screen, child: child);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.screen,
        image: const DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}

class BackTextButton extends StatelessWidget {
  const BackTextButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Material(
      color: palette.green,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox.square(
          dimension: 38,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class AuthStepIndicator extends StatelessWidget {
  const AuthStepIndicator({
    required this.activeIndex,
    this.total = 6,
    super.key,
  });

  final int activeIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == activeIndex;
        final isComplete = index < activeIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: isActive ? 28 : 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive || isComplete ? palette.green : palette.inactiveDot,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class AuthEntrance extends StatelessWidget {
  const AuthEntrance({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final adjusted =
            (delay == Duration.zero ? value : value.clamp(0.0, 1.0)).toDouble();

        return Opacity(
          opacity: adjusted,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - adjusted)),
            child: Transform.scale(
              scale: 0.98 + (0.02 * adjusted),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class AuthIconTile extends StatelessWidget {
  const AuthIconTile({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      width: 104,
      height: 104,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.green, palette.greenDark],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: child,
    );
  }
}

class AuthHeaderBlock extends StatelessWidget {
  const AuthHeaderBlock({
    required this.stepIndex,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showStepIndicator = true,
    super.key,
  });

  final int stepIndex;
  final Widget icon;
  final String title;
  final Widget subtitle;
  final bool showStepIndicator;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Column(
      children: [
        if (showStepIndicator) ...[
          AuthStepIndicator(activeIndex: stepIndex),
          const SizedBox(height: 28),
        ],
        AuthIconTile(child: icon),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.text,
            fontSize: 26,
            height: 1.05,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        DefaultTextStyle(
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.mutedText,
            fontSize: 15,
            height: 1.25,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          child: subtitle,
        ),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Text(
      text,
      style: TextStyle(
        color: palette.mutedText,
        fontSize: 13,
        height: 1,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
      ),
    );
  }
}

class PhoneCountry {
  const PhoneCountry({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.maxLength,
    required this.groups,
    required this.example,
  });

  static const india = PhoneCountry(
    name: 'India',
    flag: '\u{1F1EE}\u{1F1F3}',
    dialCode: '+91',
    maxLength: 10,
    groups: [5, 5],
    example: '9830393093',
  );

  final String name;
  final String flag;
  final String dialCode;
  final int maxLength;
  final List<int> groups;
  final String example;

  String formatNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > maxLength
        ? digits.substring(0, maxLength)
        : digits;

    var cursor = 0;
    final chunks = <String>[];
    for (final group in groups) {
      if (cursor >= limited.length) break;
      final end = math.min(cursor + group, limited.length);
      chunks.add(limited.substring(cursor, end));
      cursor = end;
    }
    if (cursor < limited.length) {
      chunks.add(limited.substring(cursor));
    }

    return chunks.join(' ');
  }
}

const authPhoneCountries = [
  PhoneCountry.india,
  PhoneCountry(
    name: 'Tajikistan',
    flag: '\u{1F1F9}\u{1F1EF}',
    dialCode: '+992',
    maxLength: 9,
    groups: [2, 3, 4],
    example: '92 123 4567',
  ),
  PhoneCountry(
    name: 'Russia',
    flag: '\u{1F1F7}\u{1F1FA}',
    dialCode: '+7',
    maxLength: 10,
    groups: [3, 3, 2, 2],
    example: '912 345 67 89',
  ),
];

class AuthInputShell extends StatelessWidget {
  const AuthInputShell({
    required this.child,
    this.highlighted = false,
    this.error = false,
    this.height = 58,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    super.key,
  });

  final Widget child;
  final bool highlighted;
  final bool error;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: error
              ? palette.error
              : highlighted
              ? palette.green
              : palette.fieldBorder,
          width: highlighted || error ? 1.8 : 1.1,
        ),
        boxShadow: [
          if (highlighted || error)
            BoxShadow(
              color: (error ? palette.error : palette.green).withValues(
                alpha: 0.12,
              ),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: child,
    );
  }
}

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.readOnly = false,
    this.compact = false,
    super.key,
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final bool readOnly;
  final bool compact;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  final _focusNode = FocusNode();

  bool get _hasDigits =>
      widget.controller.text.replaceAll(RegExp(r'\D'), '').isNotEmpty;

  bool get _highlighted =>
      !widget.readOnly && (_focusNode.hasFocus || _hasDigits);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_refresh);
    widget.controller.addListener(_refresh);
    _normalizePhoneText();
  }

  @override
  void didUpdateWidget(covariant PhoneNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
    if (oldWidget.country != widget.country ||
        oldWidget.controller != widget.controller) {
      _normalizePhoneText();
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _normalizePhoneText() {
    final formatted = widget.country.formatNumber(widget.controller.text);
    if (formatted == widget.controller.text) return;

    widget.controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _openCountryPicker() async {
    if (widget.readOnly) return;

    _focusNode.unfocus();
    final country = await showModalBottomSheet<PhoneCountry>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) {
        return CountryCodePickerSheet(selectedCountry: widget.country);
      },
    );

    if (country != null) {
      widget.onCountryChanged(country);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return AuthInputShell(
      highlighted: _highlighted,
      height: widget.compact ? 46 : 58,
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 13 : 18),
      child: Row(
        children: [
          InkWell(
            onTap: widget.readOnly ? null : _openCountryPicker,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.country.flag,
                    style: TextStyle(fontSize: widget.compact ? 19 : 23),
                  ),
                  SizedBox(width: widget.compact ? 7 : 9),
                  Text(
                    widget.country.dialCode,
                    style: TextStyle(
                      color: _highlighted
                          ? palette.greenDark
                          : palette.mutedText,
                      fontSize: widget.compact ? 14 : 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _highlighted ? palette.greenDark : palette.mutedText,
                    size: widget.compact ? 16 : 19,
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: widget.compact ? 20 : 24,
            margin: EdgeInsets.only(
              left: widget.compact ? 8 : 10,
              right: widget.compact ? 11 : 14,
            ),
            color: palette.fieldBorder,
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.phone,
              readOnly: widget.readOnly,
              canRequestFocus: !widget.readOnly,
              enableInteractiveSelection: !widget.readOnly,
              inputFormatters: [PhoneNumberInputFormatter(widget.country)],
              style: TextStyle(
                color: palette.text,
                fontSize: widget.compact ? 15 : 19,
                fontWeight: FontWeight.w400,
                letterSpacing: widget.compact ? 0.8 : 1.4,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: widget.country.example,
                hintStyle: TextStyle(
                  color: Color(0xE8E8E8CD),
                ),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class PhoneNumberInputFormatter extends TextInputFormatter {
  PhoneNumberInputFormatter(this.country);

  final PhoneCountry country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = country.formatNumber(newValue.text);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CountryCodePickerSheet extends StatelessWidget {
  const CountryCodePickerSheet({required this.selectedCountry, super.key});

  final PhoneCountry selectedCountry;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: palette.screen,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: palette.fieldBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select country code',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.mutedText,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                itemCount: authPhoneCountries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final country = authPhoneCountries[index];
                  final selected =
                      country.name == selectedCountry.name &&
                      country.dialCode == selectedCountry.dialCode;

                  return _CountryCodeTile(
                    country: country,
                    selected: selected,
                    onTap: () => Navigator.pop(context, country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryCodeTile extends StatelessWidget {
  const _CountryCodeTile({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final PhoneCountry country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Material(
      color: selected ? palette.softGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  country.name,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                country.dialCode,
                style: TextStyle(
                  color: selected ? palette.greenDark : palette.mutedText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? palette.green : palette.fieldBorder,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CredentialsField extends StatefulWidget {
  const CredentialsField({
    required this.controller,
    required this.leading,
    this.obscureText = false,
    this.trailing,
    this.keyboardType,
    this.errorText,
    this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final Widget leading;
  final bool obscureText;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final String? errorText;
  final String? hintText;

  @override
  State<CredentialsField> createState() => _CredentialsFieldState();
}

class _CredentialsFieldState extends State<CredentialsField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthInputShell(
          highlighted: _focusNode.hasFocus,
          error: hasError,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              SizedBox(width: 24, child: Center(child: widget.leading)),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: widget.obscureText ? 3 : 0,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: palette.mutedText.withValues(alpha: 0.62),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ],
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: hasError
              ? Padding(
                  key: ValueKey(widget.errorText),
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    widget.errorText!,
                    style: TextStyle(
                      color: palette.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class PrimaryAuthButton extends StatelessWidget {
  const PrimaryAuthButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final active = enabled && onPressed != null && !loading;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: active ? palette.buttonShadow : Colors.transparent,
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: active ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          disabledBackgroundColor: palette.green.withValues(alpha: 0.5),
          backgroundColor: palette.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
      ),
    );
  }
}

class LinkedSentence extends StatelessWidget {
  const LinkedSentence({required this.parts, super.key});

  final List<InlineSpan> parts;

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: parts), textAlign: TextAlign.center);
  }
}

class AuthAccountPrompt extends StatelessWidget {
  const AuthAccountPrompt({
    required this.text,
    required this.actionText,
    required this.onTap,
    super.key,
  });

  final String text;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final baseStyle = TextStyle(
      color: palette.mutedText,
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w400,
    );

    return LinkedSentence(
      parts: [
        TextSpan(text: '$text ', style: baseStyle),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                actionText,
                style: baseStyle.copyWith(
                  color: palette.greenDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OtpCodeFields extends StatelessWidget {
  const OtpCodeFields({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    super.key,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      children: List.generate(controllers.length, (index) {
        final hasValue = controllers[index].text.isNotEmpty;
        final hasFocus = focusNodes[index].hasFocus;
        final active = hasValue || hasFocus;

        return Expanded(
          child: Container(
            height: 54,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 5,
              right: index == controllers.length - 1 ? 0 : 5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? palette.green : palette.fieldBorder,
                width: active ? 1.8 : 1.1,
              ),
            ),
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              keyboardType: TextInputType.number,
              maxLength: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.green,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                onChanged(value);
                if (value.isNotEmpty && index < controllers.length - 1) {
                  focusNodes[index + 1].requestFocus();
                }
                if (value.isEmpty && index > 0) {
                  focusNodes[index - 1].requestFocus();
                }
              },
            ),
          ),
        );
      }),
    );
  }
}

class SplashBackground extends StatelessWidget {
  const SplashBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.splashTop, palette.splashBottom],
          ),
        ),
        child: CustomPaint(
          painter: DotPatternPainter(),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

class SplashLogoTile extends StatelessWidget {
  const SplashLogoTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}

class SplashLoadingIndicator extends StatefulWidget {
  const SplashLoadingIndicator({super.key});

  @override
  State<SplashLoadingIndicator> createState() => _SplashLoadingIndicatorState();
}

class _SplashLoadingIndicatorState extends State<SplashLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 86,
          height: 20,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  final wave = math.sin(
                    (_controller.value * math.pi * 2) + (index * math.pi / 2),
                  );
                  final opacity = 0.45 + ((wave + 1) * 0.25);

                  return Transform.translate(
                    offset: Offset(0, -4 * wave),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Loading your seller workspace',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.09);

    for (double y = 42; y < size.height; y += 84) {
      for (double x = 30; x < size.width; x += 82) {
        final wobble = math.sin((x + y) / 40) * 11;
        canvas.drawCircle(Offset(x + wobble, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
