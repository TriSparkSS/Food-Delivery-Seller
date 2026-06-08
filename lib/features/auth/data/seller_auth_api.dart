import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'device_identity.dart';

class SellerOtpRequest {
  const SellerOtpRequest({
    required this.phoneNumber,
    required this.deviceIdentity,
  });

  final String phoneNumber;
  final DeviceIdentity deviceIdentity;

  Map<String, Object?> toJson() {
    return {
      'phone_number': phoneNumber,
      'device_type': deviceIdentity.deviceType,
      'device_token': deviceIdentity.deviceToken,
      'fcm_token': deviceIdentity.fcmToken,
    };
  }
}

class VerifySellerOtpRequest extends SellerOtpRequest {
  const VerifySellerOtpRequest({
    required super.phoneNumber,
    required super.deviceIdentity,
    required this.otp,
  });

  final String otp;

  @override
  Map<String, Object?> toJson() {
    return {...super.toJson(), 'otp': otp};
  }
}

class SellerRegistrationStatusRequest {
  const SellerRegistrationStatusRequest({required this.phoneNumber});

  final String phoneNumber;

  Map<String, Object?> toJson() {
    return {'phone_number': phoneNumber};
  }
}

class SellerRegistrationStatusResponse {
  const SellerRegistrationStatusResponse({
    required this.message,
    required this.isRegistered,
  });

  final String message;
  final bool isRegistered;

  factory SellerRegistrationStatusResponse.fromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);

    return SellerRegistrationStatusResponse(
      message:
          _stringFrom(json['message']) ??
          'Seller registration status fetched successfully.',
      isRegistered: _boolFrom(data['is_registered']),
    );
  }
}

class SellerMailAddressRequest {
  const SellerMailAddressRequest({
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  final String email;
  final String password;
  final String passwordConfirmation;

  Map<String, Object?> toJson() {
    return {
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}

class SellerProfileUpdateRequest {
  const SellerProfileUpdateRequest({
    required this.name,
    required this.ownerFullName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.dateOfBirth,
    this.password,
    this.passwordConfirmation,
    this.profilePhotoPath,
  });

  final String name;
  final String ownerFullName;
  final String phoneNumber;
  final String email;
  final String address;
  final String dateOfBirth;
  final String? password;
  final String? passwordConfirmation;
  final String? profilePhotoPath;

  Map<String, String> toMultipartFields() {
    final fields = <String, String>{};

    void put(String key, String value) {
      final text = value.trim();
      if (text.isNotEmpty) fields[key] = text;
    }

    put('name', name);
    put('owner_full_name', ownerFullName);
    put('phone_number', phoneNumber);
    put('email', email);
    put('address', address);
    put('dob', dateOfBirth);
    put('password', password ?? '');
    put('password_confirmation', passwordConfirmation ?? '');

    return fields;
  }

  Map<String, String> toMultipartFiles() {
    final photoPath = profilePhotoPath?.trim();
    if (photoPath == null || photoPath.isEmpty) return const {};
    return {'profile_photo': photoPath};
  }
}

class SellerRestaurantRequest {
  const SellerRestaurantRequest({
    this.ownerFullName,
    this.email,
    this.password,
    required this.restaurantName,
    required this.restaurantPhone,
    this.restaurantEmail,
    required this.restaurantAddress,
    required this.city,
    this.latitude,
    this.longitude,
    this.cuisineType,
    this.foodType,
    required this.minimumOrderAmount,
    this.averagePreparationTime,
    this.deliveryRadius,
    this.openingHours,
    this.closingHours,
    this.coverImagePath,
    this.logoImagePath,
  });

  final String? ownerFullName;
  final String? email;
  final String? password;
  final String restaurantName;
  final String restaurantPhone;
  final String? restaurantEmail;
  final String restaurantAddress;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? cuisineType;
  final String? foodType;
  final double minimumOrderAmount;
  final int? averagePreparationTime;
  final double? deliveryRadius;
  final String? openingHours;
  final String? closingHours;
  final String? coverImagePath;
  final String? logoImagePath;

  Map<String, String> toMultipartFields() {
    final fields = <String, String>{
      'restaurant_name': restaurantName,
      'restaurant_phone': restaurantPhone,
      'restaurant_address': restaurantAddress,
      'city': city,
      'minimum_order_amount': minimumOrderAmount.toString(),
    };

    void put(String key, Object? value) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) fields[key] = text;
    }

    put('owner_full_name', ownerFullName);
    put('email', email);
    put('password', password);
    put('restaurant_email', restaurantEmail);
    put('latitude', latitude);
    put('longitude', longitude);
    put('cuisine_type', cuisineType);
    put('food_type', foodType);
    put('average_preparation_time', averagePreparationTime);
    put('delivery_radius', deliveryRadius);
    put('opening_hours', openingHours);
    put('closing_hours', closingHours);

    return fields;
  }

  Map<String, String> toMultipartFiles() {
    final files = <String, String>{};

    void put(String key, String? value) {
      final path = value?.trim();
      if (path != null && path.isNotEmpty) files[key] = path;
    }

    put('cover_image', coverImagePath);
    put('restaurant_logo', logoImagePath);

    return files;
  }
}

class SellerAuthResult {
  const SellerAuthResult({required this.message, this.data});

  final String message;
  final Map<String, Object?>? data;
}

class SellerBusinessHour {
  const SellerBusinessHour({
    required this.dayOfWeek,
    this.openingTime,
    this.closingTime,
    this.isClosed = false,
    this.is24Hours = false,
  });

  final int dayOfWeek;
  final String? openingTime;
  final String? closingTime;
  final bool isClosed;
  final bool is24Hours;

  factory SellerBusinessHour.fromJson(Map<String, Object?> json) {
    return SellerBusinessHour(
      dayOfWeek: _intFrom(json['day_of_week']) ?? 1,
      openingTime: _stringFrom(json['opening_time']),
      closingTime: _stringFrom(json['closing_time']),
      isClosed: _boolFrom(json['is_closed']),
      is24Hours: _boolFrom(json['is_24_hours']),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'opening_time': openingTime ?? '',
      'closing_time': closingTime ?? '',
      'is_closed': isClosed,
      'is_24_hours': is24Hours,
    };
  }

  static List<SellerBusinessHour> listFromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);
    Object? raw = data['business_hours'];
    if (raw == null) {
      final restaurant = _mapFrom(data['restaurant']);
      raw = restaurant['business_hours'];
    }
    raw ??= json['business_hours'];

    final items = _listFrom(raw);
    final parsed = items
        .where((item) => item != null)
        .map(_mapFrom)
        .where((item) => item.isNotEmpty)
        .map(SellerBusinessHour.fromJson)
        .toList(growable: false);

    if (parsed.isNotEmpty) return parsed;
    return SellerBusinessHour.defaultWeek();
  }

