import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/app_theme.dart';
import '../data/profile_image_picker.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';
import '../widgets/auth_components.dart';
import 'complete_verification_screen.dart';

class StoreDetailsScreen extends StatefulWidget {
  const StoreDetailsScreen({
    required this.authApi,
    required this.tokenStorage,
    this.profile,
    this.onLoggedOut,
    this.fromSettings = false,
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final SellerProfile? profile;
  final VoidCallback? onLoggedOut;
  final bool fromSettings;

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  final _imagePicker = const ProfileImagePicker();

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

  List<SellerCuisine> _cuisines = const [];
  SellerCuisine? _selectedCuisine;
  String _foodType = 'both';
  double _deliveryRadius = 5;
  String? _coverImagePath;
  String? _logoImagePath;
  double? _selectedLat;
  double? _selectedLng;
  bool _submitting = false;
  bool _loadingRestaurant = false;
  bool _loadingCuisines = false;
  bool _pickingCoverImage = false;
  bool _pickingLogoImage = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    final restaurant = profile?.restaurant;

    _restaurantNameController = TextEditingController(
      text: restaurant?.restaurantName ?? '',
    );
    _phoneController = TextEditingController(
      text: restaurant?.restaurantPhone ?? '',
    );
    _emailController = TextEditingController(
      text: restaurant?.restaurantEmail ?? '',
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
    _coverImagePath = restaurant?.coverImage;
    _logoImagePath = restaurant?.restaurantLogo;
    _selectedLat = restaurant?.latitude;
    _selectedLng = restaurant?.longitude;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurant();
      _loadCuisines();
    });
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

  Future<void> _loadRestaurant() async {
    if (_loadingRestaurant) return;

    setState(() => _loadingRestaurant = true);
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
    } finally {
      if (mounted) setState(() => _loadingRestaurant = false);
    }
  }

  void _applyRestaurant(SellerRestaurantProfile restaurant) {
    _setText(_restaurantNameController, restaurant.restaurantName);
    _setText(_phoneController, restaurant.restaurantPhone);
    _setText(_emailController, restaurant.restaurantEmail);
    _setText(_addressController, restaurant.restaurantAddress);
    _setText(_cityController, restaurant.city);
    _setText(_cuisineController, restaurant.cuisineType);

    final minimumOrder = restaurant.minimumOrderAmount;
    if (minimumOrder != null) {
      _minimumOrderController.text = _formatStoreNumber(minimumOrder);
    }

    final prepTime = restaurant.averagePreparationTime;
    if (prepTime != null) {
      _prepTimeController.text = prepTime.toString();
    }

    _opensController.text = _formatStoreTime(
      _parseStoreTime(restaurant.openingHours ?? '') ?? _defaultOpenTime,
    );
    _closesController.text = _formatStoreTime(
      _parseStoreTime(restaurant.closingHours ?? '') ?? _defaultCloseTime,
    );

    _deliveryRadius = restaurant.deliveryRadius ?? _deliveryRadius;
    final foodType = restaurant.foodType?.trim().toLowerCase().replaceAll(
      '_',
      '-',
    );
    if (foodType == 'veg' || foodType == 'non-veg' || foodType == 'both') {
      _foodType = foodType!;
    }

    _coverImagePath = restaurant.coverImage ?? _coverImagePath;
    _logoImagePath = restaurant.restaurantLogo ?? _logoImagePath;
    _selectedLat = restaurant.latitude ?? _selectedLat;
    _selectedLng = restaurant.longitude ?? _selectedLng;
    _selectedCuisine = _findCuisineForText(_cuisineController.text);
  }

  void _setText(TextEditingController controller, String? value) {
    final text = value?.trim();
    if (text != null && text.isNotEmpty) {
      controller.text = text;
    }
  }

