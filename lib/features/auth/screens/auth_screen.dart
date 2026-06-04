import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';
import '../data/device_identity.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';
import '../widgets/auth_components.dart';
import 'credentials_auth_screen.dart';
import 'complete_verification_screen.dart';
import 'onboarding_auth_screen.dart';
import 'otp_auth_screen.dart';
import 'phone_auth_screen.dart';
import 'profile_review_screen.dart';
import 'splash_auth_screen.dart';
import 'store_details_screen.dart';
import 'verification_screen.dart';
import '../../seller/screens/seller_dashboard_screen.dart';

enum AuthStep {
  splash,
  onboarding,
  phone,
  signup,
  otp,
  credentials,
  verification,
  profile,
  store,
  completeVerification,
}

class SellerAuthFlow extends StatefulWidget {
  const SellerAuthFlow({
    SellerAuthApi? authApi,
    DeviceIdentityProvider? deviceIdentityProvider,
    this.startAtPhone = false,
    super.key,
  }) : authApi = authApi ?? const NetworkSellerAuthApi(),
       deviceIdentityProvider =
            deviceIdentityProvider ?? const PlatformDeviceIdentityProvider();

  final SellerAuthApi authApi;
  final DeviceIdentityProvider deviceIdentityProvider;
  final bool startAtPhone;

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
  bool _resumedFromStoredToken = false;
  String? _authToken;
  String _authTokenType = 'Bearer';
  String? _sentOtp;
  String? _verificationStatusMessage;
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
    if (widget.startAtPhone) {
      _checkingStoredToken = false;
      _onboardingComplete = true;
      _step = AuthStep.phone;
      return;
    }
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
    setState(() => _checkingStoredToken = false);
    _scheduleSplashAutoAdvance();
  }

  Future<void> _finishSplash() async {
    _splashTimer?.cancel();
    final token = await _tokenStorage.loadToken();
    final tokenType = await _tokenStorage.loadTokenType();

    if (!mounted) return;
    if (token != null && token.trim().isNotEmpty) {
      final storedStatus = await _loadFreshStoredAuthStatus(token, tokenType);
      if (!mounted) return;

      setState(() {
        _authToken = token;
        _authTokenType = tokenType;
        _checkingStoredToken = false;
        _onboardingComplete = true;
        _resumedFromStoredToken = true;
      });
      _routeAfterStoredToken(storedStatus);
      return;
    }
    _goTo(AuthStep.onboarding);
  }

  void _finishOnboarding() {
    _onboardingComplete = true;
    _goTo(AuthStep.phone);
  }

  void _handleLoggedOut() {
    _splashTimer?.cancel();
    _phoneController.clear();
    _emailController.clear();
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _authToken = null;
      _authTokenType = 'Bearer';
      _sentOtp = null;
      _verificationStatusMessage = null;
      _profile = null;
      _selectedCountry = PhoneCountry.india;
      _hidePassword = true;
      _confirmPassword = true;
      _sendingOtp = false;
      _verifyingOtp = false;
      _submittingCredentials = false;
      _onboardingComplete = true;
      _resumedFromStoredToken = false;
      _step = AuthStep.phone;
    });
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
        _goTo(_resumedFromStoredToken ? AuthStep.phone : AuthStep.otp);
        break;
      case AuthStep.verification:
        break;
      case AuthStep.profile:
        break;
      case AuthStep.store:
        _goTo(AuthStep.profile);
        break;
      case AuthStep.completeVerification:
        break;
    }
  }

  void _sendOtpFrom(AuthStep sourceStep, {String? otp}) {
    _otpSourceStep = sourceStep;
    _sentOtp = otp;
    _goTo(AuthStep.otp);
  }

  Future<void> _requestOtp(AuthStep sourceStep) async {
    if (_sendingOtp) return;

    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _showErrorMessage('Enter your phone number');
      return;
    }

    setState(() => _sendingOtp = true);
    try {
      final registrationStatus = await widget.authApi.isRegistered(
        SellerRegistrationStatusRequest(phoneNumber: _apiPhoneNumber),
      );

      if (!mounted) return;

      if (sourceStep == AuthStep.phone && !registrationStatus.isRegistered) {
        _showInfoMessage(registrationStatus.message);
        return;
      }

      if (sourceStep == AuthStep.signup && registrationStatus.isRegistered) {
        _showInfoMessage('This number is already registered. Please sign in.');
        return;
      }

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

  Future<bool> _resendOtp() async {
    if (_sendingOtp) return false;

    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _showErrorMessage('Enter your phone number');
      return false;
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

      if (!mounted) return false;
      for (final controller in _otpControllers) {
        controller.clear();
      }
      if (_otpFocusNodes.isNotEmpty) {
        _otpFocusNodes.first.requestFocus();
      }
      setState(() => _sentOtp = result.otp);
      _showInfoMessage(result.message);
      if (result.otp != null) {
        _showOtpMessage(result.otp!);
      }
      return true;
    } on SellerAuthException catch (error) {
      if (mounted) _showErrorMessage(error.message);
      return false;
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
      _resumedFromStoredToken = false;
      if (result.token.isNotEmpty) {
        await _tokenStorage.saveToken(
          token: result.token,
          tokenType: result.tokenType,
        );
        _authToken = result.token;
        _authTokenType = result.tokenType;
      }
      await _tokenStorage.saveAuthStatus(
        isNewSeller: result.isNewSeller,
        isEmailVerified: result.isEmailVerified,
        requiresRestaurantDetails: result.requiresRestaurantDetails,
        status: result.status,
        verificationStatus: result.verificationStatus,
      );
      _showInfoMessage(result.message);
      _routeAfterOtpVerification(result);

    } on SellerAuthException catch (error) {
      if (mounted) _showErrorMessage(error.message);
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  void _routeAfterOtpVerification(SellerVerifyOtpResponse result) {
    _profile = null;

    if (!result.isEmailVerified) {
      _verificationStatusMessage = null;
      _goTo(AuthStep.credentials);
      return;
    }

    if (result.isVerificationApproved) {
      _routeAfterApprovedVerification(result);
      return;
    }

    if (result.isVerificationInReview) {
      _verificationStatusMessage = null;
      _goTo(AuthStep.profile);
      return;
    }

    if (result.isVerificationFailed) {
      final statusMessage = 'Didit status: ${result.verificationStatusLabel}';
      _verificationStatusMessage = statusMessage;
      _showInfoMessage(statusMessage);
      _goTo(AuthStep.verification);
      return;
    }

    if (!result.isVerificationApproved) {
      final statusMessage = 'Didit status: ${result.verificationStatusLabel}';
      _verificationStatusMessage = statusMessage;
      _showInfoMessage(statusMessage);
      _goTo(AuthStep.verification);
      return;
    }
  }

  void _routeAfterApprovedVerification(SellerVerifyOtpResponse result) {
    _verificationStatusMessage = null;

    if (result.requiresRestaurantDetails ||
        _isOnboardingSellerStatus(result.status)) {
      _goTo(AuthStep.store);
      return;
    }

    if (_isPendingSellerStatus(result.status)) {
      _goTo(AuthStep.completeVerification);
      return;
    }

    _openDashboard();
  }

  void _routeAfterStoredToken(SellerStoredAuthStatus status) {
    _profile = null;

    final emailVerified = status.isEmailVerified == true;
    final verificationApproved = _isApprovedVerificationStatus(
      status.verificationStatus,
    );

    if (!emailVerified) {
      _verificationStatusMessage = null;
      _goTo(AuthStep.credentials);
      return;
    }

    if (!verificationApproved) {
      final label = _authRouteStatusLabel(status.verificationStatus);
      _verificationStatusMessage = 'Didit status: $label';
      _goTo(AuthStep.verification);
      return;
    }

    if (_isOnboardingSellerStatus(status.status)) {
      _verificationStatusMessage = null;
      _goTo(AuthStep.store);
      return;
    }

    if (_isPendingSellerStatus(status.status)) {
      _verificationStatusMessage = null;
      _goTo(AuthStep.completeVerification);
      return;
    }

    _verificationStatusMessage = null;
    _openDashboard();
  }

  bool _isApprovedVerificationStatus(String? status) {
    final value = _normalizeAuthRouteValue(status);
    return value == 'approved' || value == 'verified';
  }

  bool _isOnboardingSellerStatus(String? status) {
    final value = _normalizeAuthRouteValue(status);
    return value == 'onboard' || value == 'onboarding';
  }

  bool _isPendingSellerStatus(String? status) {
    final value = _normalizeAuthRouteValue(status);
    return value == 'pending' ||
        value == 'pending_review' ||
        value == 'under_review' ||
        value == 'in_review';
  }

  String _normalizeAuthRouteValue(String? value) {
    return value?.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_') ??
        '';
  }

  String _authRouteStatusLabel(String? status) {
    final value = status?.trim().replaceAll('_', ' ') ?? '';
    if (value.isEmpty) return 'Pending Review';

    return value
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  Future<SellerStoredAuthStatus> _loadFreshStoredAuthStatus(
    String token,
    String tokenType,
  ) async {
    final storedStatus = await _tokenStorage.loadAuthStatus();

    if (storedStatus.isEmailVerified != true) {
      return storedStatus;
    }

    var latestSellerStatus = storedStatus.status;
    var latestVerificationStatus = storedStatus.verificationStatus;

    try {
      final latestStatus = await widget.authApi.fetchVerificationStatus(
        token: token,
        tokenType: tokenType,
      );
      latestVerificationStatus = latestStatus.status ?? latestVerificationStatus;
    } catch (_) {}

    try {
      final profile = await widget.authApi.fetchProfile(
        token: token,
        tokenType: tokenType,
      );
      latestSellerStatus = profile.status ?? latestSellerStatus;
      latestVerificationStatus =
          profile.verificationStatus ??
          profile.latestVerificationStatus ??
          latestVerificationStatus;
    } catch (_) {}

    await _tokenStorage.saveAuthStatus(
      isNewSeller: storedStatus.isNewSeller ?? false,
      isEmailVerified: true,
      requiresRestaurantDetails: storedStatus.requiresRestaurantDetails ?? false,
      status: latestSellerStatus,
      verificationStatus: latestVerificationStatus,
    );

    return _tokenStorage.loadAuthStatus();
  }

  void _openDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => SellerDashboardScreen(
          authApi: widget.authApi,
          tokenStorage: _tokenStorage,
          onLoggedOut: _handleLoggedOut,
        ),
      ),
    );
  }

  void _selectPhoneCountry(PhoneCountry country) {
    if (_selectedCountry == country) return;
    setState(() => _selectedCountry = country);
  }

  void _showInfoMessage(String message) {
    _showToast(message);
  }

  void _showErrorMessage(String message) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    _showToast(message, backgroundColor: palette.error);
  }

  void _showToast(String message, {Color? backgroundColor}) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor ?? palette.greenDark,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        elevation: 0,
        duration: const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                onResendOtp: _resendOtp,
                loading: _verifyingOtp,
                resending: _sendingOtp,
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
                initialStatus: _verificationStatusMessage,
                onProfileLoaded: _openProfile,
              ),
              AuthStep.profile => ProfileReviewScreen(
                profile: _profile,
                authApi: widget.authApi,
                tokenStorage: _tokenStorage,
                onLoggedOut: _handleLoggedOut,
              ),
              AuthStep.store => StoreDetailsScreen(
                profile: _profile,
                authApi: widget.authApi,
                tokenStorage: _tokenStorage,
                onLoggedOut: _handleLoggedOut,
              ),
              AuthStep.completeVerification => CompleteVerificationScreen(
                authApi: widget.authApi,
                tokenStorage: _tokenStorage,
                message: _verificationStatusMessage,
                onLoggedOut: _handleLoggedOut,
              ),
            },
          ),
        ),
      ),
    );
  }
}
