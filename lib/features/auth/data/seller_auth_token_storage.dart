import 'package:shared_preferences/shared_preferences.dart';

class SellerAuthTokenStorage {
  const SellerAuthTokenStorage();

  static const _tokenKey = 'seller_auth_token';
  static const _tokenTypeKey = 'seller_auth_token_type';
  static const _isNewSellerKey = 'seller_is_new_seller';
  static const _isEmailVerifiedKey = 'seller_is_email_verified';
  static const _sellerStatusKey = 'seller_status';
  static const _verificationStatusKey = 'seller_verification_status';
  static const _requiresRestaurantDetailsKey =
      'seller_requires_restaurant_details';

  Future<void> saveToken({required String token, required String tokenType}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    await preferences.setString(_tokenTypeKey, tokenType);
  }

  Future<String?> loadToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  Future<String> loadTokenType() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenTypeKey) ?? 'Bearer';
  }

  Future<void> saveAuthStatus({
    required bool isNewSeller,
    required bool isEmailVerified,
    required bool requiresRestaurantDetails,
    String? status,
    String? verificationStatus,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_isNewSellerKey, isNewSeller);
    await preferences.setBool(_isEmailVerifiedKey, isEmailVerified);
    await preferences.setBool(
      _requiresRestaurantDetailsKey,
      requiresRestaurantDetails,
    );

    final cleanStatus = status?.trim();
    if (cleanStatus == null || cleanStatus.isEmpty) {
      await preferences.remove(_sellerStatusKey);
    } else {
      await preferences.setString(_sellerStatusKey, cleanStatus);
    }

    final cleanVerificationStatus = verificationStatus?.trim();
    if (cleanVerificationStatus == null || cleanVerificationStatus.isEmpty) {
      await preferences.remove(_verificationStatusKey);
    } else {
      await preferences.setString(
        _verificationStatusKey,
        cleanVerificationStatus,
      );
    }
  }

  Future<SellerStoredAuthStatus> loadAuthStatus() async {
    final preferences = await SharedPreferences.getInstance();
    return SellerStoredAuthStatus(
      isNewSeller: preferences.getBool(_isNewSellerKey),
      isEmailVerified: preferences.getBool(_isEmailVerifiedKey),
      requiresRestaurantDetails: preferences.getBool(
        _requiresRestaurantDetailsKey,
      ),
      status: preferences.getString(_sellerStatusKey),
      verificationStatus: preferences.getString(_verificationStatusKey),
    );
  }

  Future<void> clearToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_tokenTypeKey);
    await preferences.remove(_isNewSellerKey);
    await preferences.remove(_isEmailVerifiedKey);
    await preferences.remove(_sellerStatusKey);
    await preferences.remove(_verificationStatusKey);
    await preferences.remove(_requiresRestaurantDetailsKey);
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }
}

class SellerStoredAuthStatus {
  const SellerStoredAuthStatus({
    required this.isNewSeller,
    required this.isEmailVerified,
    required this.requiresRestaurantDetails,
    this.status,
    this.verificationStatus,
  });

  final bool? isNewSeller;
  final bool? isEmailVerified;
  final bool? requiresRestaurantDetails;
  final String? status;
  final String? verificationStatus;

  bool get hasSavedStatus {
    return isNewSeller != null ||
        isEmailVerified != null ||
        requiresRestaurantDetails != null ||
        (status != null && status!.trim().isNotEmpty) ||
        (verificationStatus != null && verificationStatus!.trim().isNotEmpty);
  }
}
