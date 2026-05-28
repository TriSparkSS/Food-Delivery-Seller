import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qadam_food_seller/features/auth/data/device_identity.dart';
import 'package:qadam_food_seller/features/auth/data/seller_auth_api.dart';
import 'package:qadam_food_seller/main.dart';

void main() {
  testWidgets('starts on the FoodHub splash screen', (tester) async {
    await tester.pumpWidget(
      const FoodHubSellerApp(
        authApi: _FakeSellerAuthApi(),
        deviceIdentityProvider: _FakeDeviceIdentityProvider(),
      ),
    );

    expect(find.text('FoodHub Seller'), findsOneWidget);
    expect(find.text('Manage your restaurant on the go'), findsOneWidget);
    expect(find.text('POWERED BY FOODHUB'), findsOneWidget);
  });

  testWidgets('moves through phone, otp, and credentials auth steps', (
    tester,
  ) async {
    await tester.pumpWidget(const FoodHubSellerApp());

    await tester.tap(find.text('FoodHub Seller'));
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
  Future<SellerAuthResult> sendOtp(SellerOtpRequest request) async {
    return const SellerAuthResult(message: 'OTP sent');
  }

  @override
  Future<SellerAuthResult> verifyOtp(VerifySellerOtpRequest request) async {
    return const SellerAuthResult(message: 'OTP verified');
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
