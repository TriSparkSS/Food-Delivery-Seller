import 'dart:io';

import 'package:flutter/services.dart';

class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceType,
    required this.deviceToken,
    this.fcmToken,
  });

  final String deviceType;
  final String deviceToken;
  final String? fcmToken;
}

abstract class DeviceIdentityProvider {
  Future<DeviceIdentity> load();
}

class PlatformDeviceIdentityProvider implements DeviceIdentityProvider {
  const PlatformDeviceIdentityProvider();

  static const _channel = MethodChannel('qadam_food_seller/device');

  @override
  Future<DeviceIdentity> load() async {
    try {
      final data = await _channel.invokeMapMethod<String, Object?>(
        'getDeviceIdentity',
      );

      return DeviceIdentity(
        deviceType: (data?['device_type'] as String?) ?? _fallbackDeviceType,
        deviceToken: (data?['device_token'] as String?) ?? _fallbackDeviceToken,
        fcmToken: data?['fcm_token'] as String?,
      );
    } on PlatformException {
      return _fallbackIdentity;
    } on MissingPluginException {
      return _fallbackIdentity;
    }
  }

  DeviceIdentity get _fallbackIdentity => DeviceIdentity(
    deviceType: _fallbackDeviceType,
    deviceToken: _fallbackDeviceToken,
  );

  String get _fallbackDeviceType {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return Platform.operatingSystem;
  }

  String get _fallbackDeviceToken {
    if (Platform.isAndroid) return 'unknown-android-device';
    if (Platform.isIOS) return 'unknown-ios-device';
    return 'unknown-${Platform.operatingSystem}-device';
  }
}
