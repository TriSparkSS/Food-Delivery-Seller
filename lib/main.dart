import 'package:flutter/material.dart';

import 'features/auth/data/device_identity.dart';
import 'features/auth/data/seller_auth_api.dart';
import 'features/auth/screens/auth_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FoodHubSellerApp());
}

class FoodHubSellerApp extends StatelessWidget {
  const FoodHubSellerApp({
    this.authApi,
    this.deviceIdentityProvider,
    super.key,
  });

  final SellerAuthApi? authApi;
  final DeviceIdentityProvider? deviceIdentityProvider;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodHub Seller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: SellerAuthFlow(
        authApi: authApi,
        deviceIdentityProvider: deviceIdentityProvider,
      ),
    );
  }
}