  static List<SellerBusinessHour> defaultWeek() {
    return List<SellerBusinessHour>.generate(7, (index) {
      final day = index + 1;
      return SellerBusinessHour(
        dayOfWeek: day,
        openingTime: '09:00',
        closingTime: '23:00',
        isClosed: day == 7,
        is24Hours: false,
      );
    }, growable: false);
  }
}

class SellerBusinessHoursUpdateRequest {
  const SellerBusinessHoursUpdateRequest({required this.businessHours});

  final List<SellerBusinessHour> businessHours;

  Map<String, Object?> toJson() {
    return {
      'business_hours': businessHours.map((hour) => hour.toJson()).toList(),
    };
  }
}

class SellerCuisine {
  const SellerCuisine({
    required this.id,
    required this.translatedName,
    this.imagePath,
    this.imageUrl,
    this.status = true,
  });

  final int? id;
  final String translatedName;
  final String? imagePath;
  final String? imageUrl;
  final bool status;

  factory SellerCuisine.fromJson(Map<String, Object?> json) {
    final name = _mapFrom(json['name']);
    final id = _intFrom(json['id']);

    return SellerCuisine(
      id: id,
      imagePath: _stringFrom(json['image_path']),
      imageUrl: _stringFrom(json['image_url']),
      status: _boolFrom(json['status']),
      translatedName:
          _stringFrom(json['translated_name']) ??
          _stringFrom(name['en']) ??
          _stringFrom(name['ru']) ??
          _stringFrom(name['tg']) ??
          (id == null ? 'Cuisine' : 'Cuisine $id'),
    );
  }

  static List<SellerCuisine> listFromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);
    final rawItems = _listFrom(data['items']);

    return rawItems
        .map(_mapFrom)
        .where((item) => item.isNotEmpty)
        .map(SellerCuisine.fromJson)
        .toList(growable: false);
  }
}

class SellerMenuRequest {
  const SellerMenuRequest({
    required this.translatedName,
    this.cuisineId,
    this.imagePath,
    this.status,
    this.productIds,
    this.availabilitySchedules,
  });

  final String translatedName;
  final int? cuisineId;
  final String? imagePath;
  final bool? status;
  final String? productIds;
  final String? availabilitySchedules;

  Map<String, String> toMultipartFields({bool includeStatus = false}) {
    final fields = <String, String>{
      'translated_name': translatedName.trim(),
    };

    if (cuisineId != null) {
      fields['cuisine_id'] = cuisineId.toString();
    }

    if (includeStatus && status != null) {
      fields['status'] = status! ? '1' : '0';
    }

    return fields;
  }

  Map<String, String> toMultipartFiles() {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty || path.startsWith('http')) {
      return const {};
    }
    return {'image': path};
  }
}

class SellerMenu {
  const SellerMenu({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.translatedName,
    this.image,
    this.cuisineId,
  });

  final int? id;
  final String name;
  final String description;
  final bool status;
  final String? translatedName;
  final String? image;
  final int? cuisineId;

  String get displayName {
    final translated = translatedName?.trim();
    if (translated != null && translated.isNotEmpty) return translated;
    return name;
  }

  factory SellerMenu.fromResponseJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);
    final nestedMenu = _mapFrom(data['menu']);
    final source = nestedMenu.isNotEmpty
        ? nestedMenu
        : data.isEmpty
        ? json
        : data;
    return SellerMenu.fromJson(source);
  }

  factory SellerMenu.fromJson(Map<String, Object?> json) {
    final translatedName = _stringFrom(json['translated_name']);
    return SellerMenu(
      id: _intFrom(json['id'] ?? json['menu_id']),
      name: _stringFrom(json['name']) ?? translatedName ?? 'Menu list',
      translatedName: translatedName,
      description: _stringFrom(json['description']) ?? '',
      status: json['status'] == null ? true : _boolFrom(json['status']),
      image: resolveSellerMediaUrl(
            _stringFrom(json['image_url']) ??
            _stringFrom(json['image_path']),
      ),
      cuisineId: _intFrom(json['cuisine_id']),
    );
  }

  static List<SellerMenu> listFromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);
    final rawItems = _listFrom(data['items']);

    return rawItems
        .where((item) => item != null)
        .map(_mapFrom)
        .where((item) => item.isNotEmpty)
        .map(SellerMenu.fromJson)
        .toList(growable: false);
  }
}

class SellerSendOtpResponse {
  const SellerSendOtpResponse({
    required this.message,
    this.expiresInSeconds,
    this.otp,
  });

  final String message;
  final int? expiresInSeconds;
  final String? otp;

  factory SellerSendOtpResponse.fromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);
    final expiresInSeconds = data['expires_in_seconds'];

    return SellerSendOtpResponse(
      message: _stringFrom(json['message']) ?? 'OTP sent successfully',
      expiresInSeconds: expiresInSeconds is int
          ? expiresInSeconds
          : int.tryParse(expiresInSeconds?.toString() ?? ''),
      otp: _stringFrom(data['otp']),
    );
  }
}

class SellerVerifyOtpResponse {
  const SellerVerifyOtpResponse({
    required this.message,
    required this.token,
    required this.tokenType,
    required this.isNewSeller,
    required this.isEmailVerified,
    required this.requiresRestaurantDetails,
    this.status,
    this.verificationStatus,
  });

  final String message;
  final String token;
  final String tokenType;
  final bool isNewSeller;
  final bool isEmailVerified;
  final bool requiresRestaurantDetails;
  final String? status;
  final String? verificationStatus;

  bool get isSellerOnboarding => _normalizedStatus == 'onboarding';

  bool get isSellerPending => _normalizedStatus == 'pending';

  bool get isVerificationApproved {
    final status = _normalizedVerificationStatus;
    return status == 'approved' || status == 'verified';
  }

  bool get isVerificationInReview {
    final status = _normalizedVerificationStatus;
    return status == 'in_review' ||
        status == 'under_review' ||
        status == 'pending' ||
        status == 'pending_review' ||
        status == 'submitted' ||
        status == 'processing';
  }

