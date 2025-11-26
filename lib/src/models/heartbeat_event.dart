import 'dart:convert';

import 'device_data.dart';

/// Serializable heartbeat payload sent to Firebase.
class HeartbeatEvent {
  HeartbeatEvent({
    required this.gigId,
    required this.testerId,
    required this.sessionId,
    required this.timestamps,
    required this.deviceData,
    required this.isEmulator,
  });

  final String gigId;
  final String testerId;
  final String sessionId;
  final List<DateTime> timestamps;
  final DeviceData deviceData;
  final bool isEmulator;

  Map<String, dynamic> toJson() {
    return {
      'gigId': gigId,
      'testerId': testerId,
      'sessionId': sessionId,
      'timestamps':
          timestamps.map((ts) => ts.toUtc().toIso8601String()).toList(),
      'device': deviceData.toJson(),
      'isEmulator': isEmulator,
    };
  }

  factory HeartbeatEvent.fromJson(Map<String, dynamic> json) {
    return HeartbeatEvent(
      gigId: json['gigId'] as String,
      testerId: json['testerId'] as String,
      sessionId: json['sessionId'] as String,
      timestamps: (json['timestamps'] as List<dynamic>)
          .map((value) => DateTime.parse(value as String).toUtc())
          .toList(),
      deviceData: DeviceData.fromJson(json['device'] as Map<String, dynamic>),
      isEmulator: json['isEmulator'] as bool? ?? false,
    );
  }

  String encode() => jsonEncode(toJson());

  static HeartbeatEvent decode(String raw) =>
      HeartbeatEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
