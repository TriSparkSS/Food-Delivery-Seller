import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../widgets/auth_components.dart';

class CredentialsAuthScreen extends StatefulWidget {
  const CredentialsAuthScreen({
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.hidePassword,
    required this.confirmPassword,
    required this.onTogglePassword,
    required this.onToggleCPassword,
    required this.onBack,
    required this.onContinue,
    this.loading = false,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool hidePassword;
  final bool confirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleCPassword;
  final VoidCallback onBack;
  final bool loading;
  final Future<void> Function({
    required String email,
    required String password,
    required String passwordConfirmation,
  })
  onContinue;

  @override
  State<CredentialsAuthScreen> createState() => _CredentialsAuthScreenState();
}

class _CredentialsAuthScreenState extends State<CredentialsAuthScreen> {
  bool _showValidation = false;

  String? get _emailError {
    final email = widget.emailController.text.trim();
    if (email.isEmpty) return 'Enter your email address';

    final validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!validEmail.hasMatch(email)) return 'Enter a valid email address';

    return null;
  }

  String? get _passwordError {
    final password = widget.passwordController.text;
    if (password.isEmpty) return 'Enter a password';
    if (password.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Use 8+ characters with at least one letter and one number';
    }

    return null;
  }

  String? get _confirmPasswordError {
    final confirmPassword = widget.confirmPasswordController.text;
    if (confirmPassword.isEmpty) return 'Confirm your password';
    if (confirmPassword != widget.passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  bool get _isValid =>
      _emailError == null &&
      _passwordError == null &&
      _confirmPasswordError == null;

  @override
  void initState() {
    super.initState();
    _addControllerListeners();
  }

  @override
  void didUpdateWidget(covariant CredentialsAuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emailController != widget.emailController ||
        oldWidget.passwordController != widget.passwordController ||
        oldWidget.confirmPasswordController !=
            widget.confirmPasswordController) {
      _removeControllerListeners(oldWidget);
      _addControllerListeners();
    }
  }

  @override
  void dispose() {
    _removeControllerListeners(widget);
    super.dispose();
  }

  void _addControllerListeners() {
    widget.emailController.addListener(_refreshValidation);
    widget.passwordController.addListener(_refreshValidation);
    widget.confirmPasswordController.addListener(_refreshValidation);
  }

  void _removeControllerListeners(CredentialsAuthScreen source) {
    source.emailController.removeListener(_refreshValidation);
    source.passwordController.removeListener(_refreshValidation);
    source.confirmPasswordController.removeListener(_refreshValidation);
  }

  void _refreshValidation() {
    if (_showValidation && mounted) setState(() {});
  }

  String? _visibleError(String? error) => _showValidation ? error : null;

  void _handleContinue() {
    setState(() => _showValidation = true);
    if (_isValid) {
      widget.onContinue(
        email: widget.emailController.text.trim(),
        password: widget.passwordController.text,
        passwordConfirmation: widget.confirmPasswordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return AuthPageScaffold(
      showBack: true,
      onBack: widget.onBack,
      child: AuthEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeaderBlock(
              stepIndex: 2,
              showStepIndicator: false,
              icon: const Icon(
                Icons.mail_outline_rounded,
                color: Colors.white,
                size: 38,
              ),
              title: 'Set Credentials',
              subtitle: const Text('Add your email and create a password'),
            ),
            const SizedBox(height: 40),
            const FieldLabel('EMAIL ADDRESS'),
            const SizedBox(height: 13),
            CredentialsField(
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              leading: const Icon(Icons.mail_outline_rounded, size: 22),
              errorText: _visibleError(_emailError),
            ),
            const SizedBox(height: 24),
            const FieldLabel('CREATE PASSWORD'),
            const SizedBox(height: 13),
            CredentialsField(
              controller: widget.passwordController,
              obscureText: widget.hidePassword,
              leading: Icon(Icons.lock, color: palette.text, size: 22),
              errorText: _visibleError(_passwordError),
              trailing: IconButton(
                onPressed: widget.onTogglePassword,
                icon: Icon(
                  widget.hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: palette.mutedText,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const FieldLabel('CONFIRM PASSWORD'),
            const SizedBox(height: 13),
            CredentialsField(
              controller: widget.confirmPasswordController,
              obscureText: widget.confirmPassword,
              leading: Icon(Icons.lock, color: palette.text, size: 22),
              errorText: _visibleError(_confirmPasswordError),
              trailing: IconButton(
                onPressed: widget.onToggleCPassword,
                icon: Icon(
                  widget.confirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: palette.mutedText,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryAuthButton(
              label: 'Continue',
              loading: widget.loading,
              onPressed: _handleContinue,
            ),
          ],
        ),
      ),
    );
  }
}
