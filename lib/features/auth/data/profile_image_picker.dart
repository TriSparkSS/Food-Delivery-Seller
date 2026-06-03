import 'package:flutter/services.dart';

enum PickedImageSource {
  camera('camera'),
  gallery('gallery'),
  file('file');

  const PickedImageSource(this.channelValue);

  final String channelValue;
}

class ProfileImagePicker {
  const ProfileImagePicker();

  static const _channel = MethodChannel('qadam_food_seller/profile_image');

  Future<String?> pickProfileImage({
    PickedImageSource source = PickedImageSource.file,
  }) {
    return pickImage(source: source);
  }

  Future<String?> pickImage({required PickedImageSource source}) async {
    final path = await _channel.invokeMethod<String>('pickImage', {
      'source': source.channelValue,
    });
    final cleanPath = path?.trim();
    if (cleanPath == null || cleanPath.isEmpty) return null;
    return cleanPath;
  }
}