  Future<void> _loadCuisines() async {
    if (_loadingCuisines) return;

    setState(() => _loadingCuisines = true);
    try {
      final token = await widget.tokenStorage.loadToken();
      final tokenType = await widget.tokenStorage.loadTokenType();

      if (token == null || token.trim().isEmpty) {
        throw const SellerAuthException('Authentication failed. Login again.');
      }

      final cuisines = await widget.authApi.fetchCuisines(
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      setState(() {
        _cuisines = cuisines;
        _selectedCuisine = _findCuisineForText(_cuisineController.text);
        final selected = _selectedCuisine;
        if (selected != null) {
          _cuisineController.text = selected.translatedName;
        } else if (_cuisineController.text.trim().isEmpty &&
            cuisines.isNotEmpty) {
          _selectedCuisine = cuisines.first;
          _cuisineController.text = cuisines.first.translatedName;
        }
      });
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } finally {
      if (mounted) setState(() => _loadingCuisines = false);
    }
  }

  SellerCuisine? _findCuisineForText(String value) {
    final selectedText = value.trim().toLowerCase();
    if (selectedText.isEmpty) return null;

    for (final cuisine in _cuisines) {
      if (cuisine.translatedName.trim().toLowerCase() == selectedText) {
        return cuisine;
      }
    }

    return null;
  }

  Future<void> _openCuisinePicker() async {
    if (_loadingCuisines) return;

    if (_cuisines.isEmpty) {
      _showMessage('No cuisines available. Pulling latest list.');
      await _loadCuisines();
      if (!mounted || _cuisines.isEmpty) return;
    }

    final selected = await showModalBottomSheet<SellerCuisine>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) {
        return _CuisinePickerSheet(
          cuisines: _cuisines,
          selectedCuisine: _selectedCuisine,
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _selectedCuisine = selected;
      _cuisineController.text = selected.translatedName;
    });
  }

  Future<void> _pickStoreImage(_StoreImageSlot slot) async {
    final isCover = slot == _StoreImageSlot.cover;
    if (isCover ? _pickingCoverImage : _pickingLogoImage) return;

    final source = await showModalBottomSheet<PickedImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (context) => const _ImageSourcePickerSheet(),
    );
    if (source == null || !mounted) return;

    setState(() {
      if (isCover) {
        _pickingCoverImage = true;
      } else {
        _pickingLogoImage = true;
      }
    });

