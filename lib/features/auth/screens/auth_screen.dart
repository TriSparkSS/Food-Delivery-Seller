import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';
import '../data/device_identity.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';
import '../widgets/auth_components.dart';
import 'credentials_auth_screen.dart';
import 'onboarding_auth_screen.dart';
import 'otp_auth_screen.dart';
import 'phone_auth_screen.dart';
import 'profile_review_screen.dart';
import 'splash_auth_screen.dart';
import 'verification_screen.dart';

enum AuthStep { splash, onboarding, phone, signup, otp, credentials, verification, profile }

class SellerAuthFlow extends StatefulWidget {
  const SellerAuthFlow({
    SellerAuthApi? authApi,
    DeviceIdentityProvider? deviceIdentityProvider,
    super.key,
  }) : authApi = authApi ?? const NetworkSellerAuthApi(),
       deviceIdentityProvider =
           deviceIdentityProvider ?? const PlatformDeviceIdentityProvider();

  final SellerAuthApi authApi;
  final DeviceIdentityProvider deviceIdentityProvider;

  @override
  State<SellerAuthFlow> createState() => _SellerAuthFlowState();
}

class _SellerAuthFlowState extends State<SellerAuthFlow> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpControllers = List.generate(
    6,
    (index) =>
        TextEditingController(),
  );
  final _otpFocusNodes = List.generate(6, (index) => FocusNode());

  AuthStep _step = AuthStep.splash;
  AuthStep _otpSourceStep = AuthStep.phone;
  PhoneCountry _selectedCountry = PhoneCountry.india;
  bool _hidePassword = true;
  bool _confirmPassword = true;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _submittingCredentials = false;
  bool _checkingStoredToken = true;
  bool _onboardingComplete = false;
  String? _authToken;
  String _authTokenType = 'Bearer';
  String? _sentOtp;
  SellerProfile? _profile;
  Timer? _splashTimer;
  final _tokenStorage = const SellerAuthTokenStorage();

  String get _fullPhoneNumber =>
      '${_selectedCountry.dialCode} ${_phoneController.text.trim()}';

  String get _apiPhoneNumber {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '${_selectedCountry.dialCode}$digits';
  }

  String get _otpCode =>
      _otpControllers.map((controller) => controller.text.trim()).join();

  bool get _otpComplete =>
      _otpControllers.every((controller) => controller.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _loadStoredToken();
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _goTo(AuthStep step) {
    _splashTimer?.cancel();
    final nextStep =
        step == AuthStep.phone && !_onboardingComplete
            ? AuthStep.onboarding
            : step;

    setState(() => _step = nextStep);
    if (step == AuthStep.splash) {
      _scheduleSplashAutoAdvance();
    }
  }

  Future<void> _loadStoredToken() async {
    final token = await _tokenStorage.loadToken();
    final tokenType = await _tokenStorage.loadTokenType();

    if (!mounted) return;
    if (token != null && token.trim().isNotEmpty) {
      setState(() {
        _authToken = token;
        _authTokenType = tokenType;
        _checkingStoredToken = false;
        _step = AuthStep.verification;
      });
      return;
    }

    setState(() => _checkingStoredToken = false);
    _scheduleSplashAutoAdvance();
  }

  void _finishSplash() {
    _splashTimer?.cancel();
    _goTo(AuthStep.onboarding);
  }

  void _finishOnboarding() {
    _onboardingComplete = true;
    _goTo(AuthStep.phone);
  }

  void _scheduleSplashAutoAdvance() {
    _splashTimer?.cancel();
    _splashTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted && _step == AuthStep.splash) {
        _finishSplash();
      }
    });
  }

  void _goBack() {
    switch (_step) {
      case AuthStep.splash:
      case AuthStep.onboarding:
      case AuthStep.phone:
        _goTo(AuthStep.splash);
        break;
      case AuthStep.signup:
        _goTo(AuthStep.phone);
        break;
      case AuthStep.otp:
        _goTo(_otpSourceStep);
        break;
      case AuthStep.credentials:
        _goTo(AuthStep.otp);
        break;
      case AuthStep.verification:
        break;
      case AuthStep.profile:
        break;
    }
  }

  void _sendOtpFrom(AuthStep sourceStep, {String? otp}) {
    _otpSourceStep = sourceStep;
    _sentOtp = otp;
    _goTo(AuthStep.otp);
  }

  Future<void> _requestOtp(AuthStep sourceStep) async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _showErrorMessage('Enter your phone number');
      return;
    }

    setState(() => _sendingOtp = true);
    try {
      final deviceIdentity = await widget.deviceIdentityProvider.load();
      final result = await widget.authApi.sendOtp(
        SellerOtpRequest(
          phoneNumber: _apiPhoneNumber,
          deviceIdentity: deviceIdentity,
        ),
      );

      if (!mounted) return;
      _showInfoMessage(result.message);
      _sendOtpFrom(sourceStep, otp: result.otp);
      if (result.otp != null) {
        _showOtpMessage(result.otp!);
      }
    } on SellerAuthException catch (error) {
      if (mounted) _showErrorMessage(error.message);
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpComplete || _verifyingOtp) return;

    setState(() => _verifyingOtp = true);
    try {
      final deviceIdentity = await widget.deviceIdentityProvider.load();
      final result = await widget.authApi.verifyOtp(
        VerifySellerOtpRequest(
          phoneNumber: _apiPhoneNumber,
          deviceIdentity: deviceIdentity,
          otp: _otpCode,
        ),
      );

      if (!mounted) return;
      if (result.token.isNotEmpty) {
        await _tokenStorage.saveToken(
          token: result.token,
          tokenType: result.tokenType,
        );
        _authToken = result.token;
        _authTokenType = result.tokenType;
      }
      _showInfoMessage(result.message);
      _goTo(AuthStep.credentials);
    } on SellerAuthException catch (error) {
      if (mounted) _showErrorMessage(error.message);
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  void _selectPhoneCountry(PhoneCountry country) {
    if (_selectedCountry == country) return;
    setState(() => _selectedCountry = country);
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorMessage(String message) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: palette.error, content: Text(message)),
    );
  }

  Future<void> _submitMailAddress({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (_submittingCredentials) return;

    final token = _authToken ?? await _tokenStorage.loadToken();
    final tokenType = _authToken != null
        ? _authTokenType
        : await _tokenStorage.loadTokenType();

    if (token == null || token.trim().isEmpty) {
      _showErrorMessage('Login token missing. Please verify OTP again.');
      return;
    }

    setState(() => _submittingCredentials = true);
    try {
      final result = await widget.authApi.submitMailAddress(
        SellerMailAddressRequest(
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
        ),
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      _showInfoMessage(result.message);
      _goTo(AuthStep.verification);
    } on SellerAuthException catch (error) {
      if (mounted) _showErrorMessage(error.message);
    } finally {
      if (mounted) setState(() => _submittingCredentials = false);
    }
  }

  void _showOtpMessage(String otp) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(minutes: 1),
          content: Text('Your OTP is $otp'),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
  }

  void _openProfile(SellerProfile profile) {
    setState(() {
      _profile = profile;
      _step = AuthStep.profile;
    });
  }

  void _showDoneMessage() {
    _showInfoMessage('Seller account setup complete');
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStoredToken) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final useLightSystemUi =
        _step == AuthStep.splash || _step == AuthStep.onboarding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: useLightSystemUi
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Theme.of(
                context,
              ).extension<AuthPalette>()!.screen,
            ),
      child: SizedBox.expand(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 430),
          reverseDuration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            final slide =
                Tween<Offset>(
                  begin: const Offset(0, 0.045),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

            final scale = Tween<double>(begin: 0.985, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(scale: scale, child: child),
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<AuthStep>(_step),
            child: switch (_step) {
              AuthStep.splash => SplashAuthScreen(onContinue: _finishSplash),
              AuthStep.onboarding => OnboardingAuthScreen(
                onFinished: _finishOnboarding,
              ),
              AuthStep.phone => _onboardingComplete
                  ? PhoneAuthScreen(
                      controller: _phoneController,
                      country: _selectedCountry,
                      onCountryChanged: _selectPhoneCountry,
                      loading: _sendingOtp,
                      onSendOtp: () => _requestOtp(AuthStep.phone),
                      onSignup: () => _goTo(AuthStep.signup),
                    )
                  : OnboardingAuthScreen(onFinished: _finishOnboarding),
              AuthStep.signup => SignupPhoneAuthScreen(
                controller: _phoneController,
                country: _selectedCountry,
                onCountryChanged: _selectPhoneCountry,
                loading: _sendingOtp,
                onSendOtp: () => _requestOtp(AuthStep.signup),
                onBack: _goBack,
                onSignin: () => _goTo(AuthStep.phone),
              ),
              AuthStep.otp => OtpAuthScreen(
                phoneNumber: _fullPhoneNumber,
                otp: _sentOtp,
                controllers: _otpControllers,
                focusNodes: _otpFocusNodes,
                otpComplete: _otpComplete,
                onOtpChanged: (_) => setState(() {}),
                onBack: _goBack,
                onChangeNumber: () => _goTo(_otpSourceStep),
                loading: _verifyingOtp,
                onVerify: _verifyOtp,
              ),
              AuthStep.credentials => CredentialsAuthScreen(
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                hidePassword: _hidePassword,
                confirmPassword: _confirmPassword,
                onTogglePassword: () {
                  setState(() {
                    _hidePassword = !_hidePassword;
                  });
                },
                onToggleCPassword: () {
                  setState(() {
                    _confirmPassword = !_confirmPassword;
                  });
                },
                onBack: _goBack,
                loading: _submittingCredentials,
                onContinue: _submitMailAddress,
              ),
              AuthStep.verification => VerificationScreen(
                authApi: widget.authApi,
                tokenStorage: _tokenStorage,
                onProfileLoaded: _openProfile,
              ),
              AuthStep.profile => ProfileReviewScreen(
                profile: _profile,
                authApi: widget.authApi,
                tokenStorage: _tokenStorage,
              ),
            },
          ),
        ),
      ),
    );
  }
}