  bool get isVerificationFailed {
    final status = _normalizedVerificationStatus;
    return status == 'failed' ||
        status == 'rejected' ||
        status == 'declined' ||
        status == 'denied' ||
        status == 'expired' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  String get verificationStatusLabel {
    final status = verificationStatus?.trim().replaceAll('_', ' ') ?? '';
    if (status.isEmpty) return 'Pending Review';

    return status
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  String get _normalizedVerificationStatus {
    return verificationStatus
            ?.trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[\s-]+'), '_') ??
        '';
  }

  String get _normalizedStatus {
    return status?.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_') ??
        '';
  }

  factory SellerVerifyOtpResponse.fromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);

    return SellerVerifyOtpResponse(
      message: _stringFrom(json['message']) ?? 'Seller logged in successfully',
      token: _stringFrom(data['token']) ?? '',
      tokenType: _stringFrom(data['token_type']) ?? 'Bearer',
      isNewSeller: data['is_new_seller'] == true,
      isEmailVerified: _boolFrom(data['is_email_verified']),
      requiresRestaurantDetails: data['requires_restaurant_details'] == true,
      status: _stringFrom(data['status']),
      verificationStatus: _stringFrom(data['verification_status']),
    );
  }
}

class SellerVerificationSessionResponse {
  const SellerVerificationSessionResponse({
    required this.message,
    required this.sessionUrl,
    this.sessionId = '',
    this.workflowId = '',
    this.sessionToken = '',
    this.sdkToken = '',
  });

  final String message;
  final String sessionUrl;
  final String sessionId;
  final String workflowId;
  final String sessionToken;
  final String sdkToken;

  factory SellerVerificationSessionResponse.fromJson(
    Map<String, Object?> json,
  ) {
    final data = _mapFrom(json['data']);
    final decisionPayload = _mapFrom(data['decision_payload']);
    final sessionUrl =
        _stringFrom(data['session_url']) ??
        _stringFrom(data['url']) ??
        _stringFrom(decisionPayload['url']);
    final sessionId =
        _stringFrom(data['session_id']) ??
        _stringFrom(decisionPayload['session_id']);
    final urlSessionToken = _sessionTokenFromVerificationUrl(sessionUrl);
    final workflowId =
        _stringFrom(data['workflow_id']) ??
        _stringFrom(decisionPayload['workflow_id']) ??
        _stringFrom(json['workflow_id']);
    final sessionToken =
        _stringFrom(data['session_token']) ??
        _stringFrom(decisionPayload['session_token']) ??
        urlSessionToken;
    final sdkToken =
        _stringFrom(json['sdk_token']) ??
        _stringFrom(json['session_token']) ??
        _stringFrom(data['sdk_token']) ??
        _stringFrom(data['session_token']) ??
        _stringFrom(data['token']) ??
        _stringFrom(decisionPayload['session_token']) ??
        urlSessionToken;

    return SellerVerificationSessionResponse(
      message: _stringFrom(json['message']) ?? 'Verification session created',
      sessionUrl: sessionUrl ?? '',
      sessionId: sessionId ?? '',
      workflowId: workflowId ?? '',
      sessionToken: sessionToken ?? '',
      sdkToken: sdkToken ?? '',
    );
  }
}

class SellerVerificationStatusResponse {
  const SellerVerificationStatusResponse({
    required this.message,
    this.status,
    this.restaurantStatus,
    this.submittedAt,
    this.faceMatch,
    this.livenessCheck,
  });

  final String message;
  final String? status;
  final String? restaurantStatus;
  final DateTime? submittedAt;
  final SellerVerificationCheck? faceMatch;
  final SellerVerificationCheck? livenessCheck;

  String get normalizedStatus => _normalizeVerificationStatusValue(status);

  String get normalizedRestaurantStatus =>
      _normalizeVerificationStatusValue(restaurantStatus);

  String get statusLabel => _verificationStatusLabelFrom(status);

  String get restaurantStatusLabel =>
      _verificationStatusLabelFrom(restaurantStatus);

  String get combinedStatusLabel {
    final diditLabel = statusLabel;
    final restaurantLabel = restaurantStatusLabel;
    if (restaurantStatus == null || restaurantStatus!.trim().isEmpty) {
      return diditLabel;
    }
    return 'Didit $diditLabel • Restaurant $restaurantLabel';
  }

  bool get isApproved {
    final value = normalizedStatus;
    return value == 'approved' || value == 'verified';
  }

  bool get isRestaurantApproved {
    final value = normalizedRestaurantStatus;
    return value == 'approved' || value == 'verified' || value == 'active';
  }

  bool get isRestaurantInReview {
    final value = normalizedRestaurantStatus;
    return value.isEmpty ||
        value == 'in_review' ||
        value == 'under_review' ||
        value == 'pending' ||
        value == 'pending_review';
  }

  bool get isRestaurantFailed {
    final value = normalizedRestaurantStatus;
    return value == 'failed' ||
        value == 'rejected' ||
        value == 'declined' ||
        value == 'denied' ||
        value == 'expired' ||
        value == 'cancelled' ||
        value == 'canceled';
  }

  bool get isInReview {
    final value = normalizedStatus;
    return value.isEmpty ||
        value == 'in_review' ||
        value == 'under_review' ||
        value == 'pending' ||
        value == 'pending_review';
  }

  bool get isFailed {
    final value = normalizedStatus;
    return value == 'failed' ||
        value == 'rejected' ||
        value == 'declined' ||
        value == 'denied' ||
        value == 'expired' ||
        value == 'cancelled' ||
        value == 'canceled';
  }

  String get displayMessage {
    if (isApproved && isRestaurantApproved) {
      return 'Your identity and restaurant are approved';
    }
    if (isApproved && isRestaurantInReview) {
      return 'Identity approved. Restaurant is pending review';
    }
    if (isApproved && isRestaurantFailed) {
      return 'Identity approved. Restaurant needs attention';
    }
    if (isInReview) {
      return 'Your verification is under review';
    }
    if (isFailed) {
      return warningSummary ?? 'Verification needs attention';
    }
    return message;
  }

  String? get warningSummary => faceMatch?.warning ?? livenessCheck?.warning;

  factory SellerVerificationStatusResponse.fromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);
    final verification = _mapFrom(data['verification']);
    final latestVerification = _mapFrom(data['latest_verification']);
    final decisionPayload = _mapFrom(latestVerification['decision_payload']);
    final source = verification.isEmpty ? data : verification;
    final faceMatches = _listFrom(source['face_matches']);
    final livenessChecks = _listFrom(source['liveness_checks']);

    return SellerVerificationStatusResponse(
      message: _stringFrom(json['message']) ?? 'Verification status fetched.',
      status:
          _stringFrom(source['status']) ??
          _stringFrom(data['verification_status']) ??
          _stringFrom(data['status']) ??
          _stringFrom(latestVerification['status']) ??
          _stringFrom(decisionPayload['status']) ??
          _stringFrom(json['verification_status']) ??
          _stringFrom(json['status']),
      restaurantStatus:
          _stringFrom(source['restaurant_status']) ??
          _stringFrom(data['restaurant_status']) ??
          _stringFrom(json['restaurant_status']),
      submittedAt: _dateTimeFrom(source['submitted_at']),
      faceMatch: SellerVerificationCheck.fromList(faceMatches),
      livenessCheck: SellerVerificationCheck.fromList(livenessChecks),
    );
  }
}

