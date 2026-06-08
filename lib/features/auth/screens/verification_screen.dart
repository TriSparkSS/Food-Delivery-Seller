import 'package:didit_sdk/sdk_flutter.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';
import '../widgets/auth_components.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    required this.authApi,
    required this.onProfileLoaded,
    this.tokenStorage = const SellerAuthTokenStorage(),
    this.initialStatus,
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final ValueChanged<SellerProfile> onProfileLoaded;
  final String? initialStatus;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus ?? 'Verify your identity to continue';
  }

  Future<void> _verifyIdentity() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _status = 'Creating secure verification session';
    });

    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();

      if (token == null || token.trim().isEmpty) {
        throw const SellerAuthException('Authentication failed. Login again.');
      }

      if (await _routeIfVerificationAlreadySubmitted(
        token: token,
        tokenType: tokenType,
      )) {
        return;
      }

      final session = await widget.authApi.createVerificationSession(
        token: token,
        tokenType: tokenType,
      );

      final verificationToken = session.sessionToken.isNotEmpty
          ? session.sessionToken
          : session.sdkToken;

      setState(() => _status = 'Opening verification');
      final result = verificationToken.isNotEmpty
          ? await DiditSdk.startVerification(
              verificationToken,
              config: DiditConfig(loggingEnabled: true),
            )
          : await _startVerificationWithWorkflow(session);

      switch (result) {
        case VerificationCompleted():
          await _fetchVerifiedProfile();
          break;
        case VerificationCancelled():
          _setStatus('Verification cancelled');
          _showMessage('Verification cancelled');
          break;
        case VerificationFailed(:final error):
          _setStatus(error.message);
          _showMessage(error.message);
          break;
      }
    } on SellerAuthException catch (error) {
      _setStatus(error.message);
      _showMessage(error.message);
    } catch (error) {
      final message = 'Unable to start verification: $error';
      _setStatus(message);
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<VerificationResult> _startVerificationWithWorkflow(
    SellerVerificationSessionResponse session,
  ) async {
    final workflowId = session.workflowId.trim();
    if (workflowId.isEmpty) {
      throw const SellerAuthException(
        'Didit workflow id missing. Please try again.',
      );
    }

    return DiditSdk.startVerificationWithWorkflow(
      workflowId,
      vendorData: session.sessionId.isEmpty ? null : session.sessionId,
      config: DiditConfig(loggingEnabled: true),
    );
  }

  Future<bool> _routeIfVerificationAlreadySubmitted({
    required String token,
    required String tokenType,
  }) async {
    final SellerVerificationStatusResponse latestStatus;
    try {
      latestStatus = await widget.authApi.fetchVerificationStatus(
        token: token,
        tokenType: tokenType,
      );
      await widget.tokenStorage.saveVerificationStatus(latestStatus.status);
    } on SellerAuthException {
      return false;
    }

    if (latestStatus.normalizedStatus.isEmpty) return false;
    if (!latestStatus.isApproved && !latestStatus.isInReview) return false;

    _setStatus(latestStatus.displayMessage);
    await _fetchVerifiedProfile();
    return true;
  }

  Future<void> _fetchVerifiedProfile() async {
    SellerProfile? loadedProfile;

    setState(() {
      _isLoading = true;
      _status = 'Fetching verified profile';
    });

    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();

      if (token == null || token.trim().isEmpty) {
        throw const SellerAuthException('Authentication failed. Login again.');
      }

      final profile = await widget.authApi.fetchProfile(
        token: token,
        tokenType: tokenType,
      );

      if (profile.isVerificationFailed) {
        final diditStatus = 'Didit status: ${profile.verificationStatusLabel}';
        _setStatus(diditStatus);
        _showMessage(diditStatus);
        return;
      }

      loadedProfile = profile;
    } on SellerAuthException catch (error) {
      _setStatus(error.message);
      _showMessage(error.message);
    } catch (error) {
      final message = 'Unable to fetch profile: $error';
      _setStatus(message);
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted || loadedProfile == null) return;
    widget.onProfileLoaded(loadedProfile);
  }

  void _setStatus(String status) {
    if (!mounted) return;
    setState(() => _status = status);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Scaffold(
      backgroundColor: palette.screen,
      body: LightAuthTextureBackground(
        opacity: 0.08,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            child: AuthEntrance(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            palette.green,
                            palette.greenDark,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: palette.greenDark.withValues(alpha: 0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Identity Verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick and secure — takes about 2 minutes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.mutedText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.fieldFill.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.fieldBorder),
                    ),
                    child: Column(
                      children: [
                        _VerificationStepRow(
                          icon: Icons.badge_outlined,
                          text: 'Government ID photo',
                          palette: palette,
                        ),
                        const SizedBox(height: 10),
                        _VerificationStepRow(
                          icon: Icons.face_retouching_natural_outlined,
                          text: 'Selfie liveness check',
                          palette: palette,
                        ),
                        const SizedBox(height: 10),
                        _VerificationStepRow(
                          icon: Icons.lock_outline_rounded,
                          text: 'Encrypted & secure',
                          palette: palette,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.softGreen.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (_isLoading)
                          SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.greenDark,
                            ),
                          )
                        else
                          Icon(
                            Icons.info_outline_rounded,
                            color: palette.greenDark,
                            size: 18,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _status,
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PrimaryAuthButton(
                    label: 'Start Verification',
                    loading: _isLoading,
                    enabled: !_isLoading,
                    onPressed: _isLoading ? null : _verifyIdentity,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationStepRow extends StatelessWidget {
  const _VerificationStepRow({
    required this.icon,
    required this.text,
    required this.palette,
  });

  final IconData icon;
  final String text;
  final AuthPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.softGreen.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: palette.greenDark, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: palette.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
