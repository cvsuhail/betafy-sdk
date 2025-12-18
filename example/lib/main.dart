import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';

import 'firebase_options.dart';

/// Simple example using BetafyWrapperSimple - the easiest way to integrate the SDK
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize your app's Firebase (if you have one)
  // This is optional - the SDK uses its own Firebase project (betafy-2e207)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error (might be already initialized): $e');
  }

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BetafyWrapperSimple(
      // Provide SDK's Firebase options (betafy-2e207)
      sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
      
      // Optional: Handle callbacks
      onEmulatorDetected: () {
        debugPrint('⚠️ Emulator detected!');
      },
      onMultiAccountDetected: () {
        debugPrint('⚠️ Multi-account abuse detected!');
      },
      
      // Your app
      child: MaterialApp(
        title: 'Betafy SDK Example',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Betafy SDK Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'SDK is Active!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The Betafy SDK is tracking tester activity automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SDK Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<bool>(
                        future: TesterHeartbeatSDK.isClaimed(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Row(
                              children: [
                                Icon(
                                  snapshot.data! ? Icons.check_circle : Icons.pending,
                                  color: snapshot.data! ? Colors.green : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  snapshot.data! ? 'Claimed' : 'Not Claimed',
                                  style: TextStyle(
                                    color: snapshot.data! ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const Text('Checking...');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  TesterHeartbeatSDK.sendHeartbeat();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Heartbeat sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Manual Heartbeat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
