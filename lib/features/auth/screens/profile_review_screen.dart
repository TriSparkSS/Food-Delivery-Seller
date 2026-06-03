import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../theme/app_theme.dart';
import '../data/seller_auth_api.dart';
import '../data/seller_auth_token_storage.dart';
import '../widgets/auth_components.dart';
import 'store_details_screen.dart';

class ProfileReviewScreen extends StatefulWidget {
  const ProfileReviewScreen({
    required this.authApi,
    required this.tokenStorage,
    this.profile,
    this.onBack,
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final SellerProfile? profile;
  final VoidCallback? onBack;

  @override
  State<ProfileReviewScreen> createState() => _ProfileReviewScreenState();
}

class _ProfileReviewScreenState extends State<ProfileReviewScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = ImagePicker();
  PhoneCountry _phoneCountry = PhoneCountry.india;
  SellerProfile? _profile;
  XFile? _pickedProfileImage;
  DateTime? _dateOfBirth;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    final initialProfile = widget.profile;
    if (initialProfile != null) {
      _applyProfile(initialProfile);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void didUpdateWidget(covariant ProfileReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile && widget.profile != null) {
      _profile = widget.profile;
      _applyProfile(widget.profile!);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _selectPhoneCountry(PhoneCountry country) {
    if (_phoneCountry == country) return;
    setState(() => _phoneCountry = country);
  }

  Future<void> _loadProfile() async {
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
      setState(() {
        _profile = profile;
        _applyProfile(profile);
      });
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to fetch profile: $error');
      }
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  void _applyProfile(SellerProfile profile) {
    final parsedPhone = _parsePhoneNumber(profile.phoneNumber);
    _phoneCountry = parsedPhone.country;
    _phoneController.text = parsedPhone.localNumber;
    _fullNameController.text = profile.ownerFullName ?? '';
    _emailController.text = profile.email ?? '';
    _addressController.text =
        profile.address ?? profile.restaurant?.restaurantAddress ?? '';
    _dateOfBirth = _parseDate(profile.dateOfBirth);
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate =
        _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (pickedDate != null && mounted) {
      setState(() => _dateOfBirth = pickedDate);
    }
  }

  Future<void> _showProfileImageSourceSheet() async {
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
                const SizedBox(height: 16),
                _ImageSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfileImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                _ImageSourceTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Take Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfileImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final hasPermission = await _ensureImagePermission(source);
      if (!hasPermission) return;

      final pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (pickedImage == null || !mounted) return;
      setState(() => _pickedProfileImage = pickedImage);
    } on MissingPluginException {
      if (mounted) {
        _showMessage('Please rebuild the app after adding image picker.');
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Unable to pick profile image.');
      }
    } catch (_) {
      if (mounted) _showMessage('Unable to pick profile image.');
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
      _showMessage('Gallery permission is denied. Enable it from settings.');
      await openAppSettings();
      return false;
    }

    _showMessage('Gallery permission is required.');
    return false;
  }

  Future<bool> _requestPermission(
    Permission permission, {
    required String deniedMessage,
  }) async {
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showMessage('$deniedMessage Enable it from settings.');
      await openAppSettings();
      return false;
    }

    _showMessage(deniedMessage);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final profile = _profile ?? widget.profile;
    final documentImages =
        profile?.documentImages ?? const SellerDocumentImages();
    final profileImageUrl = _publicImageUrl(profile?.profilePhoto);
    final pickedProfileImagePath = _pickedProfileImage?.path;
    final initials = profile?.initials ?? 'S';

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
          child: RefreshIndicator(
            color: palette.green,
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 42,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: BackTextButton(onPressed: _closeApplication),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Profile Details',
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
                    'Review and update your seller information',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.mutedText,
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SellerProfileImage(
                    imageUrl: profileImageUrl,
                    localImagePath: pickedProfileImagePath,
                    initials: initials,
                    onTap: _showProfileImageSourceSheet,
                  ),
                  if (_loadingProfile) ...[
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: palette.fieldBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.green,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _EditableProfileField(
                    icon: Icons.person_outline_rounded,
                    label: 'FULL NAME',
                    controller: _fullNameController,
                    hintText: 'Enter full name',
                  ),
                  _DateOfBirthField(
                    value: _formatDate(_dateOfBirth),
                    onTap: _pickDateOfBirth,
                  ),
                  _DocumentImagesSection(images: documentImages),
                  _EditableProfileField(
                    icon: Icons.location_on_outlined,
                    label: 'ADDRESS',
                    controller: _addressController,
                    hintText: 'Enter address',
                    minLines: 2,
                    maxLines: 3,
                  ),
                  _PhoneProfileField(
                    controller: _phoneController,
                    country: _phoneCountry,
                    onCountryChanged: _selectPhoneCountry,
                  ),
                  _EditableProfileField(
                    icon: Icons.mail_outline_rounded,
                    label: 'EMAIL',
                    controller: _emailController,
                    hintText: 'Enter email address',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You can continue after checking these details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.mutedText,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => StoreDetailsScreen(
                              authApi: widget.authApi,
                              tokenStorage: widget.tokenStorage,
                              profile: profile,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Confirm & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 17),
                        ],
                      ),
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  void _closeApplication() {
    SystemNavigator.pop();
  }
}

class _SellerProfileImage extends StatelessWidget {
  const _SellerProfileImage({
    required this.imageUrl,
    required this.localImagePath,
    required this.initials,
    required this.onTap,
  });

  final String? imageUrl;
  final String? localImagePath;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final localPath = localImagePath;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 104,
              height: 104,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.green, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: palette.green.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: localPath != null
                  ? Image.file(File(localPath), fit: BoxFit.cover)
                  : imageUrl == null
                      ? _ProfileInitials(initials: initials)
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _ProfileInitials(initials: initials);
                          },
                        ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: palette.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.screen, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: palette.green.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _ProfileInitials extends StatelessWidget {
  const _ProfileInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Center(
      child: ColoredBox(
        color: palette.greenDark,
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final hasValue = value != 'Not available';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProfileSectionLabel(
            icon: Icons.cake_outlined,
            label: 'DATE OF BIRTH',
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: palette.fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.fieldBorder, width: 1.1),
              ),
              child: Row(
                children: [
                  _ProfileFieldIcon(icon: Icons.cake_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: hasValue ? palette.text : palette.mutedText,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_month_outlined,
                    color: palette.greenDark,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneProfileField extends StatelessWidget {
  const _PhoneProfileField({
    required this.controller,
    required this.country,
    required this.onCountryChanged,
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProfileSectionLabel(
            icon: Icons.phone_outlined,
            label: 'PHONE NUMBER',
          ),
          const SizedBox(height: 8),
          PhoneNumberField(
            controller: controller,
            country: country,
            onCountryChanged: onCountryChanged,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _DocumentImagesSection extends StatelessWidget {
  const _DocumentImagesSection({required this.images});

  final SellerDocumentImages images;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProfileSectionLabel(
            icon: Icons.badge_outlined,
            label: 'DOCUMENT IMAGES',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DocumentImageCard(
                  title: 'Front',
                  imageUrl: images.frontUrl,
                  icon: Icons.credit_card_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DocumentImageCard(
                  title: 'Back',
                  imageUrl: images.backUrl,
                  icon: Icons.credit_card_off_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentImageCard extends StatelessWidget {
  const _DocumentImageCard({
    required this.title,
    required this.imageUrl,
    required this.icon,
  });

  final String title;
  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final resolvedUrl = _publicImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.fieldFill,
          border: Border.all(color: palette.fieldBorder, width: 1.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AspectRatio(
          aspectRatio: 1.25,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (resolvedUrl != null)
                Image.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _DocumentImagePlaceholder(title: title, icon: icon);
                  },
                )
              else
                _DocumentImagePlaceholder(title: title, icon: icon),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.text.withValues(alpha: 0.76),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
}

class _DocumentImagePlaceholder extends StatelessWidget {
  const _DocumentImagePlaceholder({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return ColoredBox(
      color: palette.fieldFill,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: palette.mutedText, size: 28),
            const SizedBox(height: 8),
            Text(
              '$title image',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Not available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.mutedText.withValues(alpha: 0.72),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableProfileField extends StatefulWidget {
  const _EditableProfileField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  State<_EditableProfileField> createState() => _EditableProfileFieldState();
}

class _EditableProfileFieldState extends State<_EditableProfileField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _requestFocus() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileSectionLabel(icon: widget.icon, label: widget.label),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _requestFocus,
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: palette.fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? palette.green
                      : palette.fieldBorder,
                  width: _focusNode.hasFocus ? 1.4 : 1.1,
                ),
              ),
              child: Row(
                crossAxisAlignment: widget.maxLines > 1
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: widget.maxLines > 1 ? 2 : 0),
                    child: _ProfileFieldIcon(icon: widget.icon),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      keyboardType: widget.keyboardType,
                      minLines: widget.minLines,
                      maxLines: widget.maxLines,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: palette.mutedText.withValues(alpha: 0.62),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Row(
      children: [
        Icon(icon, size: 15, color: palette.mutedText),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: palette.mutedText,
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _ProfileFieldIcon extends StatelessWidget {
  const _ProfileFieldIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.softGreen.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: palette.greenDark, size: 14),
    );
  }
}

class _ParsedPhoneNumber {
  const _ParsedPhoneNumber({
    required this.country,
    required this.localNumber,
  });

  final PhoneCountry country;
  final String localNumber;
}

_ParsedPhoneNumber _parsePhoneNumber(String? phoneNumber) {
  final raw = phoneNumber?.replaceAll(RegExp(r'\s+'), '') ?? '';
  final country = authPhoneCountries
      .where((item) => raw.startsWith(item.dialCode))
      .fold<PhoneCountry?>(
        null,
        (selected, item) {
          if (selected == null) return item;
          return item.dialCode.length > selected.dialCode.length
              ? item
              : selected;
        },
      ) ??
      PhoneCountry.india;
  final localNumber = raw.startsWith(country.dialCode)
      ? raw.substring(country.dialCode.length)
      : raw.replaceAll(RegExp(r'\D'), '');

  return _ParsedPhoneNumber(country: country, localNumber: localNumber);
}

DateTime? _parseDate(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;

  final parsed = DateTime.tryParse(text);
  if (parsed != null) return parsed;

  final parts = text.split(RegExp(r'[-/.]'));
  if (parts.length != 3) return null;

  final first = int.tryParse(parts[0]);
  final second = int.tryParse(parts[1]);
  final third = int.tryParse(parts[2]);
  if (first == null || second == null || third == null) return null;

  if (parts[0].length == 4) return DateTime(first, second, third);
  return DateTime(third, second, first);
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Not available';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day.toString().padLeft(2, '0')} '
      '${months[date.month - 1]} ${date.year}';
}

String? _publicImageUrl(String? url) {
  final value = url?.trim();
  if (value == null || value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri == null) return value;
  if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
    return uri
        .replace(scheme: 'https', host: 'restro.devhimanshu.com')
        .toString();
  }

  return value;
}
