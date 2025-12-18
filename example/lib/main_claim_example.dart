import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';

import 'firebase_options.dart';

/// Advanced example showing manual claim flow implementation
/// This demonstrates how to implement the claim flow without using BetafyWrapperSimple

/// Example showing the post-install claim flow for closed testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const ClaimExampleApp());
}

class ClaimExampleApp extends StatelessWidget {
  const ClaimExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claim Flow Example',
      home: const ClaimScreen(),
    );
  }
}

class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final TextEditingController _claimCodeController = TextEditingController();
  bool _isClaimed = false;
  bool _isChecking = true;
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkClaimStatus();
  }

  Future<void> _checkClaimStatus() async {
    setState(() {
      _isChecking = true;
    });

    // Check if already claimed
    final isClaimed = await TesterHeartbeatSDK.isClaimed();
    
    if (isClaimed) {
      // Try to initialize with existing claim
      final status = await TesterHeartbeatSDK.initializeWithClaim(
        sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
        onEmulatorDetected: () {
          debugPrint('Emulator detected!');
        },
        onMultiAccountDetected: () {
          debugPrint('Multi-account abuse detected!');
        },
      );

      setState(() {
        _isClaimed = status == ClaimStatus.claimed;
        _isChecking = false;
      });
    } else {
      setState(() {
        _isClaimed = false;
        _isChecking = false;
      });
    }
  }

  Future<void> _verifyClaimCode() async {
    final claimCode = _claimCodeController.text.trim().toUpperCase();
    
    if (claimCode.isEmpty) {
      setState(() {
        _error = 'Please enter a claim code';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final result = await TesterHeartbeatSDK.verifyClaimCode(
        claimCode,
        sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
        onEmulatorDetected: () {
          debugPrint('Emulator detected!');
        },
        onMultiAccountDetected: () {
          debugPrint('Multi-account abuse detected!');
        },
      );

      if (result.success) {
        setState(() {
          _isClaimed = true;
          _isVerifying = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully claimed! SDK is now active.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _error = result.error ?? 'Failed to verify claim code';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isClaimed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claimed - SDK Active')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Install is claimed and SDK is active!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => TesterHeartbeatSDK.sendHeartbeat(),
                child: const Text('Send Manual Heartbeat'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await TesterHeartbeatSDK.clearClaimBinding();
                  await _checkClaimStatus();
                },
                child: const Text('Reset Claim (Testing)'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Claim Code')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'This app is under test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enter your claim code from the tester app',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _claimCodeController,
              decoration: InputDecoration(
                labelText: 'Claim Code',
                hintText: 'XXXX-XXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.code),
              ),
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyClaimCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Verify Claim Code',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _claimCodeController.dispose();
    super.dispose();
  }
}

