import 'package:shared_preferences/shared_preferences.dart';

class SellerAuthTokenStorage {
  const SellerAuthTokenStorage();

  static const _tokenKey = 'seller_auth_token';
  static const _tokenTypeKey = 'seller_auth_token_type';

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

  Future<void> clearToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_tokenTypeKey);
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }
}
