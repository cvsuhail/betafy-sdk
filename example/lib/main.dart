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
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          fontFamily: 'SF Pro Display',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.1),
              const Color(0xFFA855F7).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon with gradient
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      ),
                      shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'SDK Active',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  const Text(
                    'Betafy SDK is tracking\ntester activity automatically',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Color(0xFF6366F1),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'SDK Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Status indicator
                        FutureBuilder<bool>(
                          future: TesterHeartbeatSDK.isClaimed(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                            
                            final isClaimed = snapshot.data!;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isClaimed
                                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isClaimed
                                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isClaimed ? Icons.check_circle : Icons.pending,
                                    color: isClaimed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isClaimed ? 'Claimed' : 'Not Claimed',
                                    style: TextStyle(
                                      color: isClaimed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Send Heartbeat Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        TesterHeartbeatSDK.sendHeartbeat();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Heartbeat sent successfully!'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite, size: 20),
                      label: const Text(
                        'Send Heartbeat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info text
                  Text(
                    'Heartbeats are sent automatically',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