class SellerVerificationCheck {
  const SellerVerificationCheck({this.score, this.status, this.warning});

  final double? score;
  final String? status;
  final String? warning;

  String get normalizedStatus => _normalizeVerificationStatusValue(status);

  String get statusLabel => _verificationStatusLabelFrom(status);

  bool get isApproved {
    final value = normalizedStatus;
    return value == 'approved' || value == 'verified' || value == 'passed';
  }

  bool get isInReview {
    final value = normalizedStatus;
    return value.isEmpty ||
        value == 'in_review' ||
        value == 'under_review' ||
        value == 'pending' ||
        value == 'pending_review';
  }

  bool get isFailed {
    final value = normalizedStatus;
    return value == 'failed' ||
        value == 'rejected' ||
        value == 'declined' ||
        value == 'denied' ||
        value == 'expired' ||
        value == 'cancelled' ||
        value == 'canceled';
  }

  String get scoreLabel {
    final value = score;
    if (value == null) {
      return isApproved ? '✓' : '-';
    }
    final formatted = value.toStringAsFixed(1);
    return formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
  }

  String get subtitle {
    final warningText = warning?.trim();
    if (warningText != null && warningText.isNotEmpty) {
      return warningText;
    }
    if (isApproved) {
      return '$statusLabel - Passed';
    }
    if (isInReview) {
      return '$statusLabel - Manual review pending';
    }
    if (isFailed) {
      return '$statusLabel - Needs attention';
    }
    return statusLabel;
  }

  factory SellerVerificationCheck.fromJson(Map<String, Object?> json) {
    return SellerVerificationCheck(
      score: _doubleFrom(json['score']),
      status: _stringFrom(json['status']),
      warning: _warningFrom(_listFrom(json['warnings'])),
    );
  }

  static SellerVerificationCheck? fromList(List<Object?> items) {
    if (items.isEmpty) {
      return null;
    }
    final first = _mapFrom(items.first);
    if (first.isEmpty) {
      return null;
    }
    return SellerVerificationCheck.fromJson(first);
  }

  static String? _warningFrom(List<Object?> warnings) {
    for (final item in warnings) {
      final warning = _mapFrom(item);
      final text =
          _stringFrom(warning['short_description']) ??
          _stringFrom(warning['long_description']);
      if (text != null && text.trim().isNotEmpty) {
        return text.trim();
      }
    }
    return null;
  }
}

class SellerProfile {
  const SellerProfile({
    this.id,
    this.ownerFullName,
    this.dateOfBirth,
    this.phoneNumber,
    this.email,
    this.profilePhoto,
    this.address,
    this.status,
    this.verificationStatus,
    this.latestVerificationStatus,
    this.documentImages = const SellerDocumentImages(),
    this.restaurant,
  });

  final int? id;
  final String? ownerFullName;
  final String? dateOfBirth;
  final String? phoneNumber;
  final String? email;
  final String? profilePhoto;
  final String? address;
  final String? status;
  final String? verificationStatus;
  final String? latestVerificationStatus;
  final SellerDocumentImages documentImages;
  final SellerRestaurantProfile? restaurant;

  bool get isVerificationApproved {
    final latest = latestVerificationStatus?.toLowerCase();
    final current = verificationStatus?.toLowerCase();
    return latest == 'approved' ||
        latest == 'verified' ||
        current == 'approved' ||
        current == 'verified';
  }

  bool get isVerificationFailed {
    final status = _normalizedVerificationStatus;
    return status == 'failed' ||
        status == 'rejected' ||
        status == 'declined' ||
        status == 'denied' ||
        status == 'expired' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  String get verificationStatusLabel {
    final status =
        latestVerificationStatus ?? verificationStatus ?? this.status ?? '';
    final normalized = status.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) return 'Pending Review';

    return normalized
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  String get _normalizedVerificationStatus {
    final rawStatus = latestVerificationStatus ?? verificationStatus ?? status;
    return rawStatus?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
  }

  String get initials {
    final name = ownerFullName?.trim();
    if (name == null || name.isEmpty) return 'S';
    final parts = name.split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }

  factory SellerProfile.fromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);
    final seller = data.containsKey('seller') ? _mapFrom(data['seller']) : data;
    final restaurant = _mapFrom(seller['restaurant']);
    final latestVerification = _mapFrom(seller['latest_verification']);
    final decisionPayload = _mapFrom(latestVerification['decision_payload']);
    final documents = _listFrom(seller['documents']);

    return SellerProfile(
      id: _intFrom(seller['id']),
      ownerFullName: _stringFrom(seller['owner_full_name']),
      dateOfBirth: _dateOfBirthFromProfile(
        seller: seller,
        latestVerification: latestVerification,
        decisionPayload: decisionPayload,
      ),
      phoneNumber: _stringFrom(seller['phone_number']),
      email: _stringFrom(seller['email']),
      profilePhoto: _stringFrom(seller['profile_photo']),
      address: _stringFrom(seller['address']),
      status: _stringFrom(seller['status']),
      verificationStatus: _stringFrom(seller['verification_status']),
      latestVerificationStatus:
          _stringFrom(latestVerification['status']) ??
          _stringFrom(decisionPayload['status']),
      documentImages: SellerDocumentImages.fromResponse(
        seller: seller,
        documents: documents,
        latestVerification: latestVerification,
        decisionPayload: decisionPayload,
      ),
      restaurant: restaurant.isEmpty
          ? null
          : SellerRestaurantProfile.fromJson(restaurant),
    );
  }
}

class SellerDocumentImages {
  const SellerDocumentImages({this.frontUrl, this.backUrl});

  final String? frontUrl;
  final String? backUrl;

  bool get hasFront => frontUrl != null && frontUrl!.trim().isNotEmpty;
  bool get hasBack => backUrl != null && backUrl!.trim().isNotEmpty;
  bool get hasAny => hasFront || hasBack;

  factory SellerDocumentImages.fromResponse({
    required Map<String, Object?> seller,
    required List<Object?> documents,
    required Map<String, Object?> latestVerification,
    required Map<String, Object?> decisionPayload,
  }) {
    final frontUrl =
        _documentUrlFromItems(documents, front: true) ??
        _findDocumentUrl(seller, front: true) ??
        _findDocumentUrl(latestVerification, front: true) ??
        _findDocumentUrl(decisionPayload, front: true);
    final backUrl =
        _documentUrlFromItems(documents, front: false) ??
        _findDocumentUrl(seller, front: false) ??
        _findDocumentUrl(latestVerification, front: false) ??
        _findDocumentUrl(decisionPayload, front: false);

    return SellerDocumentImages(frontUrl: frontUrl, backUrl: backUrl);
  }
}

