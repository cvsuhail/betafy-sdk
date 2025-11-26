import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize the SDK
  await TesterHeartbeatSDK.initialize(
    gigId: 'GIG123',
    testerId: 'USER123',
    onEmulatorDetected: () {
      debugPrint('Emulator detected!');
    },
    onMultiAccountDetected: () {
      debugPrint('Potential multi-account abuse detected.');
    },
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tester Heartbeat Example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Tester Heartbeat SDK'),
        ),
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
