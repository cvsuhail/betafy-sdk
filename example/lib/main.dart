import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the generated options
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Firebase might already be initialized, which is fine
    debugPrint(
      'Firebase initialization error (might be already initialized): $e',
    );
  }

  // Get Device ID
  final deviceId = await _getDeviceId();
  if (deviceId == null) {
    debugPrint('Could not retrieve device ID.');
    return;
  }

  // Fetch Tester ID from Firestore
  String? testerId;
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      testerId = querySnapshot.docs.first.id;
      debugPrint('Tester ID found: $testerId');
    } else {
      debugPrint('No user found with device ID: $deviceId');
    }
  } catch (e) {
    debugPrint('Error fetching tester ID: $e');
  }

  if (testerId != null) {
    // Initialize the SDK
    await TesterHeartbeatSDK.initialize(
      gigId: 'rgAfpGMsEcn3205gqrW4',
      testerId: testerId,
      onEmulatorDetected: () {
        debugPrint('Emulator detected!');
      },
      onMultiAccountDetected: () {
        debugPrint('Potential multi-account abuse detected.');
      },
    );
  } else {
    debugPrint('SDK initialization skipped because testerId could not be found.');
  }
  runApp(const ExampleApp());
}



Future<String?> _getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor;
  }
  return null;
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tester Heartbeat Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Tester Heartbeat SDK')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => TesterHeartbeatSDK.sendHeartbeat(),
            child: const Text('Send manual heartbeat'),
          ),
        ),
      ),
    );
  }
}
