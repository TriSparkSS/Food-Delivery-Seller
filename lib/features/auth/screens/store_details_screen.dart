import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../theme/app_theme.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';
import '../widgets/auth_components.dart';

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
  final _imagePicker = ImagePicker();

  XFile? _restaurantLogoImage;
  XFile? _coverImage;
  double? _latitude;
  double? _longitude;
  String _foodType = 'both';
  double _deliveryRadius = 5;
  bool _submitting = false;
  bool _fetchingLocation = false;

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
    _latitude = restaurant?.latitude;
    _longitude = restaurant?.longitude;
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
          latitude: _latitude,
          longitude: _longitude,
          cuisineType: _cuisineController.text.trim(),
          foodType: _foodType,
          minimumOrderAmount: minimumOrder,
          averagePreparationTime: int.tryParse(_prepTimeController.text.trim()),
          deliveryRadius: _deliveryRadius,
          openingHours: _opensController.text.trim(),
          closingHours: _closesController.text.trim(),
          restaurantLogoPath: _restaurantLogoImage?.path,
          coverImagePath: _coverImage?.path,
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

  Future<void> _showImageSourceSheet({
    required String title,
    required ValueChanged<XFile> onImagePicked,
  }) async {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.screen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.fieldBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                _ImageSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, onImagePicked);
                  },
                ),
                const SizedBox(height: 10),
                _ImageSourceTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Take Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, onImagePicked);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    ValueChanged<XFile> onImagePicked,
  ) async {
    try {
      final hasPermission = await _ensureImagePermission(source);
      if (!hasPermission) return;

      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1400,
      );
      if (image == null || !mounted) return;
      setState(() => onImagePicked(image));
    } on MissingPluginException {
      if (mounted) {
        _showMessage(
          'Please rebuild the app after adding image picker.',
          error: true,
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Unable to pick image.', error: true);
      }
    } catch (_) {
      if (mounted) _showMessage('Unable to pick image.', error: true);
    }
  }

  Future<bool> _ensureImagePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      return _requestPermission(
        Permission.camera,
        deniedMessage: 'Camera permission is required.',
      );
    }

    if (Platform.isIOS) {
      return _requestPermission(
        Permission.photos,
        deniedMessage: 'Photo library permission is required.',
      );
    }

    final photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted || photosStatus.isLimited) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted || storageStatus.isLimited) return true;

    if (photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      _showMessage(
        'Gallery permission is denied. Enable it from settings.',
        error: true,
      );
      await openAppSettings();
      return false;
    }

    _showMessage('Gallery permission is required.', error: true);
    return false;
  }

  Future<bool> _requestPermission(
    Permission permission, {
    required String deniedMessage,
  }) async {
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showMessage('$deniedMessage Enable it from settings.', error: true);
      await openAppSettings();
      return false;
    }

    _showMessage(deniedMessage, error: true);
    return false;
  }

  Future<void> _fetchCurrentLocation() async {
    if (_fetchingLocation) return;

    setState(() => _fetchingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Please enable location services.', error: true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission is required.', error: true);
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. Enable it from settings.',
          error: true,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Unable to fetch location.', error: true);
      }
    } catch (_) {
      if (mounted) _showMessage('Unable to fetch location.', error: true);
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.screen,
          image: const DecorationImage(
            image: AssetImage(LightAuthTextureBackground.assetPath),
            fit: BoxFit.cover,
          ),
        ),
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
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 20),
                _CoverImagePicker(
                  logoImagePath: _restaurantLogoImage?.path,
                  coverImagePath: _coverImage?.path,
                  onLogoTap: () => _showImageSourceSheet(
                    title: 'Restaurant Logo',
                    onImagePicked: (image) => _restaurantLogoImage = image,
                  ),
                  onCoverTap: () => _showImageSourceSheet(
                    title: 'Cover Image',
                    onImagePicked: (image) => _coverImage = image,
                  ),
                ),
                const SizedBox(height: 24),
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
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 14),
                _LocationMapPreview(
                  latitude: _latitude,
                  longitude: _longitude,
                  fetching: _fetchingLocation,
                  onTap: _fetchCurrentLocation,
                ),
                const SizedBox(height: 18),
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
                  'DELIVERY RADIUS - ${_deliveryRadius.round()} KM',
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StoreInput(
                        label: 'OPENS',
                        controller: _opensController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StoreInput(
                        label: 'CLOSES',
                        controller: _closesController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submitRestaurant,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Complete Registration',
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
      fontSize: 14,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.3,
    );
  }
}

class _CoverImagePicker extends StatelessWidget {
  const _CoverImagePicker({
    required this.logoImagePath,
    required this.coverImagePath,
    required this.onLogoTap,
    required this.onCoverTap,
  });

  final String? logoImagePath;
  final String? coverImagePath;
  final VoidCallback onLogoTap;
  final VoidCallback onCoverTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final logoPath = logoImagePath;
    final coverPath = coverImagePath;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onCoverTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 112,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.fieldFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.fieldBorder, width: 1.4),
            ),
            child: coverPath == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.crop_original_rounded,
                        color: palette.mutedText,
                        size: 30,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Cover image',
                        style: TextStyle(
                          color: palette.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(coverPath), fit: BoxFit.cover),
                      Container(
                        color: Colors.black.withValues(alpha: 0.16),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        Positioned(
          left: 22,
          bottom: -22,
          child: InkWell(
            onTap: onLogoTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 58,
              height: 58,
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.screen,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.fieldBorder, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: palette.text.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: logoPath == null
                  ? Icon(
                      Icons.storefront_rounded,
                      color: palette.greenDark,
                      size: 26,
                    )
                  : Image.file(
                      File(logoPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
          ),
        ),
        Positioned(
          left: 60,
          bottom: -24,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: palette.green,
              shape: BoxShape.circle,
              border: Border.all(color: palette.screen, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationMapPreview extends StatelessWidget {
  const _LocationMapPreview({
    required this.latitude,
    required this.longitude,
    required this.fetching,
    required this.onTap,
  });

  final double? latitude;
  final double? longitude;
  final bool fetching;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final hasLocation = latitude != null && longitude != null;

    return InkWell(
      onTap: fetching ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 124,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111A27),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.16,
                child: CustomPaint(painter: _MapGridPainter()),
              ),
            ),
            Center(
              child: fetching
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: palette.green,
                          size: 42,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasLocation
                              ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                              : 'Tap to use current location',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x + 36, size.height), paint);
    }

    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 18), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: palette.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.fieldBorder, width: 1.1),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.greenDark, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
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
    this.prefixIcon,
    this.suffixText,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? prefixText;
  final IconData? prefixIcon;
  final String? suffixText;
  final TextInputType? keyboardType;

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
          style: TextStyle(
            color: palette.text,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: palette.greenDark, size: 19),
            suffixText: suffixText,
            filled: true,
            fillColor: palette.fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.fieldBorder, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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
                    width: 14,
                    height: 14,
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
                      fontSize: 13,
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
