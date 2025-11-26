import 'package:flutter/foundation.dart';

/// Immutable snapshot of device metadata.
@immutable
class DeviceData {
  const DeviceData({
    required this.deviceId,
    required this.installId,
    required this.appPackageName,
    required this.platform,
    required this.model,
    required this.osVersion,
  });

  final String deviceId;
  final String installId;
  final String appPackageName;
  final String platform;
  final String model;
  final String osVersion;

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'installId': installId,
        'appPackageName': appPackageName,
        'platform': platform,
        'model': model,
        'osVersion': osVersion,
      };

  factory DeviceData.fromJson(Map<String, dynamic> json) => DeviceData(
        deviceId: json['deviceId'] as String,
        installId: json['installId'] as String,
        appPackageName: json['appPackageName'] as String,
        platform: json['platform'] as String,
        model: json['model'] as String,
        osVersion: json['osVersion'] as String,
      );
}