class SellerRestaurantProfile {
  const SellerRestaurantProfile({
    this.restaurantName,
    this.restaurantLogo,
    this.coverImage,
    this.status,
    this.restaurantPhone,
    this.restaurantEmail,
    this.restaurantAddress,
    this.city,
    this.latitude,
    this.longitude,
    this.cuisineType,
    this.foodType,
    this.minimumOrderAmount,
    this.averagePreparationTime,
    this.deliveryRadius,
    this.openingHours,
    this.closingHours,
  });

  final String? restaurantName;
  final String? restaurantLogo;
  final String? coverImage;
  final String? status;
  final String? restaurantPhone;
  final String? restaurantEmail;
  final String? restaurantAddress;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? cuisineType;
  final String? foodType;
  final double? minimumOrderAmount;
  final int? averagePreparationTime;
  final double? deliveryRadius;
  final String? openingHours;
  final String? closingHours;

  factory SellerRestaurantProfile.fromJson(Map<String, Object?> json) {
    return SellerRestaurantProfile(
      restaurantName: _stringFrom(json['restaurant_name'] ?? json['name']),
      restaurantLogo: _firstImageUrlFromKeys(json, const [
        'restaurant_logo',
        'restaurant_logo_url',
        'logo',
        'logo_url',
      ]),
      coverImage: _firstImageUrlFromKeys(json, const [
        'cover_image',
        'cover_image_url',
        'cover_photo',
        'cover_photo_url',
      ]),
      status: _stringFrom(
        json['status'] ??
            json['restaurant_status'] ??
            json['verification_status'],
      ),
      restaurantPhone: _stringFrom(json['restaurant_phone'] ?? json['phone']),
      restaurantEmail: _stringFrom(json['restaurant_email'] ?? json['email']),
      restaurantAddress: _stringFrom(
        json['restaurant_address'] ?? json['address'],
      ),
      city: _stringFrom(json['city']),
      latitude: _doubleFrom(json['latitude']),
      longitude: _doubleFrom(json['longitude']),
      cuisineType: _stringFrom(json['cuisine_type']),
      foodType: _stringFrom(json['food_type']),
      minimumOrderAmount: _doubleFrom(json['minimum_order_amount']),
      averagePreparationTime: _intFrom(json['average_preparation_time']),
      deliveryRadius: _doubleFrom(json['delivery_radius']),
      openingHours: _stringFrom(json['opening_hours']),
      closingHours: _stringFrom(json['closing_hours']),
    );
  }

  factory SellerRestaurantProfile.fromApiJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);
    final restaurant = _mapFrom(data['restaurant']);
    final source = restaurant.isNotEmpty
        ? restaurant
        : data.isNotEmpty
        ? data
        : json;

    return SellerRestaurantProfile.fromJson(source);
  }
}