    try {
      final path = await _imagePicker.pickImage(source: source);
      if (path == null || !mounted) return;

      setState(() {
        if (isCover) {
          _coverImagePath = path;
        } else {
          _logoImagePath = path;
        }
      });
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(
          error.message ?? 'Unable to select image. Please try again.',
          error: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to select image. Please try again.', error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isCover) {
            _pickingCoverImage = false;
          } else {
            _pickingLogoImage = false;
          }
        });
      }
    }
  }

  Future<void> _openMapAddressPicker() async {
    final result = await Navigator.of(context).push<_StoreAddressResult>(
      MaterialPageRoute<_StoreAddressResult>(
        builder: (context) => _StoreAddressSelectionScreen(
          initialAddress: _addressController.text,
          initialCity: _cityController.text,
          initialLat: _selectedLat,
          initialLng: _selectedLng,
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _addressController.text = result.address;
      _cityController.text = result.city;
      _selectedLat = result.latitude;
      _selectedLng = result.longitude;
    });
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
    final cuisineType = _cuisineController.text.trim();
    final minimumOrder = double.tryParse(_minimumOrderController.text.trim());

    if (restaurantName.isEmpty ||
        restaurantPhone.isEmpty ||
        restaurantAddress.isEmpty ||
        city.isEmpty ||
        cuisineType.isEmpty ||
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
          latitude: _selectedLat,
          longitude: _selectedLng,
          cuisineType: cuisineType,
          foodType: _foodType,
          minimumOrderAmount: minimumOrder,
          averagePreparationTime: int.tryParse(_prepTimeController.text.trim()),
          deliveryRadius: _deliveryRadius,
          openingHours: _formatApiStoreTime(
            _parseStoreTime(_opensController.text) ?? _defaultOpenTime,
          ),
          closingHours: _formatApiStoreTime(
            _parseStoreTime(_closesController.text) ?? _defaultCloseTime,
          ),
          coverImagePath: _coverImagePath,
          logoImagePath: _logoImagePath,
        ),
        token: token,
        tokenType: tokenType,
      );

      await _saveSubmittedRestaurantStatus(result);

      if (!mounted) return;
      if (widget.fromSettings) {
        _showMessage(result.message.isNotEmpty
            ? result.message
            : 'Store details updated successfully.');
        Navigator.of(context).pop(true);
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => CompleteVerificationScreen(
            authApi: widget.authApi,
            tokenStorage: widget.tokenStorage,
            message: result.message,
            restaurantName: restaurantName,
            initials: _restaurantInitials(restaurantName),
            onLoggedOut: widget.onLoggedOut,
          ),
        ),
      );
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveSubmittedRestaurantStatus(SellerAuthResult result) async {
    final storedStatus = await widget.tokenStorage.loadAuthStatus();
    await widget.tokenStorage.saveAuthStatus(
      isNewSeller: storedStatus.isNewSeller ?? true,
      isEmailVerified: storedStatus.isEmailVerified ?? true,
      requiresRestaurantDetails: false,
      status: _stringFromRestaurantResult(result.data, 'status') ?? 'pending',
      verificationStatus:
      _stringFromRestaurantResult(result.data, 'verification_status') ??
          storedStatus.verificationStatus ??
          'approved',
    );
  }

  String? _stringFromRestaurantResult(
      Map<String, Object?>? data,
      String key,
      ) {
    Object? value = data?[key];
    if (value == null) {
      final seller = data?['seller'];
      if (seller is Map) value = seller[key];
    }
    if (value == null) {
      final restaurant = data?['restaurant'];
      if (restaurant is Map) value = restaurant[key];
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  Future<void> _pickOpeningTime() async {
    final current = _parseStoreTime(_opensController.text) ?? _defaultOpenTime;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) return;

    setState(() {
      _opensController.text = _formatStoreTime(picked);
      final closeTime =
          _parseStoreTime(_closesController.text) ?? _defaultCloseTime;
      if (!_isAfter(picked, closeTime)) {
        _closesController.text = _formatStoreTime(_nextValidCloseTime(picked));
      }
    });
  }

  Future<void> _pickClosingTime() async {
    final openTime = _parseStoreTime(_opensController.text) ?? _defaultOpenTime;
    final currentClose =
        _parseStoreTime(_closesController.text) ?? _defaultCloseTime;
    final initialTime = _isAfter(openTime, currentClose)
        ? currentClose
        : _nextValidCloseTime(openTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null || !mounted) return;

    if (!_isAfter(openTime, picked)) {
      _showMessage('Close time must be after opening time.', error: true);
      return;
    }

    setState(() => _closesController.text = _formatStoreTime(picked));
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 42,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: BackTextButton(
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Store Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your restaurant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
                _CoverImagePicker(
                  coverImagePath: _coverImagePath,
                  logoImagePath: _logoImagePath,
                  pickingCover: _pickingCoverImage,
                  pickingLogo: _pickingLogoImage,
                  onPickCover: () => _pickStoreImage(_StoreImageSlot.cover),
                  onPickLogo: () => _pickStoreImage(_StoreImageSlot.logo),
                ),
                const SizedBox(height: 40),
                _StoreInput(
                  label: 'RESTAURANT NAME',
                  controller: _restaurantNameController,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StoreInput(
                        label: 'PHONE',
                        controller: _phoneController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StoreInput(
                        label: 'EMAIL',
                        controller: _emailController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'RESTAURANT ADDRESS',
                  style: _labelStyle(palette),
                ),
                const SizedBox(height: 8),
                _StoreAddressPickerCard(
                  address: _addressController.text,
                  city: _cityController.text,
                  latitude: _selectedLat,
                  longitude: _selectedLng,
                  onTap: _openMapAddressPicker,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StoreInput(
                        label: 'CITY',
                        controller: _cityController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StoreInput(
                        label: 'CUISINE TYPE',
                        controller: _cuisineController,
                        readOnly: true,
                        onTap: _openCuisinePicker,
                        suffixIcon: _loadingCuisines
                            ? Icons.hourglass_empty_rounded
                            : Icons.keyboard_arrow_down_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('FOOD TYPE', style: _labelStyle(palette)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _FoodTypeChip(
                      label: 'Veg',
                      color: const Color(0xFF72B843),
                      selected: _foodType == 'veg',
                      onTap: () => setState(() => _foodType = 'veg'),
                    ),
                    const SizedBox(width: 8),
                    _FoodTypeChip(
                      label: 'Non-Veg',
                      color: const Color(0xFFFF4338),
                      selected: _foodType == 'non-veg',
                      onTap: () => setState(() => _foodType = 'non-veg'),
                    ),
                    const SizedBox(width: 8),
                    _FoodTypeChip(
                      label: 'Both',
                      color: const Color(0xFFFFC733),
                      selected: _foodType == 'both',
                      onTap: () => setState(() => _foodType = 'both'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
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
                    const SizedBox(width: 12),
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
                const SizedBox(height: 18),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StoreInput(
                        label: 'OPENS',
                        controller: _opensController,
                        readOnly: true,
                        onTap: _pickOpeningTime,
                        suffixIcon: Icons.access_time_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StoreInput(
                        label: 'CLOSES',
                        controller: _closesController,
                        readOnly: true,
                        onTap: _pickClosingTime,
                        suffixIcon: Icons.access_time_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _submitting || _loadingRestaurant
                        ? null
                        : _submitRestaurant,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting || _loadingRestaurant
                        ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : Text(
                      widget.fromSettings ? 'Save' : 'Done',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle _labelStyle(AuthPalette palette) {
    return TextStyle(
      color: palette.mutedText,
      fontSize: 11,
      height: 1,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    );
  }
}

enum _StoreImageSlot { cover, logo }

String _formatCoordinate(double value) => value.toStringAsFixed(5);

class _StoreAddressResult {
  const _StoreAddressResult({
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
  });

  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
}

class _ResolvedStoreAddress {
  const _ResolvedStoreAddress({
    required this.address,
    required this.city,
    required this.landmark,
  });

  final String address;
  final String city;
  final String landmark;
}

class _StoreAddressPickerCard extends StatelessWidget {
  const _StoreAddressPickerCard({
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final hasAddress = address.trim().isNotEmpty;
    final hasCoordinates = latitude != null && longitude != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: palette.fieldFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.fieldBorder, width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.softGreen.withValues(alpha: 0.74),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: palette.greenDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAddress ? address.trim() : 'Select restaurant address',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasAddress ? palette.text : palette.mutedText,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: hasAddress
                            ? FontWeight.w500
                            : FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasCoordinates
                          ? '${_formatCoordinate(latitude!)}, ${_formatCoordinate(longitude!)}'
                          : city.trim().isEmpty
                          ? 'City and location pin'
                          : city.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasCoordinates
                            ? palette.greenDark
                            : palette.mutedText,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

class _StoreAddressSelectionScreen extends StatefulWidget {
  const _StoreAddressSelectionScreen({
    required this.initialAddress,
    required this.initialCity,
    required this.initialLat,
    required this.initialLng,
  });

  final String initialAddress;
  final String initialCity;
  final double? initialLat;
  final double? initialLng;

  @override
  State<_StoreAddressSelectionScreen> createState() =>
      _StoreAddressSelectionScreenState();
}

class _StoreAddressSelectionScreenState
    extends State<_StoreAddressSelectionScreen> {
  static const LatLng _defaultMapCenter = LatLng(28.6139, 77.2090);
  static const String _mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );
  static const String _mapboxStylePath = String.fromEnvironment(
    'MAPBOX_STYLE_PATH',
    defaultValue: 'mapbox/streets-v12',
  );

  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _landmarkController;
  late final MapController _mapController;
  double? _selectedLat;
  double? _selectedLng;
  bool _locating = false;
  bool _resolvingAddress = false;
  int _addressLookupSerial = 0;

  LatLng get _mapCenter => LatLng(
    _selectedLat ?? _defaultMapCenter.latitude,
    _selectedLng ?? _defaultMapCenter.longitude,
  );

  String get _tileUrlTemplate {
    if (_mapboxAccessToken.isEmpty) {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }

    final stylePath = _mapboxStylePath.replaceFirst(RegExp(r'^/+'), '');
    return 'https://api.mapbox.com/styles/v1/$stylePath/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxAccessToken';
  }

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
    _cityController = TextEditingController(text: widget.initialCity);
    _landmarkController = TextEditingController();
    _mapController = MapController();
    _selectedLat = widget.initialLat;
    _selectedLng = widget.initialLng;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _landmarkController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _setPinnedLocation(
      double latitude,
      double longitude, {
        bool move = false,
      }) {
    setState(() {
      _selectedLat = latitude;
      _selectedLng = longitude;
    });

    if (move) {
      _mapController.move(LatLng(latitude, longitude), 15);
    }
  }

  Future<void> _pinAndResolveLocation(
      double latitude,
      double longitude, {
        bool move = false,
        bool showSuccess = false,
      }) async {
    _setPinnedLocation(latitude, longitude, move: move);
    await _resolveAddressForLocation(
      latitude,
      longitude,
      showSuccess: showSuccess,
    );
  }

  Future<void> _resolveAddressForLocation(
      double latitude,
      double longitude, {
        bool showSuccess = false,
      }) async {
    final lookupId = ++_addressLookupSerial;
    setState(() => _resolvingAddress = true);

    try {
      final resolved = _mapboxAccessToken.isEmpty
          ? await _fetchOsmResolvedAddress(latitude, longitude)
          : await _fetchMapboxResolvedAddress(latitude, longitude);

      if (!mounted || lookupId != _addressLookupSerial) return;

      if (resolved == null) {
        _showMessage('Location pinned. Enter address manually.');
        return;
      }

      _applyResolvedAddress(resolved);
      if (showSuccess) {
        _showMessage('Current location and address filled.');
      }
    } catch (_) {
      if (mounted && lookupId == _addressLookupSerial) {
        _showMessage('Location pinned. Unable to fetch address.');
      }
    } finally {
      if (mounted && lookupId == _addressLookupSerial) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  void _applyResolvedAddress(_ResolvedStoreAddress resolved) {
    setState(() {
      if (resolved.city.isNotEmpty) {
        _cityController.text = resolved.city;
      }
      if (resolved.address.isNotEmpty) {
        _addressController.text = resolved.address;
      }
      _landmarkController.text = resolved.landmark;
    });
  }

  Future<_ResolvedStoreAddress?> _fetchMapboxResolvedAddress(
      double latitude,
      double longitude,
      ) async {
    final uri = Uri.https('api.mapbox.com', '/search/geocode/v6/reverse', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'access_token': _mapboxAccessToken,
    });
    final data = await _readJsonObject(uri);
    final features = data?['features'];
    if (features is! List || features.isEmpty) return null;

    for (final item in features) {
      final feature = _asJsonObject(item);
      final properties = _asJsonObject(feature?['properties']);
      if (properties == null) continue;

      final context = _asJsonObject(properties['context']);
      final placeFormatted = _stringValue(properties['place_formatted']);
      final name = _stringValue(properties['name']);
      final fullAddress = _firstNonEmpty([
        _stringValue(properties['full_address']),
        _joinAddressParts([name, placeFormatted]),
        _stringValue(properties['address']),
      ]);
      final city = _firstNonEmpty([
        _contextName(context, 'place'),
        _contextName(context, 'locality'),
        _contextName(context, 'district'),
        _contextName(context, 'region'),
      ]);
      final landmark = _firstNonEmpty([
        if (name != city) name,
        _contextName(context, 'neighborhood'),
        _contextName(context, 'street'),
      ]);

      if (fullAddress.isNotEmpty || city.isNotEmpty) {
        return _ResolvedStoreAddress(
          address: fullAddress,
          city: city,
          landmark: landmark,
        );
      }
    }

    return null;
  }

  Future<_ResolvedStoreAddress?> _fetchOsmResolvedAddress(
      double latitude,
      double longitude,
      ) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'addressdetails': '1',
    });
    final data = await _readJsonObject(uri);
    if (data == null) return null;

    final address = _asJsonObject(data['address']) ?? const {};
    final city = _firstNonEmpty([
      _stringValue(address['city']),
      _stringValue(address['town']),
      _stringValue(address['village']),
      _stringValue(address['municipality']),
      _stringValue(address['county']),
      _stringValue(address['state_district']),
      _stringValue(address['state']),
    ]);
    final landmark = _firstNonEmpty([
      _stringValue(address['amenity']),
      _stringValue(address['shop']),
      _stringValue(address['tourism']),
      _stringValue(address['building']),
      _stringValue(address['neighbourhood']),
      _stringValue(address['suburb']),
      _stringValue(address['road']),
    ]);
    final displayAddress = _firstNonEmpty([
      _stringValue(data['display_name']),
      _joinAddressParts([
        landmark,
        _stringValue(address['road']),
        _stringValue(address['suburb']),
        city,
        _stringValue(address['postcode']),
      ]),
    ]);

    if (displayAddress.isEmpty && city.isEmpty) return null;

    return _ResolvedStoreAddress(
      address: displayAddress,
      city: city,
      landmark: landmark,
    );
  }

  Future<Map<String, dynamic>?> _readJsonObject(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'qadam_food_seller/1.0');

      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final body = await utf8.decodeStream(response).timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(body);
      return _asJsonObject(decoded);
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic>? _asJsonObject(Object? value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  String _contextName(Map<String, dynamic>? context, String key) {
    final contextValue = _asJsonObject(context?[key]);
    return _stringValue(contextValue?['name']);
  }

  String _joinAddressParts(List<String> parts) {
    return parts.where((part) => part.trim().isNotEmpty).join(', ');
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  String _stringValue(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;

    setState(() => _locating = true);
    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final openSettings = await _showLocationActionDialog(
          title: 'Turn on device location',
          message:
          'Location permission is allowed, but device location is turned off. Turn it on to pin your restaurant.',
          primaryLabel: 'Open Settings',
        );
        if (openSettings == true) {
          await Geolocator.openLocationSettings();
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      await _pinAndResolveLocation(
        position.latitude,
        position.longitude,
        move: true,
        showSuccess: true,
      );
    } catch (_) {
      if (mounted) _showMessage('Unable to fetch current location.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (_hasLocationPermission(permission)) return true;

    if (permission == LocationPermission.denied) {
      final shouldRequest = await _showLocationActionDialog(
        title: 'Allow location access',
        message:
        'We need location permission to pin your restaurant coordinates for delivery.',
        primaryLabel: 'Allow',
      );
      if (shouldRequest != true) return false;

      permission = await Geolocator.requestPermission();
      if (_hasLocationPermission(permission)) return true;
    }

    if (permission == LocationPermission.deniedForever) {
      final openSettings = await _showLocationActionDialog(
        title: 'Location permission blocked',
        message:
        'Location permission is blocked for this app. Open app settings and allow location access.',
        primaryLabel: 'App Settings',
      );
      if (openSettings == true) {
        await Geolocator.openAppSettings();
      }
      return false;
    }

    _showMessage('Location permission was not granted.');
    return false;
  }

  bool _hasLocationPermission(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool?> _showLocationActionDialog({
    required String title,
    required String message,
    required String primaryLabel,
  }) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.screen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          content: Text(
            message,
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
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmSelection() {
    final city = _cityController.text.trim();
    final address = _addressController.text.trim();
    final landmark = _landmarkController.text.trim();

    if (city.isEmpty) {
      _showMessage('Enter city');
      return;
    }

    if (address.isEmpty) {
      _showMessage('Enter restaurant address');
      return;
    }

    final fullAddress = landmark.isEmpty ? address : '$address, $landmark';
    Navigator.pop(
      context,
      _StoreAddressResult(
        address: fullAddress,
        city: city,
        latitude: _selectedLat,
        longitude: _selectedLng,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildOpenMapPicker(AuthPalette palette) {
    final hasCoordinates = _selectedLat != null && _selectedLng != null;
    final instructionText = _resolvingAddress
        ? 'Finding address...'
        : hasCoordinates
        ? 'Tap map to move pin'
        : 'Tap map to pin';
    final coordinateText = _resolvingAddress
        ? 'Fetching city and address'
        : hasCoordinates
        ? '${_formatCoordinate(_selectedLat!)}, ${_formatCoordinate(_selectedLng!)}'
        : 'No pin selected';
    final coordinateIcon = hasCoordinates
        ? Icons.check_circle_rounded
        : Icons.location_searching_rounded;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: palette.fieldFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasCoordinates ? palette.green : palette.fieldBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.greenDark.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: hasCoordinates ? 15 : 4,
              minZoom: 3,
              maxZoom: 18,
              backgroundColor: palette.softGreen.withValues(alpha: 0.35),
              onTap: (_, point) async {
                await _pinAndResolveLocation(point.latitude, point.longitude);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrlTemplate,
                userAgentPackageName: 'qadam_food_seller',
              ),
              if (hasCoordinates)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _mapCenter,
                      width: 52,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: palette.greenDark.withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_pin,
                          color: palette.greenDark,
                          size: 38,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _MapStatusChip(
              icon: Icons.touch_app_rounded,
              text: instructionText,
              palette: palette,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: _MapStatusChip(
              icon: coordinateIcon,
              text: coordinateText,
              palette: palette,
              isActive: hasCoordinates,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final hasCoordinates = _selectedLat != null && _selectedLng != null;
    final currentLocationTitle = _locating
        ? 'Fetching current location'
        : _resolvingAddress
        ? 'Finding address'
        : hasCoordinates
        ? 'Location pinned'
        : 'Use current location';
    final currentLocationSubtitle = _resolvingAddress
        ? 'City, address, and landmark will fill automatically.'
        : hasCoordinates
        ? '${_formatCoordinate(_selectedLat!)}, ${_formatCoordinate(_selectedLng!)}'
        : 'Adds latitude and longitude for delivery.';

    return Scaffold(
      backgroundColor: palette.screen,
      body: LightAuthTextureBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    BackTextButton(onPressed: () => Navigator.pop(context)),
                    const Spacer(),
                    TextButton(
                      onPressed: _confirmSelection,
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: palette.greenDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Pin Your Location',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap the map to place your restaurant pin',
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                _buildOpenMapPicker(palette),
                const SizedBox(height: 20),
                _StoreInput(
                  label: 'CITY',
                  controller: _cityController,
                  prefixText: '  ',
                ),
                const SizedBox(height: 16),
                _StoreInput(
                  label: 'ADDRESS',
                  controller: _addressController,
                  prefixText: '  ',
                ),
                const SizedBox(height: 16),
                _StoreInput(
                  label: 'LANDMARK OPTIONAL',
                  controller: _landmarkController,
                  prefixText: '  ',
                ),
                const SizedBox(height: 18),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _locating ? null : _useCurrentLocation,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasCoordinates
                              ? palette.green
                              : palette.fieldBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.softGreen.withValues(alpha: 0.74),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _locating || _resolvingAddress
                                ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  palette.greenDark,
                                ),
                              ),
                            )
                                : Icon(
                              Icons.my_location_rounded,
                              color: palette.greenDark,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentLocationTitle,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  currentLocationSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasCoordinates
                                        ? palette.greenDark
                                        : palette.mutedText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: palette.mutedText,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapStatusChip extends StatelessWidget {
  const _MapStatusChip({
    required this.icon,
    required this.text,
    required this.palette,
    this.isActive = false,
  });

  final IconData icon;
  final String text;
  final AuthPalette palette;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? palette.greenDark : palette.text;

    return Container(
      constraints: const BoxConstraints(maxWidth: 218),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.screen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImagePicker extends StatelessWidget {
  const _CoverImagePicker({
    required this.coverImagePath,
    required this.logoImagePath,
    required this.pickingCover,
    required this.pickingLogo,
    required this.onPickCover,
    required this.onPickLogo,
  });

  final String? coverImagePath;
  final String? logoImagePath;
  final bool pickingCover;
  final bool pickingLogo;
  final VoidCallback onPickCover;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: pickingCover ? null : onPickCover,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 104,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: palette.fieldFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.fieldBorder, width: 1.2),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverImagePath == null)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.crop_original_rounded,
                            color: palette.mutedText,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Cover image',
                            style: TextStyle(
                              color: palette.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _StoreImagePreview(
                      path: coverImagePath!,
                      fit: BoxFit.cover,
                      errorIcon: Icons.broken_image_rounded,
                    ),
                  if (pickingCover)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: _CameraBadge(
                      palette: palette,
                      loading: pickingCover,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          bottom: -24,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: pickingLogo ? null : onPickLogo,
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: palette.screen,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: palette.green, width: 1.4),
                    ),
                    child: logoImagePath == null
                        ? const Text('🏪', style: TextStyle(fontSize: 21))
                        : _StoreImagePreview(
                      path: logoImagePath!,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorIcon: Icons.storefront_rounded,
                    ),
                  ),
                  Positioned(
                    right: -7,
                    bottom: -7,
                    child: _CameraBadge(
                      palette: palette,
                      loading: pickingLogo,
                      size: 24,
                      iconSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreImagePreview extends StatelessWidget {
  const _StoreImagePreview({
    required this.path,
    required this.fit,
    required this.errorIcon,
    this.width,
    this.height,
  });

  final String path;
  final BoxFit fit;
  final IconData errorIcon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');

    Widget errorBuilder(
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
        ) {
      return Center(
        child: Icon(errorIcon, color: palette.mutedText, size: 28),
      );
    }

    if (isNetwork) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    return Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({
    required this.palette,
    required this.loading,
    required this.size,
    this.iconSize = 16,
  });

  final AuthPalette palette;
  final bool loading;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: palette.green.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: loading
          ? SizedBox.square(
        dimension: iconSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Icon(
        Icons.photo_camera_rounded,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}

class _ImageSourcePickerSheet extends StatelessWidget {
  const _ImageSourcePickerSheet();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: palette.screen,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.fieldBorder, width: 1.1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose image',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.mutedText,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _ImageSourceOptionTile(
                icon: Icons.photo_camera_rounded,
                title: 'Camera',
                subtitle: 'Capture a new photo',
                onTap: () => Navigator.pop(context, PickedImageSource.camera),
              ),
              const SizedBox(height: 8),
              _ImageSourceOptionTile(
                icon: Icons.photo_library_rounded,
                title: 'Gallery',
                subtitle: 'Pick from photos',
                onTap: () => Navigator.pop(context, PickedImageSource.gallery),
              ),
              const SizedBox(height: 8),
              _ImageSourceOptionTile(
                icon: Icons.folder_open_rounded,
                title: 'File',
                subtitle: 'Browse image files',
                onTap: () => Navigator.pop(context, PickedImageSource.file),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSourceOptionTile extends StatelessWidget {
  const _ImageSourceOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Material(
      color: palette.fieldFill,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.softGreen.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: palette.greenDark, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: palette.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? prefixText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _StoreDetailsScreenState._labelStyle(palette)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            color: palette.text,
            fontSize: 14,
            height: 1.25,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            prefixText: prefixText,
            suffixText: suffixText,
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, color: palette.greenDark, size: 18),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 34,
              minHeight: 34,
            ),
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
        ),
      ],
    );
  }
}

class _CuisinePickerSheet extends StatelessWidget {
  const _CuisinePickerSheet({
    required this.cuisines,
    required this.selectedCuisine,
  });

  final List<SellerCuisine> cuisines;
  final SellerCuisine? selectedCuisine;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        decoration: BoxDecoration(
          color: palette.screen,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.fieldBorder, width: 1.1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cuisine Type',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.mutedText,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                itemCount: cuisines.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final cuisine = cuisines[index];
                  final selected =
                      cuisine.id == selectedCuisine?.id ||
                          cuisine.translatedName == selectedCuisine?.translatedName;

                  return Material(
                    color: selected
                        ? palette.softGreen.withValues(alpha: 0.72)
                        : palette.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, cuisine),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cuisine.translatedName,
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_rounded,
                                color: palette.greenDark,
                                size: 19,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
        color: selected ? palette.greenDark : palette.fieldFill,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 36,
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
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : palette.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

const _defaultOpenTime = TimeOfDay(hour: 9, minute: 0);
const _defaultCloseTime = TimeOfDay(hour: 23, minute: 0);

TimeOfDay? _parseStoreTime(String value) {
  final text = value.trim();
  final twentyFourHourMatch = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
  if (twentyFourHourMatch != null) {
    final hour = int.tryParse(twentyFourHourMatch.group(1)!);
    final minute = int.tryParse(twentyFourHourMatch.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return null;

  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  final period = match.group(3)!.toUpperCase();
  if (hour == null || minute == null) return null;
  if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;

  final normalizedHour = switch (period) {
    'AM' => hour == 12 ? 0 : hour,
    'PM' => hour == 12 ? 12 : hour + 12,
    _ => hour,
  };

  return TimeOfDay(hour: normalizedHour, minute: minute);
}

String _formatStoreTime(TimeOfDay time) {
  final period = time.hour >= 12 ? 'PM' : 'AM';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
}

String _formatApiStoreTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

String _formatStoreNumber(num value) {
  final formatted = value.toStringAsFixed(2);
  return formatted.endsWith('.00')
      ? formatted.substring(0, formatted.length - 3)
      : formatted;
}

bool _isAfter(TimeOfDay start, TimeOfDay end) {
  return _minutesOfDay(end) > _minutesOfDay(start);
}

TimeOfDay _nextValidCloseTime(TimeOfDay openTime) {
  final nextMinutes = (_minutesOfDay(openTime) + 60).clamp(0, 23 * 60 + 59);
  return TimeOfDay(hour: nextMinutes ~/ 60, minute: nextMinutes % 60);
}

int _minutesOfDay(TimeOfDay time) => time.hour * 60 + time.minute;

String _restaurantInitials(String restaurantName) {
  final words = restaurantName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return 'RK';
  return words.take(2).map((word) => word[0]).join().toUpperCase();
}
