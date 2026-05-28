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

class SellerAuthResult {
  const SellerAuthResult({required this.message, this.data});

  final String message;
  final Map<String, Object?>? data;
}

class SellerAuthException implements Exception {
  const SellerAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class SellerAuthApi {
  Future<SellerAuthResult> sendOtp(SellerOtpRequest request);

  Future<SellerAuthResult> verifyOtp(VerifySellerOtpRequest request);
}
class NetworkSellerAuthApi implements SellerAuthApi {
  const NetworkSellerAuthApi({
    this.baseUrl = 'https://restro.shopolia.info/api/v1/seller',
    this.sendOtpPath = '/auth/otp/send',
    this.verifyOtpPath = '/auth/otp/verify',
  });

  final String baseUrl;
  final String sendOtpPath;
  final String verifyOtpPath;

  @override
  Future<SellerAuthResult> sendOtp(SellerOtpRequest request) {
    return _post(sendOtpPath, request.toJson());
  }

  @override
  Future<SellerAuthResult> verifyOtp(VerifySellerOtpRequest request) {
    return _post(verifyOtpPath, request.toJson());
  }

  Future<SellerAuthResult> _post(
    String path,
    Map<String, Object?> payload,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);

    try {
      final request = await client
          .postUrl(_uri(path))
          .timeout(const Duration(seconds: 20));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.value);
      request.write(jsonEncode(payload));

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
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