class SellerAuthException implements Exception {
  const SellerAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class SellerAuthApi {
  Future<SellerRegistrationStatusResponse> isRegistered(
    SellerRegistrationStatusRequest request,
  );

  Future<SellerSendOtpResponse> sendOtp(SellerOtpRequest request);

  Future<SellerVerifyOtpResponse> verifyOtp(VerifySellerOtpRequest request);

  Future<SellerAuthResult> submitMailAddress(
    SellerMailAddressRequest request, {
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerVerificationSessionResponse> createVerificationSession({
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerVerificationStatusResponse> fetchVerificationStatus({
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerProfile> fetchProfile({
    required String token,
    String tokenType = 'Bearer',
  });

  Future<List<SellerCuisine>> fetchCuisines({
    required String token,
    String tokenType = 'Bearer',
    int perPage = 15,
  });

  Future<List<SellerMenu>> fetchMenus({
    required String token,
    String tokenType = 'Bearer',
    int? cuisineId,
    int page = 1,
    int perPage = 15,
  });

  Future<SellerMenu> createMenu(
    SellerMenuRequest request, {
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerMenu> updateMenu(
    int menuId,
    SellerMenuRequest request, {
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerAuthResult> deleteMenu({
    required int menuId,
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerProfile> updateProfile(
    SellerProfileUpdateRequest request, {
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerRestaurantProfile> fetchRestaurant({
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerAuthResult> submitRestaurant(
    SellerRestaurantRequest request, {
    required String token,
    String tokenType = 'Bearer',
  });

  Future<List<SellerBusinessHour>> fetchBusinessHours({
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerAuthResult> updateBusinessHours(
    SellerBusinessHoursUpdateRequest request, {
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerAuthResult> logout({
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerAuthResult> deleteAccount({
    required String token,
    String tokenType = 'Bearer',
  });
}

class NetworkSellerAuthApi implements SellerAuthApi {
  const NetworkSellerAuthApi({
    this.baseUrl = 'https://restro.devhimanshu.com/api/v1/seller',
    this.isRegisteredPath = '/auth/is-register',
    this.sendOtpPath = '/auth/otp/send',
    this.verifyOtpPath = '/auth/otp/verify',
    this.mailAddressPath = '/auth/mail-address',
    this.verificationSessionPath = '/auth/verification/session',
    this.verificationStatusPath = '/auth/verification/status',
    this.mePath = 'https://restro.devhimanshu.com/api/v1/seller/auth/me',
    this.profileUpdatePath = '/auth/me/update',
    this.cuisinesPath = '/auth/cuisines',
    this.menusPath = '/auth/menus',
    this.restaurantPath = '/auth/restaurant',
    this.businessHoursPath = '/auth/restaurant/business-hours',
    this.logoutPath = '/auth/logout',
    this.deleteAccountPath = '/auth/delete/account',
  });

  final String baseUrl;
  final String isRegisteredPath;
  final String sendOtpPath;
  final String verifyOtpPath;
  final String mailAddressPath;
  final String verificationSessionPath;
  final String verificationStatusPath;
  final String mePath;
  final String profileUpdatePath;
  final String cuisinesPath;
  final String menusPath;
  final String restaurantPath;
  final String businessHoursPath;
  final String logoutPath;
  final String deleteAccountPath;

  @override
  Future<SellerRegistrationStatusResponse> isRegistered(
    SellerRegistrationStatusRequest request,
  ) async {
    final result = await _post(isRegisteredPath, request.toJson());
    return SellerRegistrationStatusResponse.fromJson(result.data ?? const {});
  }

  @override
  Future<SellerSendOtpResponse> sendOtp(SellerOtpRequest request) async {
    final result = await _post(sendOtpPath, request.toJson());
    return SellerSendOtpResponse.fromJson(result.data ?? const {});
  }

  @override
  Future<SellerVerifyOtpResponse> verifyOtp(
    VerifySellerOtpRequest request,
  ) async {
    final result = await _post(verifyOtpPath, request.toJson());
    return SellerVerifyOtpResponse.fromJson(result.data ?? const {});
  }

  @override
  Future<SellerAuthResult> submitMailAddress(
    SellerMailAddressRequest request, {
    required String token,
    String tokenType = 'Bearer',
  }) {
    return _post(
      mailAddressPath,
      request.toJson(),
      bearerToken: token,
      tokenType: tokenType,
      allowClosedConnectionSuccess: true,
    );
  }

  @override
  Future<SellerVerificationSessionResponse> createVerificationSession({
    required String token,
    String tokenType = 'Bearer',
  }) async {
    final result = await _post(
      verificationSessionPath,
      const {},
      bearerToken: token,
      tokenType: tokenType,
    );
    return SellerVerificationSessionResponse.fromJson(result.data ?? const {});
  }

  @override
  Future<SellerVerificationStatusResponse> fetchVerificationStatus({
    required String token,
    String tokenType = 'Bearer',
  }) async {
    final result = await _get(
      verificationStatusPath,
      bearerToken: token,
      tokenType: tokenType,
    );
    return SellerVerificationStatusResponse.fromJson(result.data ?? const {});
  }

  @override
  Future<SellerProfile> fetchProfile({
    required String token,
    String tokenType = 'Bearer',
  }) async {
    final result = await _get(mePath, bearerToken: token, tokenType: tokenType);
    return SellerProfile.fromJson(result.data ?? const {});
  }

  @override
  Future<List<SellerCuisine>> fetchCuisines({
    required String token,
    String tokenType = 'Bearer',
    int perPage = 15,
  }) async {
    final result = await _get(
      '$cuisinesPath?per_page=$perPage',
      bearerToken: token,
      tokenType: tokenType,
    );
    return SellerCuisine.listFromJson(result.data ?? const {});
  }

  @override
  Future<List<SellerMenu>> fetchMenus({
    required String token,
    String tokenType = 'Bearer',
    int? cuisineId,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String>[
      'page=$page',
      'per_page=$perPage',
    ];
    if (cuisineId != null) {
      query.add('cuisine_id=$cuisineId');
    }

    final result = await _get(
      '$menusPath?${query.join('&')}',
      bearerToken: token,
      tokenType: tokenType,
    );
    return SellerMenu.listFromJson(result.data ?? const {});
  }

  @override
  Future<SellerMenu> createMenu(
    SellerMenuRequest request, {
    required String token,
    String tokenType = 'Bearer',
  }) async {
    final result = await _postMultipart(
      menusPath,
      request.toMultipartFields(),
      files: request.toMultipartFiles(),
      bearerToken: token,
      tokenType: tokenType,
    );
    return SellerMenu.fromResponseJson(result.data ?? const {});
  }

  @override
  Future<SellerMenu> updateMenu(
    int menuId,
    SellerMenuRequest request, {
    required String token,
    String tokenType = 'Bearer',
  }) async {
    final result = await _postMultipart(
      '$menusPath/$menuId',
      request.toMultipartFields(includeStatus: true),
      files: request.toMultipartFiles(),
      bearerToken: token,
      tokenType: tokenType,
    );
    return SellerMenu.fromResponseJson(result.data ?? const {});
  }

  @override
  Future<SellerAuthResult> deleteMenu({
    required int menuId,
    required String token,
    String tokenType = 'Bearer',
  }) {
    return _delete(
      '$menusPath/$menuId',
      bearerToken: token,
      tokenType: tokenType,
    );
  }

  @override
  Future<SellerProfile> updateProfile(
    SellerProfileUpdateRequest request, {
    required String token,
    String tokenType = 'Bearer',
  }) async {
    final result = await _postMultipart(
      profileUpdatePath,
      request.toMultipartFields(),
      files: request.toMultipartFiles(),
      bearerToken: token,
      tokenType: tokenType,
    );
    return SellerProfile.fromJson(result.data ?? const {});
  }

  @override
  Future<SellerRestaurantProfile> fetchRestaurant({
    required String token,
    String tokenType = 'Bearer',
  }) async {
    final result = await _get(
      restaurantPath,
      bearerToken: token,
      tokenType: tokenType,
    );
    return SellerRestaurantProfile.fromApiJson(result.data ?? const {});
  }

  @override
  Future<SellerAuthResult> submitRestaurant(
    SellerRestaurantRequest request, {
    required String token,
    String tokenType = 'Bearer',
  }) {
    return _postMultipart(
      restaurantPath,
      request.toMultipartFields(),
      files: request.toMultipartFiles(),
      bearerToken: token,
      tokenType: tokenType,
    );
  }

  @override
  Future<List<SellerBusinessHour>> fetchBusinessHours({
    required String token,
    String tokenType = 'Bearer',
  }) async {
    final result = await _get(
      businessHoursPath,
      bearerToken: token,
      tokenType: tokenType,
    );
    return SellerBusinessHour.listFromJson(result.data ?? const {});
  }

  @override
  Future<SellerAuthResult> updateBusinessHours(
    SellerBusinessHoursUpdateRequest request, {
    required String token,
    String tokenType = 'Bearer',
  }) {
    return _put(
      businessHoursPath,
      request.toJson(),
      bearerToken: token,
      tokenType: tokenType,
    );
  }

  @override
  Future<SellerAuthResult> logout({
    required String token,
    String tokenType = 'Bearer',
  }) {
    return _post(
      logoutPath,
      const {},
      bearerToken: token,
      tokenType: tokenType,
      allowClosedConnectionSuccess: true,
    );
  }

  @override
  Future<SellerAuthResult> deleteAccount({
    required String token,
    String tokenType = 'Bearer',
  }) {
    return _post(
      deleteAccountPath,
      const {},
      bearerToken: token,
      tokenType: tokenType,
      allowClosedConnectionSuccess: true,
    );
  }

  Future<SellerAuthResult> _get(
    String path, {
    required String bearerToken,
    String tokenType = 'Bearer',
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 20);
      client.idleTimeout = const Duration(seconds: 5);

      try {
        final request = await client
            .getUrl(_uri(path))
            .timeout(const Duration(seconds: 20));
        request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
        request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
        request.headers.set(HttpHeaders.connectionHeader, 'close');
        request.headers.set(
          HttpHeaders.authorizationHeader,
          '$tokenType $bearerToken',
        );

        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
        return await _readResponse(response);
      } on SellerAuthException {
        rethrow;
      } on TimeoutException {
        throw const SellerAuthException('Request timed out. Please try again.');
      } on SocketException {
        throw const SellerAuthException(
          'Network error. Check your connection.',
        );
      } on HttpException catch (error) {
        if (attempt == 0 && _isClosedConnectionError(error)) continue;
        throw const SellerAuthException(
          'Server closed the profile request. Please try again.',
        );
      } on FormatException {
        throw const SellerAuthException('Invalid response from server.');
      } finally {
        client.close(force: true);
      }
    }

    throw const SellerAuthException('Request failed. Please try again.');
  }

  Future<SellerAuthResult> _post(
    String path,
    Map<String, Object?> payload, {
    String? bearerToken,
    String tokenType = 'Bearer',
    bool allowClosedConnectionSuccess = false,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    client.idleTimeout = const Duration(seconds: 5);

    try {
      final request = await client
          .postUrl(_uri(path))
          .timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      request.headers.set(HttpHeaders.connectionHeader, 'close');
      if (bearerToken != null && bearerToken.trim().isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          '$tokenType $bearerToken',
        );
      }
      request.write(jsonEncode(payload));

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      return _readResponse(
        response,
        allowClosedConnectionSuccess: allowClosedConnectionSuccess,
      );
    } on SellerAuthException {
      rethrow;
    } on TimeoutException {
      throw const SellerAuthException('Request timed out. Please try again.');
    } on SocketException {
      throw const SellerAuthException('Network error. Check your connection.');
    } on HttpException catch (error) {
      if (allowClosedConnectionSuccess && _isClosedConnectionError(error)) {
        return const SellerAuthResult(
          message: 'Request completed successfully',
        );
      }
      throw const SellerAuthException(
        'Server closed the request. Please try again.',
      );
    } on FormatException {
      throw const SellerAuthException('Invalid response from server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<SellerAuthResult> _put(
    String path,
    Map<String, Object?> payload, {
    required String bearerToken,
    String tokenType = 'Bearer',
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    client.idleTimeout = const Duration(seconds: 5);

    try {
      final request = await client
          .putUrl(_uri(path))
          .timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      request.headers.set(HttpHeaders.connectionHeader, 'close');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        '$tokenType $bearerToken',
      );
      request.write(jsonEncode(payload));

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      return _readResponse(response);
    } on SellerAuthException {
      rethrow;
    } on TimeoutException {
      throw const SellerAuthException('Request timed out. Please try again.');
    } on SocketException {
      throw const SellerAuthException('Network error. Check your connection.');
    } on HttpException {
      throw const SellerAuthException(
        'Server closed the request. Please try again.',
      );
    } on FormatException {
      throw const SellerAuthException('Invalid response from server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<SellerAuthResult> _delete(
    String path, {
    required String bearerToken,
    String tokenType = 'Bearer',
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    client.idleTimeout = const Duration(seconds: 5);

    try {
      final request = await client
          .deleteUrl(_uri(path))
          .timeout(const Duration(seconds: 20));
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      request.headers.set(HttpHeaders.connectionHeader, 'close');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        '$tokenType $bearerToken',
      );

      return _readResponse(
        await request.close().timeout(const Duration(seconds: 30)),
      );
    } on SellerAuthException {
      rethrow;
    } on TimeoutException {
      throw const SellerAuthException('Request timed out. Please try again.');
    } on SocketException {
      throw const SellerAuthException('Network error. Check your connection.');
    } on HttpException {
      throw const SellerAuthException(
        'Server closed the request. Please try again.',
      );
    } on FormatException {
      throw const SellerAuthException('Invalid response from server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<SellerAuthResult> _postMultipart(
    String path,
    Map<String, String> fields, {
    Map<String, String> files = const {},
    required String bearerToken,
    String tokenType = 'Bearer',
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    final boundary =
        '----qadamFoodSeller${DateTime.now().microsecondsSinceEpoch}';

    try {
      final request = await client
          .postUrl(_uri(path))
          .timeout(const Duration(seconds: 20));
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        '$tokenType $bearerToken',
      );
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      void addText(String value) {
        request.add(utf8.encode(value));
      }

      for (final entry in fields.entries) {
        addText('--$boundary\r\n');
        addText('Content-Disposition: form-data; name="${entry.key}"\r\n\r\n');
        addText(entry.value);
        addText('\r\n');
      }
      for (final entry in files.entries) {
        final file = File(entry.value);
        if (!file.existsSync()) continue;
        final maxBytes = _maxMultipartFileBytes(entry.key);
        final fileBytes = await file.length();
        if (maxBytes != null && fileBytes > maxBytes) {
          throw SellerAuthException(
            '${_multipartFileLabel(entry.key)} is too large. Please choose a smaller image.',
          );
        }
        final filename = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'upload.jpg';
        addText('--$boundary\r\n');
        addText(
          'Content-Disposition: form-data; name="${entry.key}"; filename="$filename"\r\n',
        );
        addText('Content-Type: image/jpeg\r\n\r\n');
        request.add(await file.readAsBytes());
        addText('\r\n');
      }
      addText('--$boundary--\r\n');

      return _readResponse(
        await request.close().timeout(const Duration(seconds: 30)),
      );
    } on SellerAuthException {
      rethrow;
    } on TimeoutException {
      throw const SellerAuthException('Request timed out. Please try again.');
    } on SocketException {
      throw const SellerAuthException('Network error. Check your connection.');
    } on FormatException {
      throw const SellerAuthException('Invalid response from server.');
    } finally {
      client.close(force: true);
    }
  }

  int? _maxMultipartFileBytes(String fieldName) {
    return switch (fieldName) {
      'cover_image' => 8 * 1024 * 1024,
      'restaurant_logo' || 'profile_photo' => 5 * 1024 * 1024,
      _ => null,
    };
  }

  String _multipartFileLabel(String fieldName) {
    return switch (fieldName) {
      'cover_image' => 'Cover image',
      'restaurant_logo' => 'Restaurant logo',
      'profile_photo' => 'Profile photo',
      _ => 'Selected image',
    };
  }

  Future<SellerAuthResult> _readResponse(
    HttpClientResponse response, {
    bool allowClosedConnectionSuccess = false,
  }) async {
    String body;
    try {
      body = await utf8.decoder.bind(response).join();
    } on HttpException catch (error) {
      if (allowClosedConnectionSuccess &&
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          _isClosedConnectionError(error)) {
        return const SellerAuthResult(
          message: 'Request completed successfully',
        );
      }
      rethrow;
    }

    final decoded = _decodeBody(body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        _isFailureResponse(decoded)) {
      throw SellerAuthException(
        _messageFrom(decoded) ?? 'Request failed. Please try again.',
      );
    }

    return SellerAuthResult(
      message: _messageFrom(decoded) ?? 'Request completed successfully',
      data: decoded,
    );
  }

  Uri _uri(String path) {
    final absoluteUri = Uri.tryParse(path);
    if (absoluteUri != null && absoluteUri.hasScheme) return absoluteUri;

    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Map<String, Object?> _decodeBody(String body) {
    if (body.trim().isEmpty) return const {};

    final decoded = jsonDecode(body);
    if (decoded is Map<String, Object?>) return decoded;
    if (decoded is Map) return Map<String, Object?>.from(decoded);

    return {'data': decoded};
  }

  String? _messageFrom(Map<String, Object?> body) {
    final message = body['message'] ?? body['error'];
    if (message is String && message.trim().isNotEmpty) return message;

    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }

    return null;
  }

  bool _isFailureResponse(Map<String, Object?> body) {
    final success = body['success'] ?? body['status'];
    if (success is bool) return !success;
    if (success is String) return success.toLowerCase() == 'false';
    return false;
  }

  bool _isClosedConnectionError(HttpException error) {
    return error.message.toLowerCase().contains('connection closed');
  }
}

Map<String, Object?> _mapFrom(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const {};
}

List<Object?> _listFrom(Object? value) {
  if (value is List<Object?>) return value;
  if (value is List) return List<Object?>.from(value);
  return const [];
}

String? _sessionTokenFromVerificationUrl(String? value) {
  final url = value?.trim();
  if (url == null || url.isEmpty) return null;

  final uri = Uri.tryParse(url);
  final segments = uri?.pathSegments
      .where((segment) => segment.trim().isNotEmpty)
      .toList();
  if (segments != null && segments.isNotEmpty) {
    return segments.last.trim();
  }

  final slashIndex = url.lastIndexOf('/');
  if (slashIndex >= 0 && slashIndex < url.length - 1) {
    return url.substring(slashIndex + 1).trim();
  }

  return null;
}

String? _stringFrom(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String _normalizeVerificationStatusValue(String? value) {
  return value?.trim().toLowerCase().replaceAll(' ', '_') ?? '';
}

String _verificationStatusLabelFrom(String? value) {
  final normalized = value?.trim().replaceAll('_', ' ') ?? '';
  if (normalized.isEmpty) return 'Pending Review';

  return normalized
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}

DateTime? _dateTimeFrom(Object? value) {
  final text = _stringFrom(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

String? _documentUrlFromItems(List<Object?> documents, {required bool front}) {
  for (final item in documents) {
    final document = _mapFrom(item);
    if (document.isEmpty) continue;

    final directUrl = _findDocumentUrl(document, front: front);
    if (directUrl != null) return directUrl;

    final sideText = [
      document['side'],
      document['document_side'],
      document['type'],
      document['document_type'],
      document['name'],
      document['label'],
    ].whereType<Object>().join(' ').toLowerCase();

    final matchesSide = front
        ? sideText.contains('front')
        : sideText.contains('back') || sideText.contains('rear');
    if (!matchesSide) continue;

    final sideUrl = _firstStringFromKeys(document, const [
      'url',
      'file_url',
      'image_url',
      'document_url',
      'media_url',
      'path',
      'file_path',
      'image',
    ]);
    if (sideUrl != null) return sideUrl;
  }

  return null;
}

String? _dateOfBirthFromProfile({
  required Map<String, Object?> seller,
  required Map<String, Object?> latestVerification,
  required Map<String, Object?> decisionPayload,
}) {
  return _firstStringFromKeys(seller, const [
        'date_of_birth',
        'dob',
        'birth_date',
        'birthday',
      ]) ??
      _findStringByKeys(latestVerification, const [
        'date_of_birth',
        'dob',
        'birth_date',
        'birthday',
      ]) ??
      _findStringByKeys(decisionPayload, const [
        'date_of_birth',
        'dob',
        'birth_date',
        'birthday',
      ]);
}

String? _findDocumentUrl(Object? value, {required bool front}) {
  if (value is List) {
    for (final item in value) {
      final found = _findDocumentUrl(item, front: front);
      if (found != null) return found;
    }
    return null;
  }

  final map = _mapFrom(value);
  if (map.isEmpty) return null;

  for (final entry in map.entries) {
    final key = entry.key.toLowerCase();
    final matchesSide = front
        ? key.contains('front')
        : key.contains('back') || key.contains('rear');
    final looksLikeImageKey =
        key.contains('image') ||
        key.contains('photo') ||
        key.contains('document') ||
        key.contains('file') ||
        key.contains('url') ||
        key.contains('path');

    if (matchesSide &&
        (looksLikeImageKey || key == 'front' || key == 'back') &&
        entry.value is! Map &&
        entry.value is! List) {
      final text = _stringFrom(entry.value);
      if (text != null) return text;
    }

    final nested = entry.value;
    if (nested is Map || nested is List) {
      final found = _findDocumentUrl(nested, front: front);
      if (found != null) return found;
    }
  }

  return null;
}

String? _findStringByKeys(Object? value, List<String> keys) {
  if (value is List) {
    for (final item in value) {
      final found = _findStringByKeys(item, keys);
      if (found != null) return found;
    }
    return null;
  }

  final map = _mapFrom(value);
  if (map.isEmpty) return null;

  for (final entry in map.entries) {
    final key = entry.key.toLowerCase();
    if (keys.contains(key) && entry.value is! Map && entry.value is! List) {
      final text = _stringFrom(entry.value);
      if (text != null) return text;
    }

    final nested = entry.value;
    if (nested is Map || nested is List) {
      final found = _findStringByKeys(nested, keys);
      if (found != null) return found;
    }
  }

  return null;
}

String? _firstStringFromKeys(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = _stringFrom(map[key]);
    if (value != null) return value;
  }

  return null;
}

String? _firstImageUrlFromKeys(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is Map || value is List) {
      final nested = _findStringByKeys(value, const [
        'url',
        'file_url',
        'image_url',
        'media_url',
        'path',
        'file_path',
      ]);
      if (nested != null) return nested;
      continue;
    }

    final text = _stringFrom(value);
    if (text != null) return text;
  }

  return _findStringByKeys(map, keys);
}

int? _intFrom(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

bool _boolFrom(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

double? _doubleFrom(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

const sellerMediaBaseUrl = 'https://restro.devhimanshu.com';

String? resolveSellerMediaUrl(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;

  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme) {
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return uri
          .replace(scheme: 'https', host: 'restro.devhimanshu.com')
          .toString();
    }
    return text;
  }

  if (text.startsWith('/')) return '$sellerMediaBaseUrl$text';
  return '$sellerMediaBaseUrl/$text';
}
