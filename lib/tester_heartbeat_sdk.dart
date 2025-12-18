library tester_heartbeat_sdk;

export 'src/widgets/betafy_wrapper.dart';
export 'src/widgets/betafy_wrapper_simple.dart';
export 'betafy_firebase_options.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tester_heartbeat_sdk/src/heartbeat_service.dart';
import 'package:tester_heartbeat_sdk/src/models/device_data.dart';
import 'package:tester_heartbeat_sdk/src/models/heartbeat_event.dart';
import 'package:tester_heartbeat_sdk/src/firebase_service.dart';
import 'package:tester_heartbeat_sdk/src/utils/shared_prefs.dart';
import 'package:tester_heartbeat_sdk/src/device_info_service.dart';
import 'package:tester_heartbeat_sdk/src/utils/emulator_check.dart';

/// Public API surface for the tester heartbeat SDK.
class TesterHeartbeatSDK {
  TesterHeartbeatSDK._();

  static final TesterHeartbeatSDK _instance = TesterHeartbeatSDK._();
  static TesterHeartbeatSDK get instance => _instance;

  HeartbeatService? _service;

  /// Initialize the SDK with explicit gigId and testerId (legacy mode).
  /// For closed testing, use [initializeWithClaim] instead.
  static Future<void> initialize({
    required String gigId,
    required String testerId,
    required VoidCallback onEmulatorDetected,
    required VoidCallback onMultiAccountDetected,
    Duration? heartbeatInterval,
    FirebaseOptions? sdkFirebaseOptions,
  }) async {
    _instance._service = HeartbeatService(
      gigId: gigId,
      testerId: testerId,
      onEmulatorDetected: onEmulatorDetected,
      onMultiAccountDetected: onMultiAccountDetected,
      heartbeatInterval: heartbeatInterval ?? const Duration(hours: 1),
      sdkFirebaseOptions: sdkFirebaseOptions,
    );
    await _instance._service!.initialize();
  }

  /// Initialize the SDK in claim mode (for closed testing).
  /// This will check for existing claim binding or wait for claim.
  /// 
  /// [sdkFirebaseOptions] - Optional. If provided, SDK will use separate Firebase project.
  /// If not provided, SDK will use app's default Firebase project.
  static Future<ClaimStatus> initializeWithClaim({
    required VoidCallback onEmulatorDetected,
    required VoidCallback onMultiAccountDetected,
    Duration? heartbeatInterval,
    FirebaseOptions? sdkFirebaseOptions,
  }) async {
    final prefs = await SharedPrefsStore.instance();
    final binding = prefs.getClaimBinding();

    if (binding != null) {
      // Already claimed, initialize normally
      await initialize(
        gigId: binding['gigId']!,
        testerId: binding['testerId']!,
        onEmulatorDetected: onEmulatorDetected,
        onMultiAccountDetected: onMultiAccountDetected,
        heartbeatInterval: heartbeatInterval,
        sdkFirebaseOptions: sdkFirebaseOptions,
      );
      return ClaimStatus.claimed;
    }

    // Not claimed yet
    return ClaimStatus.unclaimed;
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

  /// Verify a claim code and bind this install to a tester/gig.
  /// If successful, automatically initializes the heartbeat service.
  /// Callbacks must be provided if not already initialized.
  /// 
  /// [sdkFirebaseOptions] - Optional. If provided, SDK will use separate Firebase project.
  /// If not provided, SDK will use app's default Firebase project.
  static Future<ClaimResult> verifyClaimCode(
    String claimCode, {
    VoidCallback? onEmulatorDetected,
    VoidCallback? onMultiAccountDetected,
    Duration? heartbeatInterval,
    FirebaseOptions? sdkFirebaseOptions,
  }) async {
    try {
      final deviceInfoService = DeviceInfoService();
      final deviceData = await deviceInfoService.loadDeviceData();
      final emulatorCheck = EmulatorCheck();
      final isEmulator = await emulatorCheck.isEmulator();

      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      final firebaseService = FirebaseHeartbeatService(
        options: sdkFirebaseOptions,
      );
      await firebaseService.initialize();

      final response = await firebaseService.verifyClaimCode(
        claimCode: claimCode,
        installId: deviceData.installId,
        deviceId: deviceData.deviceId,
        packageName: packageName,
        isEmulator: isEmulator,
      );

      if (response.success && response.gigId != null && response.testerId != null) {
        // Store claim binding
        final prefs = await SharedPrefsStore.instance();
        await prefs.saveClaimBinding(response.gigId!, response.testerId!);

        // Auto-initialize if callbacks provided
        if (onEmulatorDetected != null && onMultiAccountDetected != null) {
          await initialize(
            gigId: response.gigId!,
            testerId: response.testerId!,
            onEmulatorDetected: onEmulatorDetected,
            onMultiAccountDetected: onMultiAccountDetected,
            heartbeatInterval: heartbeatInterval,
            sdkFirebaseOptions: sdkFirebaseOptions,
          );
        }

        return ClaimResult(
          success: true,
          gigId: response.gigId,
          testerId: response.testerId,
        );
      } else {
        return ClaimResult(
          success: false,
          error: response.error ?? 'Unknown error',
          errorCode: response.code,
        );
      }
    } catch (e) {
      return ClaimResult(
        success: false,
        error: e.toString(),
        errorCode: 'exception',
      );
    }
  }

  /// Check if the install is already claimed.
  static Future<bool> isClaimed() async {
    final prefs = await SharedPrefsStore.instance();
    final binding = prefs.getClaimBinding();
    return binding != null;
  }

  /// Get claim binding if exists.
  static Future<Map<String, String>?> getClaimBinding() async {
    final prefs = await SharedPrefsStore.instance();
    return prefs.getClaimBinding();
  }

  /// Clear claim binding (for testing or reset).
  static Future<void> clearClaimBinding() async {
    final prefs = await SharedPrefsStore.instance();
    await prefs.clearClaimBinding();
    _instance._service = null;
  }

  static Future<void> _ensureInitialized() async {
    if (_instance._service == null) {
      throw StateError(
        'TesterHeartbeatSDK.initialize or TesterHeartbeatSDK.initializeWithClaim must be called before use.',
      );
    }
    await _instance._service!.waitForReady();
  } 
}

/// Status of claim initialization
enum ClaimStatus {
  /// Install is already claimed and SDK is ready
  claimed,
  /// Install is not yet claimed, needs user to enter claim code
  unclaimed,
}

/// Result of claim code verification
class ClaimResult {
  ClaimResult({
    required this.success,
    this.gigId,
    this.testerId,
    this.error,
    this.errorCode,
  });

  final bool success;
  final String? gigId;
  final String? testerId;
  final String? error;
  final String? errorCode;
}
  