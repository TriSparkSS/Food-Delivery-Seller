import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/seller_auth_api.dart';
import '../../auth/data/seller_auth_token_storage.dart';
import '../../auth/widgets/auth_components.dart';
import 'seller_menu_screen.dart';

class OperationsSettingsScreen extends StatefulWidget {
  const OperationsSettingsScreen({
    required this.authApi,
    required this.tokenStorage,
    this.profile,
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final SellerProfile? profile;

  @override
  State<OperationsSettingsScreen> createState() =>
      _OperationsSettingsScreenState();
}

class _OperationsSettingsScreenState extends State<OperationsSettingsScreen> {
  final _minimumOrderController = TextEditingController();
  final _prepTimeController = TextEditingController();

  SellerRestaurantProfile? _restaurant;
  double _deliveryRadius = 5;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRestaurant());
  }

  @override
  void dispose() {
    _minimumOrderController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurant() async {
    if (_loading) return;

    setState(() => _loading = true);
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
      setState(() => _applyRestaurant(restaurant));
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to load operations: $error', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyRestaurant(SellerRestaurantProfile restaurant) {
    _restaurant = restaurant;
    final minimumOrder = restaurant.minimumOrderAmount;
    if (minimumOrder != null) {
      _minimumOrderController.text = _formatNumber(minimumOrder);
    }
    final prepTime = restaurant.averagePreparationTime;
    if (prepTime != null) {
      _prepTimeController.text = prepTime.toString();
    }
    _deliveryRadius = restaurant.deliveryRadius ?? _deliveryRadius;
  }

  Future<void> _saveOperations() async {
    if (_saving || _loading) return;

    final restaurant = _restaurant;
    if (restaurant == null) {
      _showMessage('Restaurant details not loaded yet.', error: true);
      return;
    }

    final minimumOrder = double.tryParse(_minimumOrderController.text.trim());
    if (minimumOrder == null) {
      _showMessage('Enter a valid minimum order amount.', error: true);
      return;
    }

    final token = await widget.tokenStorage.loadToken();
    final tokenType = await widget.tokenStorage.loadTokenType();
    if (token == null || token.trim().isEmpty) {
      _showMessage('Authentication failed. Login again.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await widget.authApi.submitRestaurant(
        SellerRestaurantRequest(
          ownerFullName: widget.profile?.ownerFullName,
          email: widget.profile?.email,
          restaurantName: restaurant.restaurantName ?? '',
          restaurantPhone: restaurant.restaurantPhone ?? '',
          restaurantEmail: restaurant.restaurantEmail,
          restaurantAddress: restaurant.restaurantAddress ?? '',
          city: restaurant.city ?? '',
          latitude: restaurant.latitude,
          longitude: restaurant.longitude,
          cuisineType: restaurant.cuisineType,
          foodType: restaurant.foodType,
          minimumOrderAmount: minimumOrder,
          averagePreparationTime: int.tryParse(_prepTimeController.text.trim()),
          deliveryRadius: _deliveryRadius,
          openingHours: restaurant.openingHours,
          closingHours: restaurant.closingHours,
          coverImagePath: restaurant.coverImage,
          logoImagePath: restaurant.restaurantLogo,
        ),
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      _showMessage(
        result.message.isNotEmpty
            ? result.message
            : 'Operations updated successfully.',
      );
      Navigator.of(context).pop(true);
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } catch (error) {
      if (mounted) _showMessage('Unable to save operations: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
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

    return Scaffold(
      backgroundColor: palette.screen,
      body: LightAuthTextureBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  children: [
                    BackTextButton(onPressed: () => Navigator.maybePop(context)),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving || _loading ? null : _saveOperations,
                      child: _saving
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  palette.greenDark,
                                ),
                              ),
                            )
                          : Text(
                              'Save',
                              style: TextStyle(
                                color: palette.greenDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading && _restaurant == null
                    ? Center(
                        child: CircularProgressIndicator(color: palette.green),
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        children: [
                          Text(
                            'Operations',
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 26,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Control delivery limits and order preparation settings.',
                            style: TextStyle(
                              color: palette.mutedText,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SellerCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _OperationsLabel('MINIMUM ORDER', palette),
                                const SizedBox(height: 8),
                                _OperationsField(
                                  controller: _minimumOrderController,
                                  prefixText: '₹ ',
                                  keyboardType: TextInputType.number,
                                  hintText: '150',
                                ),
                                const SizedBox(height: 16),
                                _OperationsLabel('PREP TIME', palette),
                                const SizedBox(height: 8),
                                _OperationsField(
                                  controller: _prepTimeController,
                                  suffixText: ' min',
                                  keyboardType: TextInputType.number,
                                  hintText: '25',
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'DELIVERY RADIUS — ${_deliveryRadius.round()} KM',
                                  style: TextStyle(
                                    color: palette.mutedText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: palette.green,
                                    inactiveTrackColor: palette.fieldBorder,
                                    thumbColor: palette.green,
                                    overlayColor:
                                        palette.green.withValues(alpha: 0.14),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    value: _deliveryRadius,
                                    onChanged: (value) {
                                      setState(() => _deliveryRadius = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsLabel extends StatelessWidget {
  const _OperationsLabel(this.text, this.palette);

  final String text;
  final AuthPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: palette.mutedText,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _OperationsField extends StatelessWidget {
  const _OperationsField({
    required this.controller,
    this.prefixText,
    this.suffixText,
    this.keyboardType,
    this.hintText,
  });

  final TextEditingController controller;
  final String? prefixText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: palette.text,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        suffixText: suffixText,
        filled: true,
        fillColor: palette.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.fieldBorder, width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.green, width: 1.4),
        ),
      ),
    );
  }
}

String _formatNumber(num value) {
  final formatted = value.toStringAsFixed(2);
  return formatted.endsWith('.00')
      ? formatted.substring(0, formatted.length - 3)
      : formatted;
}
