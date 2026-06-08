
import 'package:flutter/material.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_menu_screen.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/seller_auth_api.dart';
import '../../auth/data/seller_auth_token_storage.dart';
import '../../auth/screens/auth_screen.dart';
import '../../auth/screens/profile_review_screen.dart';
import '../../auth/screens/store_details_screen.dart';
import 'business_hours_screen.dart';
import 'operations_settings_screen.dart';

class SellerSettingsScreen extends StatefulWidget {
  const SellerSettingsScreen({
    required this.authApi,
    required this.tokenStorage,
    required this.restaurantName,
    this.onLoggedOut,
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final String restaurantName;
  final VoidCallback? onLoggedOut;

  @override
  State<SellerSettingsScreen> createState() => _SellerSettingsScreenState();
}

class _SellerSettingsScreenState extends State<SellerSettingsScreen> {
  bool _loggingOut = false;
  bool _deletingAccount = false;
  bool _loadingProfile = false;
  bool _loadingStoreSummary = false;
  bool _loadingBusinessHours = false;
  SellerProfile? _settingsProfile;
  SellerRestaurantProfile? _settingsRestaurant;
  String _businessHoursSummary = 'Loading schedule...';

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    await Future.wait([
      _loadProfileSummary(),
      _loadStoreSummary(),
      _loadBusinessHoursSummary(),
    ]);
  }

  Future<void> _loadProfileSummary() async {
    if (_loadingProfile) return;

    setState(() => _loadingProfile = true);
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

      if (!mounted) return;
      setState(() => _settingsProfile = profile);
    } on SellerAuthException catch (error) {
      if (mounted) _showSettingsMessage(error.message, error: true);
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadStoreSummary() async {
    if (_loadingStoreSummary) return;

    setState(() => _loadingStoreSummary = true);
    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();

      if (token == null || token.trim().isEmpty) {
        throw const SellerAuthException('Authentication failed. Login again.');
      }

      final restaurant = await widget.authApi.fetchRestaurant(
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      setState(() => _settingsRestaurant = restaurant);
    } on SellerAuthException catch (error) {
      if (mounted) _showSettingsMessage(error.message, error: true);
    } finally {
      if (mounted) setState(() => _loadingStoreSummary = false);
    }
  }

  Future<void> _loadBusinessHoursSummary() async {
    if (_loadingBusinessHours) return;

    setState(() => _loadingBusinessHours = true);
    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();

      if (token == null || token.trim().isEmpty) {
        throw const SellerAuthException('Authentication failed. Login again.');
      }

      final hours = await widget.authApi.fetchBusinessHours(
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      setState(() => _businessHoursSummary = summarizeBusinessHours(hours));
    } on SellerAuthException catch (error) {
      if (mounted) {
        setState(() => _businessHoursSummary = 'Unable to load schedule');
        _showSettingsMessage(error.message, error: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _businessHoursSummary = 'Unable to load schedule');
      }
    } finally {
      if (mounted) setState(() => _loadingBusinessHours = false);
    }
  }

  Future<void> _openProfileDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileReviewScreen(
          authApi: widget.authApi,
          tokenStorage: widget.tokenStorage,
          profile: _settingsProfile,
          readOnly: true,
        ),
      ),
    );
    if (!mounted) return;
    await _loadProfileSummary();
  }

  Future<void> _openStoreDetails() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => StoreDetailsScreen(
          authApi: widget.authApi,
          tokenStorage: widget.tokenStorage,
          profile: _settingsProfile,
          fromSettings: true,
          onLoggedOut: widget.onLoggedOut,
        ),
      ),
    );

    if (updated == true && mounted) {
      await _loadStoreSummary();
    }
  }

  Future<void> _openOperations() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => OperationsSettingsScreen(
          authApi: widget.authApi,
          tokenStorage: widget.tokenStorage,
          profile: _settingsProfile,
        ),
      ),
    );

    if (updated == true && mounted) {
      await _loadStoreSummary();
    }
  }

  Future<void> _openBusinessHours() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => BusinessHoursScreen(
          authApi: widget.authApi,
          tokenStorage: widget.tokenStorage,
        ),
      ),
    );

    if (updated == true && mounted) {
      await _loadBusinessHoursSummary();
    }
  }

  Future<void> _showLogoutDialog() async {
    if (_loggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _LogoutDialog(),
    );
    if (confirmed == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);
    var openedAuth = false;
    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();

      if (token != null && token.trim().isNotEmpty) {
        try {
          await widget.authApi.logout(token: token, tokenType: tokenType);
        } catch (_) {}
      }
      await _clearSessionAndOpenGetStarted();
      openedAuth = true;
    } on SellerAuthException catch (error) {
      if (mounted) _showSettingsMessage(error.message, error: true);
    } finally {
      if (mounted && !openedAuth) setState(() => _loggingOut = false);
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    if (_deletingAccount) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_deletingAccount) return;

    setState(() => _deletingAccount = true);
    var openedAuth = false;
    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();

      if (token != null && token.trim().isNotEmpty) {
        await widget.authApi.deleteAccount(token: token, tokenType: tokenType);
      }
      await _clearSessionAndOpenGetStarted();
      openedAuth = true;
    } on SellerAuthException catch (error) {
      if (mounted) _showSettingsMessage(error.message, error: true);
    } finally {
      if (mounted && !openedAuth) setState(() => _deletingAccount = false);
    }
  }

  Future<void> _clearSessionAndOpenGetStarted() async {
    await widget.tokenStorage.clearAll();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => SellerAuthFlow(
          authApi: widget.authApi,
          startAtPhone: true,
        ),
      ),
      (route) => false,
    );
  }

  void _showSettingsMessage(String message, {bool error = false}) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error ? palette.error : null,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final profile = _settingsProfile;
    final restaurant = _settingsRestaurant;
    final statusColor = _settingsStatusColor(restaurant?.status, palette);
    final statusLabel = _settingsStatusText(restaurant?.status);
    final profileName = profile?.ownerFullName?.trim().isNotEmpty == true
        ? profile!.ownerFullName!.trim()
        : 'Seller profile';
    final profileEmail = profile?.email?.trim().isNotEmpty == true
        ? profile!.email!.trim()
        : 'Email not added';
    final storeName = restaurant?.restaurantName?.trim().isNotEmpty == true
        ? restaurant!.restaurantName!.trim()
        : widget.restaurantName;
    final city = restaurant?.city?.trim().isNotEmpty == true
        ? restaurant!.city!.trim()
        : 'City not set';
    final minOrder = restaurant?.minimumOrderAmount;
    final prepTime = restaurant?.averagePreparationTime;
    final deliveryRadius = restaurant?.deliveryRadius;
    return SellerWorkScaffold(
      horizontalPadding: 18,
      title: 'Settings',
      subtitle: 'Manage your restaurant and account',
      bottomPadding: 36,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsHeroCard(
            storeName: storeName,
            city: city,
            statusLabel: statusLabel,
            statusColor: statusColor,
            logoUrl: restaurant?.restaurantLogo,
            loading: _loadingStoreSummary,
            ownerName: profileName,
          ),
          const SizedBox(height: 22),
          _SettingsGroup(
            title: 'Seller Account',
            children: [
              _SettingsNavTile(
                icon: Icons.person_outline_rounded,
                iconColor: palette.greenDark,
                iconBackground: palette.softGreen.withValues(alpha: 0.9),
                title: 'Profile Details',
                subtitle: profileEmail,
                onTap: _openProfileDetails,
                trailing: _loadingProfile
                    ? _SettingsLoadingDot(color: palette.greenDark)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            title: 'Restaurant',
            children: [
              _SettingsNavTile(
                icon: Icons.storefront_rounded,
                iconColor: palette.greenDark,
                iconBackground: palette.softGreen.withValues(alpha: 0.9),
                title: 'Store Information',
                subtitle: '$city · Cuisine, address, and branding',
                onTap: _openStoreDetails,
              ),
              _SettingsDivider(),
              _SettingsNavTile(
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFFFF9F0A),
                iconBackground: const Color(0xFFFFF4E5),
                title: 'Business Hours',
                subtitle: _loadingBusinessHours
                    ? 'Loading weekly schedule...'
                    : _businessHoursSummary,
                onTap: _openBusinessHours,
                trailing: _loadingBusinessHours
                    ? _SettingsLoadingDot(color: const Color(0xFFFF9F0A))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            title: 'Operations',
            children: [
              _SettingsInfoTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Minimum Order',
                value: minOrder == null ? '—' : '₹${_formatSettingsNumber(minOrder)}',
              ),
              _SettingsDivider(),
              _SettingsInfoTile(
                icon: Icons.timer_outlined,
                title: 'Prep Time',
                value: prepTime == null ? '—' : '$prepTime min',
              ),
              _SettingsDivider(),
              _SettingsInfoTile(
                icon: Icons.delivery_dining_outlined,
                title: 'Delivery Radius',
                value: deliveryRadius == null
                    ? '—'
                    : '${deliveryRadius.round()} km',
              ),
              _SettingsDivider(),
              _SettingsNavTile(
                icon: Icons.tune_rounded,
                iconColor: palette.greenDark,
                iconBackground: palette.softGreen.withValues(alpha: 0.9),
                title: 'Update Operations',
                subtitle: 'Edit min order, prep time, and delivery radius',
                onTap: _openOperations,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            title: 'Support',
            children: [
              _SettingsNavTile(
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFF6B7280),
                iconBackground: const Color(0xFFF3F4F6),
                title: 'Help & Support',
                subtitle: 'Contact support for account or payout issues',
                onTap: () => _showSettingsMessage(
                  'Support channel will be available soon.',
                ),
              ),
              _SettingsDivider(),
              _SettingsNavTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF6B7280),
                iconBackground: const Color(0xFFF3F4F6),
                title: 'Terms & Policies',
                subtitle: 'Seller agreement and privacy policy',
                onTap: () => _showSettingsMessage(
                  'Policy documents will be available soon.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            title: 'Account Actions',
            children: [
              _SettingsNavTile(
                icon: Icons.logout_rounded,
                iconColor: palette.greenDark,
                iconBackground: palette.softGreen.withValues(alpha: 0.9),
                title: 'Logout',
                subtitle: 'Sign out from this device',
                onTap: _loggingOut ? null : _showLogoutDialog,
                trailing: _loggingOut
                    ? _SettingsLoadingDot(color: palette.greenDark)
                    : null,
              ),
              _SettingsDivider(),
              _SettingsNavTile(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFFF4338),
                iconBackground: const Color(0xFFFFF1F2),
                title: 'Delete Account',
                subtitle: 'Permanently remove your seller account',
                onTap: _deletingAccount ? null : _showDeleteAccountDialog,
                trailing: _deletingAccount
                    ? _SettingsLoadingDot(color: const Color(0xFFFF4338))
                    : null,
                titleColor: const Color(0xFFFF4338),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({
    required this.storeName,
    required this.city,
    required this.statusLabel,
    required this.statusColor,
    required this.logoUrl,
    required this.loading,
    required this.ownerName,
  });

  final String storeName;
  final String city;
  final String statusLabel;
  final Color statusColor;
  final String? logoUrl;
  final bool loading;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SellerCard(
      highlight: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _SettingsStoreLogo(logoUrl: logoUrl, loading: loading),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                SellerMutedText('$ownerName · $city', fontSize: 12),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        SellerCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SellerIconBadge(
                size: 42,
                background: iconBackground,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? palette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.mutedText,
                    size: 22,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: palette.mutedText, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: palette.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: palette.greenDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    return Divider(
      height: 1,
      thickness: 1,
      color: palette.fieldBorder.withValues(alpha: 0.75),
      indent: 70,
    );
  }
}

class _SettingsLoadingDot extends StatelessWidget {
  const _SettingsLoadingDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

String _formatSettingsNumber(num value) {
  final formatted = value.toStringAsFixed(2);
  return formatted.endsWith('.00')
      ? formatted.substring(0, formatted.length - 3)
      : formatted;
}

Color _settingsStatusColor(String? status, AuthPalette palette) {
  final value = _normalizeSettingsStatus(status);
  if (value.isEmpty) return palette.mutedText;
  if (value == 'approved' || value == 'verified' || value == 'active') {
    return palette.greenDark;
  }
  if (value == 'failed' ||
      value == 'rejected' ||
      value == 'declined' ||
      value == 'denied' ||
      value == 'expired' ||
      value == 'cancelled' ||
      value == 'canceled') {
    return const Color(0xFFFF4338);
  }
  return const Color(0xFFFF9F0A);
}

String _settingsStatusText(String? status) {
  final text = status?.trim().replaceAll(RegExp(r'[_-]+'), ' ') ?? '';
  if (text.isEmpty) return 'Pending review';
  return text
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) {
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  })
      .join(' ');
}

String _normalizeSettingsStatus(String? status) {
  return status?.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_') ?? '';
}

class _SettingsStoreLogo extends StatelessWidget {
  const _SettingsStoreLogo({required this.logoUrl, required this.loading});

  final String? logoUrl;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final url = logoUrl?.trim();

    Widget fallback() {
      return const Text('🌿', style: TextStyle(fontSize: 28, color: Colors.white));
    }

    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.greenDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: palette.greenDark.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: loading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : url == null || url.isEmpty
              ? fallback()
              : Image.network(
                  url,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => fallback(),
                ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return AlertDialog(
      backgroundColor: palette.screen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Logout',
        style: TextStyle(
          color: palette.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: TextStyle(color: palette.mutedText, fontSize: 14, height: 1.35),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: palette.mutedText)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: palette.greenDark),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return AlertDialog(
      backgroundColor: palette.screen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Delete Account',
        style: TextStyle(
          color: palette.text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        'Are you sure you want to delete your seller account?',
        style: TextStyle(color: palette.mutedText, fontSize: 14, height: 1.35),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: palette.mutedText)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF4338),
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
