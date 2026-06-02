import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';

class StoreDetailsScreen extends StatefulWidget {
  const StoreDetailsScreen({
    required this.authApi,
    required this.tokenStorage,
    this.profile,
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final SellerProfile? profile;

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  late final TextEditingController _restaurantNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _cuisineController;
  late final TextEditingController _minimumOrderController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _opensController;
  late final TextEditingController _closesController;

  String _foodType = 'both';
  double _deliveryRadius = 5;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    final restaurant = profile?.restaurant;

    _restaurantNameController = TextEditingController(
      text: restaurant?.restaurantName ?? 'Spice Garden',
    );
    _phoneController = TextEditingController(
      text: restaurant?.restaurantPhone ?? profile?.phoneNumber ?? '',
    );
    _emailController = TextEditingController(
      text: restaurant?.restaurantEmail ?? profile?.email ?? '',
    );
    _addressController = TextEditingController(
      text: restaurant?.restaurantAddress ?? '',
    );
    _cityController = TextEditingController(text: restaurant?.city ?? '');
    _cuisineController = TextEditingController(
      text: restaurant?.cuisineType ?? 'Indian',
    );
    _minimumOrderController = TextEditingController(
      text: (restaurant?.minimumOrderAmount ?? 150).toString(),
    );
    _prepTimeController = TextEditingController(
      text: (restaurant?.averagePreparationTime ?? 25).toString(),
    );
    _opensController = TextEditingController(
      text: restaurant?.openingHours ?? '09:00 AM',
    );
    _closesController = TextEditingController(
      text: restaurant?.closingHours ?? '11:00 PM',
    );
    _deliveryRadius = restaurant?.deliveryRadius ?? 5;
    _foodType = restaurant?.foodType ?? 'both';
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _cuisineController.dispose();
    _minimumOrderController.dispose();
    _prepTimeController.dispose();
    _opensController.dispose();
    _closesController.dispose();
    super.dispose();
  }

  Future<void> _submitRestaurant() async {
    if (_submitting) return;

    final token = await widget.tokenStorage.loadToken();
    final tokenType = await widget.tokenStorage.loadTokenType();

    if (token == null || token.trim().isEmpty) {
      _showMessage('Authentication failed. Login again.', error: true);
      return;
    }

    final restaurantName = _restaurantNameController.text.trim();
    final restaurantPhone = _phoneController.text.trim();
    final restaurantAddress = _addressController.text.trim();
    final city = _cityController.text.trim();
    final minimumOrder = double.tryParse(_minimumOrderController.text.trim());

    if (restaurantName.isEmpty ||
        restaurantPhone.isEmpty ||
        restaurantAddress.isEmpty ||
        city.isEmpty ||
        minimumOrder == null) {
      _showMessage('Please fill all required restaurant fields.', error: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await widget.authApi.submitRestaurant(
        SellerRestaurantRequest(
          ownerFullName: widget.profile?.ownerFullName,
          email: widget.profile?.email,
          restaurantName: restaurantName,
          restaurantPhone: restaurantPhone,
          restaurantEmail: _emailController.text.trim(),
          restaurantAddress: restaurantAddress,
          city: city,
          cuisineType: _cuisineController.text.trim(),
          foodType: _foodType,
          minimumOrderAmount: minimumOrder,
          averagePreparationTime: int.tryParse(_prepTimeController.text.trim()),
          deliveryRadius: _deliveryRadius,
          openingHours: _opensController.text.trim(),
          closingHours: _closesController.text.trim(),
        ),
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      _showMessage(result.message);
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.mutedText,
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Store Details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about your restaurant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.mutedText,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              const _CoverImagePicker(),
              const SizedBox(height: 24),
              _StoreInput(
                label: 'RESTAURANT NAME',
                controller: _restaurantNameController,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StoreInput(label: 'PHONE', controller: _phoneController),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StoreInput(label: 'EMAIL', controller: _emailController),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _StoreInput(
                label: 'RESTAURANT ADDRESS',
                controller: _addressController,
                prefixText: '📍  ',
              ),
              const SizedBox(height: 18),
              Container(
                height: 142,
                decoration: BoxDecoration(
                  color: const Color(0xFF111A27),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: palette.green,
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _StoreInput(label: 'CITY', controller: _cityController),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StoreInput(
                      label: 'CUISINE TYPE',
                      controller: _cuisineController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('FOOD TYPE', style: _labelStyle(palette)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _FoodTypeChip(
                    label: 'Veg',
                    color: const Color(0xFF72B843),
                    selected: _foodType == 'veg',
                    onTap: () => setState(() => _foodType = 'veg'),
                  ),
                  const SizedBox(width: 10),
                  _FoodTypeChip(
                    label: 'Non-Veg',
                    color: const Color(0xFFFF4338),
                    selected: _foodType == 'non-veg',
                    onTap: () => setState(() => _foodType = 'non-veg'),
                  ),
                  const SizedBox(width: 10),
                  _FoodTypeChip(
                    label: 'Both',
                    color: const Color(0xFFFFC733),
                    selected: _foodType == 'both',
                    onTap: () => setState(() => _foodType = 'both'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StoreInput(
                      label: 'MIN. ORDER',
                      controller: _minimumOrderController,
                      prefixText: '₹',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StoreInput(
                      label: 'PREP TIME',
                      controller: _prepTimeController,
                      suffixText: ' min',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'DELIVERY RADIUS — ${_deliveryRadius.round()} KM',
                style: _labelStyle(palette),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: palette.green,
                  inactiveTrackColor: palette.fieldBorder,
                  thumbColor: palette.green,
                  overlayColor: palette.green.withValues(alpha: 0.14),
                  trackHeight: 5,
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StoreInput(label: 'OPENS', controller: _opensController),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StoreInput(label: 'CLOSES', controller: _closesController),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 64,
                child: FilledButton(
                  onPressed: _submitting ? null : _submitRestaurant,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Complete Registration 🎉',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TextStyle _labelStyle(AuthPalette palette) {
    return TextStyle(
      color: palette.mutedText,
      fontSize: 14,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.3,
    );
  }
}

class _CoverImagePicker extends StatelessWidget {
  const _CoverImagePicker();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 124,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.fieldBorder, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.crop_original_rounded, color: palette.mutedText, size: 34),
              const SizedBox(height: 8),
              Text(
                'Cover image',
                style: TextStyle(
                  color: palette.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 26,
          bottom: -24,
          child: Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.screen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.fieldBorder, width: 2),
            ),
            child: const Text('🏪', style: TextStyle(fontSize: 24)),
          ),
        ),
      ],
    );
  }
}

class _StoreInput extends StatelessWidget {
  const _StoreInput({
    required this.label,
    required this.controller,
    this.prefixText,
    this.suffixText,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? prefixText;
  final String? suffixText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _StoreDetailsScreenState._labelStyle(palette)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: palette.text,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            prefixText: prefixText,
            suffixText: suffixText,
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.fieldBorder, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodTypeChip extends StatelessWidget {
  const _FoodTypeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Expanded(
      child: Material(
        color: selected ? palette.greenDark : Colors.white,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? palette.greenDark : palette.fieldBorder,
                width: 1.2,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : palette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
