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
}

class SellerAuthResult {
  const SellerAuthResult({required this.message, this.data});

  final String message;
  final Map<String, Object?>? data;
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
    required this.requiresRestaurantDetails,
  });

  final String message;
  final String token;
  final String tokenType;
  final bool isNewSeller;
  final bool requiresRestaurantDetails;

  factory SellerVerifyOtpResponse.fromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);

    return SellerVerifyOtpResponse(
      message: _stringFrom(json['message']) ?? 'Seller logged in successfully',
      token: _stringFrom(data['token']) ?? '',
      tokenType: _stringFrom(data['token_type']) ?? 'Bearer',
      isNewSeller: data['is_new_seller'] == true,
      requiresRestaurantDetails: data['requires_restaurant_details'] == true,
    );
  }
}

class SellerVerificationSessionResponse {
  const SellerVerificationSessionResponse({
    required this.message,
    required this.sessionUrl,
    this.sessionId = '',
    this.sessionToken = '',
    this.sdkToken = '',
  });

  final String message;
  final String sessionUrl;
  final String sessionId;
  final String sessionToken;
  final String sdkToken;

  factory SellerVerificationSessionResponse.fromJson(Map<String, Object?> json) {
    final data = _mapFrom(json['data']);
    final decisionPayload = _mapFrom(data['decision_payload']);
    final sessionUrl =
        _stringFrom(data['session_url']) ??
        _stringFrom(data['url']) ??
        _stringFrom(decisionPayload['url']);
    final sessionId =
        _stringFrom(data['session_id']) ??
        _stringFrom(decisionPayload['session_id']);
    final sessionToken =
        _stringFrom(data['session_token']) ??
        _stringFrom(decisionPayload['session_token']);
    final sdkToken =
        _stringFrom(json['sdk_token']) ??
        _stringFrom(json['session_token']) ??
        _stringFrom(data['sdk_token']) ??
        _stringFrom(data['session_token']) ??
        _stringFrom(data['token']) ??
        _stringFrom(decisionPayload['session_token']);

    return SellerVerificationSessionResponse(
      message: _stringFrom(json['message']) ?? 'Verification session created',
      sessionUrl: sessionUrl ?? '',
      sessionId: sessionId ?? '',
      sessionToken: sessionToken ?? '',
      sdkToken: sdkToken ?? '',
    );
  }
}

class SellerProfile {
  const SellerProfile({
    this.id,
    this.ownerFullName,
    this.phoneNumber,
    this.email,
    this.profilePhoto,
    this.status,
    this.verificationStatus,
    this.latestVerificationStatus,
    this.restaurant,
  });

  final int? id;
  final String? ownerFullName;
  final String? phoneNumber;
  final String? email;
  final String? profilePhoto;
  final String? status;
  final String? verificationStatus;
  final String? latestVerificationStatus;
  final SellerRestaurantProfile? restaurant;

  bool get isVerificationApproved {
    final latest = latestVerificationStatus?.toLowerCase();
    final current = verificationStatus?.toLowerCase();
    return latest == 'approved' ||
        latest == 'verified' ||
        current == 'approved' ||
        current == 'verified';
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

    return SellerProfile(
      id: _intFrom(seller['id']),
      ownerFullName: _stringFrom(seller['owner_full_name']),
      phoneNumber: _stringFrom(seller['phone_number']),
      email: _stringFrom(seller['email']),
      profilePhoto: _stringFrom(seller['profile_photo']),
      status: _stringFrom(seller['status']),
      verificationStatus: _stringFrom(seller['verification_status']),
      latestVerificationStatus:
          _stringFrom(latestVerification['status']) ??
          _stringFrom(decisionPayload['status']),
      restaurant: restaurant.isEmpty
          ? null
          : SellerRestaurantProfile.fromJson(restaurant),
    );
  }
}

