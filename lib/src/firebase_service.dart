import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:retry/retry.dart';

import 'models/heartbeat_event.dart';

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
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: _options,
      );
    }
    await _ensureAuth();
    _initialized = true;
  }

  Future<HeartbeatResponse> logHeartbeat(HeartbeatEvent event) async {
    await initialize();

    final callable = _functions.httpsCallable('logHeartbeat');

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
      retryIf: (e) => e is FirebaseFunctionsException || e is FirebaseException,
      maxAttempts: 3,
    );

    return HeartbeatResponse.fromJson(result);
  }

  Future<void> _ensureAuth() async {
    final user = _auth.currentUser;
    if (user == null) {
      await _auth.signInAnonymously();
    }
  }
}

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
