import 'package:didit_sdk/sdk_flutter.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    required this.authApi,
    required this.onProfileLoaded,
    this.tokenStorage = const SellerAuthTokenStorage(),
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final ValueChanged<SellerProfile> onProfileLoaded;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  String _status = 'Preparing identity verification';

  /*@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyIdentity();
    });
  }*/

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

      final session = await widget.authApi.createVerificationSession(
        token: token,
        tokenType: tokenType,
      );

      final verificationToken = session.sessionToken.isNotEmpty
          ? session.sessionToken
          : session.sdkToken.isNotEmpty
              ? session.sdkToken
              : session.sessionId;

      if (verificationToken.isEmpty) {
        throw const SellerAuthException('Verification session token missing.');
      }

      setState(() => _status = 'Opening identity verification');
      final result = await DiditSdk.startVerification(
        verificationToken,
        config: DiditConfig(loggingEnabled: true),
      );

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
      const message = 'Unable to fetch profile. Please try again.';
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: palette.green,
                  size: 78,
                ),
                const SizedBox(height: 24),
                Text(
                  'Identity Verification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _verifyIdentity,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Start Verification',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
