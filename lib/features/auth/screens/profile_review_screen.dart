import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';
import '../data/profile_image_picker.dart';
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
    this.onLoggedOut,
    this.readOnly = false,
    super.key,
  });

  final SellerAuthApi authApi;
  final SellerAuthTokenStorage tokenStorage;
  final SellerProfile? profile;
  final VoidCallback? onBack;
  final VoidCallback? onLoggedOut;
  final bool readOnly;

  @override
  State<ProfileReviewScreen> createState() => _ProfileReviewScreenState();
}

class _ProfileReviewScreenState extends State<ProfileReviewScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imagePicker = const ProfileImagePicker();
  PhoneCountry _phoneCountry = PhoneCountry.india;
  SellerProfile? _profile;
  DateTime? _dateOfBirth;
  String? _selectedProfilePhotoPath;
  bool _loadingProfile = false;
  bool _savingProfile = false;
  bool _pickingProfileImage = false;

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
    final initialDate = _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day);
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

  Future<void> _pickProfilePhoto() async {
    if (_pickingProfileImage) return;

    setState(() => _pickingProfileImage = true);
    try {
      final path = await _imagePicker.pickProfileImage();
      if (path != null && mounted) {
        setState(() => _selectedProfilePhotoPath = path);
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _showMessage(error.message ?? 'Unable to pick profile photo.');
      }
    } finally {
      if (mounted) setState(() => _pickingProfileImage = false);
    }
  }

  Future<void> _submitProfile() async {
    if (_savingProfile || _loadingProfile) return;

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final dateOfBirth = _dateOfBirth;

    if (fullName.isEmpty) {
      _showMessage('Enter full name');
      return;
    }
    if (!_isValidEmail(email)) {
      _showMessage('Enter a valid email address');
      return;
    }
    if (address.isEmpty) {
      _showMessage('Enter address');
      return;
    }
    if (dateOfBirth == null) {
      _showMessage('Select date of birth');
      return;
    }

    final token = await widget.tokenStorage.loadToken();
    final tokenType = await widget.tokenStorage.loadTokenType();

    if (token == null || token.trim().isEmpty) {
      _showMessage('Authentication failed. Login again.');
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final updatedProfile = await widget.authApi.updateProfile(
        SellerProfileUpdateRequest(
          name: fullName,
          ownerFullName: fullName,
          phoneNumber: _profilePhoneNumber,
          email: email,
          address: address,
          dateOfBirth: _formatApiDate(dateOfBirth),
          profilePhotoPath: _selectedProfilePhotoPath,
        ),
        token: token,
        tokenType: tokenType,
      );

      if (!mounted) return;
      setState(() {
        _profile = updatedProfile;
        _selectedProfilePhotoPath = null;
        _applyProfile(updatedProfile);
      });
      _showMessage('Seller profile updated successfully.');
      _openStoreDetails(updatedProfile);
    } on SellerAuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Unable to update profile. Please try again.');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  String get _profilePhoneNumber {
    final existingPhone = _profile?.phoneNumber ?? widget.profile?.phoneNumber;
    if (existingPhone != null && existingPhone.trim().isNotEmpty) {
      return existingPhone.replaceAll(RegExp(r'\s+'), '');
    }

    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '${_phoneCountry.dialCode}$digits';
  }

  void _openStoreDetails(SellerProfile? profile) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StoreDetailsScreen(
          authApi: widget.authApi,
          tokenStorage: widget.tokenStorage,
          profile: profile,
          onLoggedOut: widget.onLoggedOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final profile = _profile ?? widget.profile;
    final documentImages =
        profile?.documentImages ?? const SellerDocumentImages();
    final profileImageUrl = _publicImageUrl(profile?.profilePhoto);

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
                      child: BackTextButton(
                        onPressed: widget.readOnly
                            ? () => Navigator.maybePop(context)
                            : _closeApplication,
                      ),
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
                    widget.readOnly
                        ? 'Your seller profile information'
                        : 'Review and update your seller information',
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
                    localImagePath: _selectedProfilePhotoPath,
                    loading: _pickingProfileImage,
                    onTap: widget.readOnly ? () {} : _pickProfilePhoto,
                    readOnly: widget.readOnly,
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
                    readOnly: widget.readOnly,
                  ),
                  _DateOfBirthField(
                    value: _formatDate(_dateOfBirth),
                    onTap: widget.readOnly ? () {} : _pickDateOfBirth,
                    readOnly: widget.readOnly,
                  ),
                  _DocumentImagesSection(images: documentImages),
                  _EditableProfileField(
                    icon: Icons.location_on_outlined,
                    label: 'ADDRESS',
                    controller: _addressController,
                    hintText: 'Enter address',
                    minLines: 2,
                    maxLines: 3,
                    readOnly: widget.readOnly,
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
                    readOnly: widget.readOnly,
                  ),
                  if (!widget.readOnly) ...[
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
                        onPressed: _savingProfile ? null : _submitProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        palette.green.withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _savingProfile
                          ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Save & Continue',
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
    required this.loading,
    required this.onTap,
    this.readOnly = false,
  });

  final String? imageUrl;
  final String? localImagePath;
  final bool loading;
  final VoidCallback onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: GestureDetector(
        onTap: readOnly || loading ? null : onTap,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: palette.green,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 42,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: ClipOval(
                  child: _ProfileImageContent(
                    imageUrl: imageUrl,
                    localImagePath: localImagePath,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ),
            if (!readOnly)
              Container(
                decoration: BoxDecoration(
                  color: palette.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.screen, width: 2),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: palette.green,
                  child: loading
                      ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(
                    Icons.photo_camera_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileImageContent extends StatelessWidget {
  const _ProfileImageContent({
    required this.imageUrl,
    required this.localImagePath,
    required this.colorScheme,
  });

  final String? imageUrl;
  final String? localImagePath;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final localPath = localImagePath;
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.person,
            size: 36,
            color: colorScheme.onSurfaceVariant,
          );
        },
      );
    }

    final remoteUrl = imageUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) {
      return Icon(Icons.person, size: 36, color: colorScheme.onSurfaceVariant);
    }

    return Image.network(
      remoteUrl,
      width: 84,
      height: 84,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.person,
          size: 36,
          color: colorScheme.onSurfaceVariant,
        );
      },
    );
  }
}

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({
    required this.value,
    required this.onTap,
    this.readOnly = false,
  });

  final String value;
  final VoidCallback onTap;
  final bool readOnly;

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
            onTap: readOnly ? null : onTap,
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
            readOnly: true,
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
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: palette.text.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 13,
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

class _EditableProfileField extends StatelessWidget {
  const _EditableProfileField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AuthPalette>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileSectionLabel(icon: icon, label: label),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: palette.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.fieldBorder, width: 1.1),
            ),
            child: Row(
              crossAxisAlignment: maxLines > 1
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
                  child: _ProfileFieldIcon(icon: icon),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    minLines: minLines,
                    maxLines: maxLines,
                    readOnly: readOnly,
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
                      hintText: hintText,
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

String _formatApiDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

bool _isValidEmail(String value) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
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
