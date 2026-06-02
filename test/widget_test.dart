import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qadam_food_seller/features/auth/data/device_identity.dart';
import 'package:qadam_food_seller/features/auth/data/seller_auth_api.dart';
import 'package:qadam_food_seller/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('starts on the QadamFoodHub seller splash screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FoodHubSellerApp(
        authApi: _FakeSellerAuthApi(),
        deviceIdentityProvider: _FakeDeviceIdentityProvider(),
      ),
    );
    await tester.pump();

    expect(find.text('QadamFoodHub Seller'), findsOneWidget);
    expect(find.text('Manage your restaurant on the go'), findsOneWidget);
  });

  testWidgets('moves through onboarding, phone, otp, and credentials auth steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FoodHubSellerApp(
        authApi: _FakeSellerAuthApi(),
        deviceIdentityProvider: _FakeDeviceIdentityProvider(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('QadamFoodHub Seller'));
    await tester.pumpAndSettle();
    expect(find.text('Set up your restaurant'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Manage every order'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Grow with clear insights'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);

    await tester.tap(find.text('+91'));
    await tester.pumpAndSettle();
    expect(find.text('Select country code'), findsOneWidget);

    await tester.tap(find.text('+992'));
    await tester.pumpAndSettle();
    expect(find.text('+992'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '921234567890');
    await tester.pumpAndSettle();
    expect(find.text('92 123 4567'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Verify OTP'), findsOneWidget);

    final otpFields = find.byType(TextField);
    await tester.enterText(otpFields.at(0), '2');
    await tester.enterText(otpFields.at(1), '9');
    await tester.enterText(otpFields.at(2), '6');
    await tester.enterText(otpFields.at(3), '1');
    await tester.enterText(otpFields.at(4), '2');
    await tester.enterText(otpFields.at(5), '3');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('Set Credentials'), findsOneWidget);
    expect(find.text('Strong password'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);

    final credentialFields = find.byType(TextField);
    await tester.enterText(credentialFields.at(0), 'bad-email');
    await tester.enterText(credentialFields.at(1), 'short');
    await tester.enterText(credentialFields.at(2), 'different');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(
      find.text('Use 8+ characters with at least one letter and one number'),
      findsOneWidget,
    );
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(credentialFields.at(0), 'seller@example.com');
    await tester.enterText(credentialFields.at(1), 'foodhub1');
    await tester.enterText(credentialFields.at(2), 'foodhub1');
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsNothing);
    expect(find.text('Passwords do not match'), findsNothing);
  });
}

class _FakeSellerAuthApi implements SellerAuthApi {
  const _FakeSellerAuthApi();

  @override
  Future<SellerRegistrationStatusResponse> isRegistered(
    SellerRegistrationStatusRequest request,
  ) async {
    return const SellerRegistrationStatusResponse(
      message: 'Seller registration status fetched successfully.',
      isRegistered: false,
    );
  }

  @override
  Future<SellerSendOtpResponse> sendOtp(SellerOtpRequest request) async {
    return const SellerSendOtpResponse(message: 'OTP sent', otp: '296587');
  }

  @override
  Future<SellerVerifyOtpResponse> verifyOtp(VerifySellerOtpRequest request) async {
    return const SellerVerifyOtpResponse(
      message: 'OTP verified',
      token: 'test-token',
      tokenType: 'Bearer',
      isNewSeller: true,
      requiresRestaurantDetails: true,
    );
  }

  @override
  Future<SellerAuthResult> submitMailAddress(
    SellerMailAddressRequest request, {
    required String token,
    String tokenType = 'Bearer',
  }) async {
    return const SellerAuthResult(message: 'Credentials saved');
  }

  @override
  Future<SellerVerificationSessionResponse> createVerificationSession({
    required String token,
    String tokenType = 'Bearer',
  }) async {
    return const SellerVerificationSessionResponse(
      message: 'Session created',
      sessionUrl: 'https://verify.didit.me/en/session/test',
      sessionId: 'test-session-id',
      sessionToken: 'test-sdk-token',
    );
  }

  @override
  Future<SellerProfile> fetchProfile({
    required String token,
    String tokenType = 'Bearer',
  }) async {
    return const SellerProfile(
      id: 2,
      ownerFullName: '',
      phoneNumber: '',
      email: '',
    );
  }

  @override
  Future<SellerAuthResult> submitRestaurant(
    SellerRestaurantRequest request, {
    required String token,
    String tokenType = 'Bearer',
  }) async {
    return const SellerAuthResult(message: 'Restaurant saved');
  }
}

class _FakeDeviceIdentityProvider implements DeviceIdentityProvider {
  const _FakeDeviceIdentityProvider();

  @override
  Future<DeviceIdentity> load() async {
    return const DeviceIdentity(
      deviceType: 'Android',
      deviceToken: 'test-device-token',
    );
  }
}
