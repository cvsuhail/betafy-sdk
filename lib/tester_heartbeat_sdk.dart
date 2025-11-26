library tester_heartbeat_sdk;

import 'package:flutter/widgets.dart';
import 'package:tester_heartbeat_sdk/src/heartbeat_service.dart';
import 'package:tester_heartbeat_sdk/src/models/device_data.dart';
import 'package:tester_heartbeat_sdk/src/models/heartbeat_event.dart';

/// Public API surface for the tester heartbeat SDK.
class TesterHeartbeatSDK {
  TesterHeartbeatSDK._();

  static final TesterHeartbeatSDK _instance = TesterHeartbeatSDK._();
  static TesterHeartbeatSDK get instance => _instance;

  HeartbeatService? _service;

  /// Initialize the SDK. Must be called before any other methods.
  static Future<void> initialize({
    required String gigId,
    required String testerId,
    required VoidCallback onEmulatorDetected,
    required VoidCallback onMultiAccountDetected,
    Duration? heartbeatInterval,
  }) async {
    _instance._service = HeartbeatService(
      gigId: gigId,
      testerId: testerId,
      onEmulatorDetected: onEmulatorDetected,
      onMultiAccountDetected: onMultiAccountDetected,
      heartbeatInterval: heartbeatInterval ?? const Duration(hours: 1),
    );
    await _instance._service!.initialize();
  }

  /// Manually trigger a heartbeat immediately.
  static Future<void> sendHeartbeat() async {
    await _ensureInitialized();
    await _instance._service!.sendHeartbeat();
  }

  /// Access cached device data for diagnostics.
  static Future<DeviceData> getDeviceData() async {
    await _ensureInitialized();
    return _instance._service!.deviceData;
  }

  /// Access the latest heartbeat payload cached locally.
  static Future<HeartbeatEvent?> getLastHeartbeat() async {
    await _ensureInitialized();
    return _instance._service!.lastEvent;
  }

  static Future<void> _ensureInitialized() async {
    if (_instance._service == null) {
      throw StateError(
        'TesterHeartbeatSDK.initialize must be called before use.',
      );
    }
    await _instance._service!.waitForReady();
  } 
}
  