import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final SellerProfile? profile;
  final VoidCallback? onLoggedOut;

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

      if (!mounted) return;
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
                _StoreInput(
                  label: 'RESTAURANT ADDRESS',
                  controller: _addressController,
                  prefixText: '📍  ',
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
                        : const Text(
                            'Done',
                            style: TextStyle(
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
