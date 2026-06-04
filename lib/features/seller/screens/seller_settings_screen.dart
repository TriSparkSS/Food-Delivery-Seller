
import 'package:flutter/material.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_dashboard_screen.dart';
import 'package:qadam_food_seller/features/seller/screens/seller_menu_screen.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/seller_auth_api.dart';
import '../../auth/data/seller_auth_token_storage.dart';
import '../../auth/screens/auth_screen.dart';

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
  bool _holidayMode = false;
  final List<bool> _businessDays = [true, true, true, true, true, true, false];
  bool _newOrders = true;
  bool _orderUpdates = true;
  bool _reviews = false;
  bool _promotions = false;
  bool _loggingOut = false;
  bool _deletingAccount = false;
  bool _loadingStoreSummary = false;
  SellerRestaurantProfile? _settingsRestaurant;
  SellerVerificationStatusResponse? _settingsVerificationStatus;

  @override
  void initState() {
    super.initState();
    _loadStoreSummary();
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
      final verification = await widget.authApi.fetchVerificationStatus(
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      setState(() {
        _settingsRestaurant = restaurant;
        _settingsVerificationStatus = verification;
      });
    } on SellerAuthException catch (error) {
      if (mounted) _showSettingsMessage(error.message, error: true);
    } finally {
      if (mounted) setState(() => _loadingStoreSummary = false);
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
        } catch (_) {
          // Local logout should still complete if the remote session is already gone.
        }
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
    final restaurant = _settingsRestaurant;
    final status = _settingsVerificationStatus;
    final statusColor = _settingsStatusColor(status, palette);
    final statusLabel = _settingsStatusLabel(status);
    final storeName =
    restaurant?.restaurantName?.trim().isNotEmpty == true
        ? restaurant!.restaurantName!.trim()
        : widget.restaurantName;
    final city =
    restaurant?.city?.trim().isNotEmpty == true
        ? restaurant!.city!.trim()
        : 'City not set';

    return SellerWorkScaffold(
      horizontalPadding: 18,
      title: 'Settings',
      subtitle: 'Store, hours, alerts, and account',
      trailing: const SellerHeaderIcon(Icons.settings_rounded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellerCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _SettingsStoreLogo(
                  logoUrl: restaurant?.restaurantLogo,
                  loading: _loadingStoreSummary,
                ),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SellerMutedText(city, fontSize: 13),
                      const SizedBox(height: 3),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Edit →',
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6F6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFCECE), width: 1.1),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Holiday Mode',
                        style: TextStyle(
                          color: Color(0xFFFF4338),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      SellerMutedText(
                        'Pause all incoming orders',
                        fontSize: 12,
                      ),
                    ],
                  ),
                ),
                SellerSwitch(
                  value: _holidayMode,
                  onChanged: (value) => setState(() => _holidayMode = value),
                  active: const Color(0xFFFF4338),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SellerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SellerSectionTitle('Business Hours', fontSize: 15),
                const SizedBox(height: 18),
                ...List.generate(_businessDays.length, (index) {
                  const days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  const hours = [
                    '09:00 AM - 11:00 PM',
                    '09:00 AM - 11:00 PM',
                    '09:00 AM - 11:00 PM',
                    '09:00 AM - 11:00 PM',
                    '09:00 AM - 11:30 PM',
                    '10:00 AM - 12:00 AM',
                    'Closed',
                  ];
                  final closed = !_businessDays[index];
                  return _SettingsRow(
                    label: days[index],
                    value: hours[index],
                    valueColor: closed ? const Color(0xFFFF4338) : null,
                    control: SellerSwitch(
                      value: _businessDays[index],
                      onChanged: (value) {
                        setState(() => _businessDays[index] = value);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SellerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SellerSectionTitle('Delivery & Orders', fontSize: 15),
                const SizedBox(height: 18),
                const _SimpleSettingRow(
                  label: 'Delivery Radius',
                  value: '5 km',
                ),
                const SellerDivider(),
                const _SimpleSettingRow(
                  label: 'Min. Order Value',
                  value: r'$10.00',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SellerCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🏦', style: TextStyle(fontSize: 21)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HDFC Bank',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 4),
                      SellerMutedText('****4521', fontSize: 12),
                    ],
                  ),
                ),
                Text(
                  'Change',
                  style: TextStyle(
                    color: palette.greenDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SellerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SellerSectionTitle('Notifications', fontSize: 15),
                const SizedBox(height: 18),
                _NotificationRow(
                  label: 'New Orders',
                  value: _newOrders,
                  onChanged: (value) => setState(() => _newOrders = value),
                ),
                const SellerDivider(),
                _NotificationRow(
                  label: 'Order Updates',
                  value: _orderUpdates,
                  onChanged: (value) => setState(() => _orderUpdates = value),
                ),
                const SellerDivider(),
                _NotificationRow(
                  label: 'Reviews',
                  value: _reviews,
                  onChanged: (value) => setState(() => _reviews = value),
                ),
                const SellerDivider(),
                _NotificationRow(
                  label: 'Promotions',
                  value: _promotions,
                  onChanged: (value) => setState(() => _promotions = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SettingsActionButton(
            icon: Icons.logout_rounded,
            label: 'Logout',
            loading: _loggingOut,
            onTap: _showLogoutDialog,
          ),
          const SizedBox(height: 10),
          _SettingsActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Account',
            destructive: true,
            loading: _deletingAccount,
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
}

Color _settingsStatusColor(
    SellerVerificationStatusResponse? status,
    AuthPalette palette,
    ) {
  if (status == null) return palette.mutedText;
  if (status.isApproved) return palette.greenDark;
  if (status.isFailed) return const Color(0xFFFF4338);
  return const Color(0xFFFF9F0A);
}

String _settingsStatusLabel(SellerVerificationStatusResponse? status) {
  if (status == null) return 'Checking status';
  if (status.isApproved) return '✓ ${status.statusLabel}';
  if (status.isFailed) return status.statusLabel;
  return status.statusLabel;
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
      return Text(
        '🌿',
        style: const TextStyle(fontSize: 26, color: Colors.white),
      );
    }

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.greenDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: loading
          ? const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : url == null || url.isEmpty
          ? fallback()
          : Image.network(
        url,
        width: 56,
        height: 56,
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
          letterSpacing: 0,
        ),
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: TextStyle(
          color: palette.mutedText,
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: palette.greenDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Logout',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
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
          letterSpacing: 0,
        ),
      ),
      content: Text(
        'Are you sure you want to delete?',
        style: TextStyle(
          color: palette.mutedText,
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF4338),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Yes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final color = destructive ? const Color(0xFFFF4338) : palette.greenDark;
    final background = destructive
        ? const Color(0xFFFFF1F2)
        : palette.softGreen.withValues(alpha: 0.72);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              loading
                  ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
                  : Icon(icon, color: color, size: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    required this.control,
    this.valueColor,
  });

  final String label;
  final String value;
  final Widget control;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: palette.text.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? palette.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          control,
        ],
      ),
    );
  }
}

class _SimpleSettingRow extends StatelessWidget {
  const _SimpleSettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: value == '5 km' ? palette.greenDark : palette.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: palette.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SellerSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
