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
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _options = options;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseOptions? _options;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: _options,
        );
      }
      // If Firebase is already initialized, we just continue without re-initializing
    } catch (e) {
      // Firebase might already be initialized, which is fine
      // We catch all exceptions to prevent initialization failures
      debugPrint('Firebase initialization warning: $e');
    }

    await _ensureAuth();
    _initialized = true;
  }

  Future<HeartbeatResponse> logHeartbeat(HeartbeatEvent event) async {
    await initialize();

    final callable = _functions.httpsCallable('logHeartbeat');

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
      final user = _auth.currentUser;
      if (user == null) {
        // Try to sign in anonymously, but don't fail if it's not allowed
        try {
          await _auth.signInAnonymously();
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
}
