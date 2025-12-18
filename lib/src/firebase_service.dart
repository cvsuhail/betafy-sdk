import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:retry/retry.dart';

import 'models/heartbeat_event.dart';

class HeartbeatResponse {
  HeartbeatResponse({
    required this.completedStreak,
    required this.multiAccountDetected,
    required this.deviceMismatch,
  });

  final bool completedStreak;
  final bool multiAccountDetected;
  final bool deviceMismatch;

  factory HeartbeatResponse.fromJson(Map<String, dynamic> json) {
    return HeartbeatResponse(
      completedStreak: json['completed'] as bool? ?? false,
      multiAccountDetected: json['multiAccountDetected'] as bool? ?? false,
      deviceMismatch: json['deviceMismatch'] as bool? ?? false,
    );
  }
}

class FirebaseHeartbeatService {
  FirebaseHeartbeatService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    FirebaseOptions? options,
    String? sdkFirebaseAppName,
  })  : _auth = auth,
        _functions = functions,
        _options = options,
        _sdkFirebaseAppName = sdkFirebaseAppName ?? 'betafy_sdk',
        _sdkApp = null;

  final FirebaseAuth? _auth;
  final FirebaseFunctions? _functions;
  final FirebaseOptions? _options;
  final String _sdkFirebaseAppName;
  FirebaseApp? _sdkApp;
  FirebaseAuth? _sdkAuth;
  FirebaseFunctions? _sdkFunctions;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // If SDK-specific Firebase options provided, create separate app instance
      if (_options != null) {
        // Check if SDK Firebase app already exists
        try {
          _sdkApp = Firebase.app(_sdkFirebaseAppName);
        } catch (e) {
          // App doesn't exist, create it
          _sdkApp = await Firebase.initializeApp(
            name: _sdkFirebaseAppName,
            options: _options,
          );
        }
        
        // Use SDK-specific instances
        _sdkAuth = FirebaseAuth.instanceFor(app: _sdkApp!);
        _sdkFunctions = FirebaseFunctions.instanceFor(app: _sdkApp!);
      } else {
        // Use default Firebase instance (app's Firebase project)
        // Check if Firebase is already initialized
        if (Firebase.apps.isEmpty) {
          throw StateError(
            'Firebase not initialized. Either initialize Firebase in your app or provide SDK Firebase options.',
          );
        }
        // Use default instances
        _sdkAuth = _auth ?? FirebaseAuth.instance;
        _sdkFunctions = _functions ?? FirebaseFunctions.instance;
      }
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      rethrow;
    }

    await _ensureAuth();
    _initialized = true;
  }

  FirebaseAuth get _authInstance => _sdkAuth ?? FirebaseAuth.instance;
  FirebaseFunctions get _functionsInstance => _sdkFunctions ?? FirebaseFunctions.instance;

  Future<HeartbeatResponse> logHeartbeat(HeartbeatEvent event) async {
    await initialize();

    final callable = _functionsInstance.httpsCallable('logHeartbeat');

    try {
      final result = await retry(
        () async {
          final response = await callable.call<Map<String, dynamic>>({
            'gigId': event.gigId,
            'testerId': event.testerId,
            'deviceId': event.deviceData.deviceId,
            'installId': event.deviceData.installId,
            'sessionId': event.sessionId,
            'timestamps': event.timestamps
                .map((ts) => ts.toUtc().toIso8601String())
                .toList(),
            'isEmulator': event.isEmulator,
            'device': event.deviceData.toJson(),
          });
          return response.data;
        },
        retryIf: (e) =>
            e is FirebaseFunctionsException || e is FirebaseException,
        maxAttempts: 3,
      );

      return HeartbeatResponse.fromJson(result);
    } catch (e) {
      // Handle authentication errors gracefully
      debugPrint('Failed to send heartbeat: $e');
      // Return a default response instead of throwing
      return HeartbeatResponse(
        completedStreak: false,
        multiAccountDetected: false,
        deviceMismatch: false,
      );
    }
  }

  Future<void> _ensureAuth() async {
    try {
      final user = _authInstance.currentUser;
      if (user == null) {
        // Try to sign in anonymously, but don't fail if it's not allowed
        try {
          await _authInstance.signInAnonymously();
        } catch (authError) {
          // If anonymous sign-in is not enabled or not allowed, we continue anyway
          // The Cloud Function should handle authentication as needed
          debugPrint(
              'Anonymous sign-in failed (this may be expected): $authError');
        }
      }
    } catch (e) {
      // If there's any other error with auth, we continue anyway
      debugPrint('Firebase Auth check failed (continuing anyway): $e');
    }
  }

  /// Verify a claim code and bind installId to testerId/gigId
  Future<ClaimVerificationResponse> verifyClaimCode({
    required String claimCode,
    required String installId,
    required String deviceId,
    required String packageName,
    required bool isEmulator,
  }) async {
    await initialize();

    final callable = _functionsInstance.httpsCallable('verifyClaimCode');

    try {
      final result = await retry(
        () async {
          final response = await callable.call<Map<String, dynamic>>({
            'claimCode': claimCode,
            'installId': installId,
            'deviceId': deviceId,
            'packageName': packageName,
            'isEmulator': isEmulator,
          });
          return response.data;
        },
        retryIf: (e) =>
            e is FirebaseFunctionsException || e is FirebaseException,
        maxAttempts: 3,
      );

      return ClaimVerificationResponse.fromJson(result);
    } catch (e) {
      debugPrint('Failed to verify claim code: $e');
      if (e is FirebaseFunctionsException) {
        return ClaimVerificationResponse(
          success: false,
          error: e.message ?? 'Unknown error',
          code: e.code,
        );
      }
      return ClaimVerificationResponse(
        success: false,
        error: e.toString(),
        code: 'unknown',
      );
    }
  }
}

class ClaimVerificationResponse {
  ClaimVerificationResponse({
    required this.success,
    this.gigId,
    this.testerId,
    this.error,
    this.code,
  });

  final bool success;
  final String? gigId;
  final String? testerId;
  final String? error;
  final String? code;

  factory ClaimVerificationResponse.fromJson(Map<String, dynamic> json) {
    return ClaimVerificationResponse(
      success: json['success'] as bool? ?? false,
      gigId: json['gigId'] as String?,
      testerId: json['testerId'] as String?,
      error: json['error'] as String?,
      code: json['code'] as String?,
    );
  }
}