class SellerRestaurantProfile {
  const SellerRestaurantProfile({
    this.restaurantName,
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
      restaurantPhone: _stringFrom(json['restaurant_phone'] ?? json['phone']),
      restaurantEmail: _stringFrom(json['restaurant_email'] ?? json['email']),
      restaurantAddress: _stringFrom(json['restaurant_address'] ?? json['address']),
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
}

class SellerAuthException implements Exception {
  const SellerAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class SellerAuthApi {
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

  Future<SellerProfile> fetchProfile({
    required String token,
    String tokenType = 'Bearer',
  });

  Future<SellerAuthResult> submitRestaurant(
    SellerRestaurantRequest request, {
    required String token,
    String tokenType = 'Bearer',
  });
}

class NetworkSellerAuthApi implements SellerAuthApi {
  const NetworkSellerAuthApi({
    this.baseUrl = 'https://restro.devhimanshu.com/api/v1/seller',
    this.sendOtpPath = '/auth/otp/send',
    this.verifyOtpPath = '/auth/otp/verify',
    this.mailAddressPath = '/auth/mail-address',
    this.verificationSessionPath = '/auth/verification/session',
    this.mePath = '/auth/me',
    this.restaurantPath = '/auth/restaurant',
  });

  final String baseUrl;
  final String sendOtpPath;
  final String verifyOtpPath;
  final String mailAddressPath;
  final String verificationSessionPath;
  final String mePath;
  final String restaurantPath;

  @override
  Future<SellerSendOtpResponse> sendOtp(SellerOtpRequest request) async {
    final result = await _post(sendOtpPath, request.toJson());
    return SellerSendOtpResponse.fromJson(result.data ?? const {});
  }

  @override
  Future<SellerVerifyOtpResponse> verifyOtp(VerifySellerOtpRequest request) async {
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
  Future<SellerProfile> fetchProfile({
    required String token,
    String tokenType = 'Bearer',
  }) async {
    final result = await _get(mePath, bearerToken: token, tokenType: tokenType);
    return SellerProfile.fromJson(result.data ?? const {});
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
      bearerToken: token,
      tokenType: tokenType,
    );
  }

  Future<SellerAuthResult> _get(
    String path, {
    required String bearerToken,
    String tokenType = 'Bearer',
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);

    try {
      final request = await client
          .getUrl(_uri(path))
          .timeout(const Duration(seconds: 20));
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        '$tokenType $bearerToken',
      );
      return _readResponse(await request.close().timeout(const Duration(seconds: 30)));
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

  Future<SellerAuthResult> _post(
    String path,
    Map<String, Object?> payload, {
    String? bearerToken,
    String tokenType = 'Bearer',
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);

    try {
      final request = await client
          .postUrl(_uri(path))
          .timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
      if (bearerToken != null && bearerToken.trim().isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          '$tokenType $bearerToken',
        );
      }
      request.write(jsonEncode(payload));

      return _readResponse(await request.close().timeout(const Duration(seconds: 30)));
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

  Future<SellerAuthResult> _postMultipart(
    String path,
    Map<String, String> fields, {
    required String bearerToken,
    String tokenType = 'Bearer',
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    final boundary = '----qadamFoodSeller${DateTime.now().microsecondsSinceEpoch}';

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

      final body = StringBuffer();
      for (final entry in fields.entries) {
        body
          ..write('--$boundary\r\n')
          ..write('Content-Disposition: form-data; name="${entry.key}"\r\n\r\n')
          ..write(entry.value)
          ..write('\r\n');
      }
      body.write('--$boundary--\r\n');
      request.add(utf8.encode(body.toString()));

      return _readResponse(await request.close().timeout(const Duration(seconds: 30)));
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

  Future<SellerAuthResult> _readResponse(HttpClientResponse response) async {
    final body = await utf8.decoder.bind(response).join();
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
}

Map<String, Object?> _mapFrom(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const {};
}

String? _stringFrom(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

int? _intFrom(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

double? _doubleFrom(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
