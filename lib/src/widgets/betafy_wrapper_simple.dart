import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';
import 'default_claim_screen.dart';

/// Ultra-simple wrapper that requires Firebase to be initialized first.
/// 
/// This is the simplest version - just wrap your app:
/// 
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///   
///   runApp(
///     BetafyWrapperSimple(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
/// 
/// If your app uses a different Firebase project than the SDK backend:
/// 
/// ```dart
/// BetafyWrapperSimple(
///   sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform, // SDK's Firebase
///   child: MyApp(),
/// )
/// ```
class BetafyWrapperSimple extends StatefulWidget {
  /// Your app widget
  final Widget child;

  /// Callback when emulator is detected (optional)
  final VoidCallback? onEmulatorDetected;

  /// Callback when multi-account abuse is detected (optional)
  final VoidCallback? onMultiAccountDetected;

  /// Custom claim code screen (optional - uses default if not provided)
  final Widget Function(BuildContext, Future<void> Function(String))? claimScreen;

  /// SDK Firebase options (optional)
  /// If provided, SDK will use separate Firebase project (e.g., betafy-2e207)
  /// If not provided, SDK will use app's default Firebase project
  final FirebaseOptions? sdkFirebaseOptions;

  const BetafyWrapperSimple({
    super.key,
    required this.child,
    this.onEmulatorDetected,
    this.onMultiAccountDetected,
    this.claimScreen,
    this.sdkFirebaseOptions,
  });

  @override
  State<BetafyWrapperSimple> createState() => _BetafyWrapperSimpleState();
}

class _BetafyWrapperSimpleState extends State<BetafyWrapperSimple> {
  bool _isInitializing = true;
  ClaimStatus? _claimStatus;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final status = await TesterHeartbeatSDK.initializeWithClaim(
        onEmulatorDetected: widget.onEmulatorDetected ?? () {},
        onMultiAccountDetected: widget.onMultiAccountDetected ?? () {},
        sdkFirebaseOptions: widget.sdkFirebaseOptions,
      );

      if (mounted) {
        setState(() {
          _claimStatus = status;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SDK Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleClaimCode(String claimCode) async {
    try {
      final result = await TesterHeartbeatSDK.verifyClaimCode(
        claimCode,
        onEmulatorDetected: widget.onEmulatorDetected ?? () {},
        onMultiAccountDetected: widget.onMultiAccountDetected ?? () {},
        sdkFirebaseOptions: widget.sdkFirebaseOptions,
      );

      if (result.success) {
        // Re-initialize to get claimed status
        final status = await TesterHeartbeatSDK.initializeWithClaim(
          onEmulatorDetected: widget.onEmulatorDetected ?? () {},
          onMultiAccountDetected: widget.onMultiAccountDetected ?? () {},
          sdkFirebaseOptions: widget.sdkFirebaseOptions,
        );
        if (mounted) {
          setState(() {
            _claimStatus = status;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to verify claim code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Initializing SDK...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_claimStatus == ClaimStatus.unclaimed) {
      if (widget.claimScreen != null) {
        return widget.claimScreen!(context, _handleClaimCode);
      }
      return DefaultClaimScreen(onClaim: _handleClaimCode);
    }

    return widget.child;
  }
}

/// Shared default claim screen
class _DefaultClaimScreen extends StatefulWidget {
  final Future<void> Function(String) onClaim;

  const _DefaultClaimScreen({required this.onClaim});

  @override
  State<_DefaultClaimScreen> createState() => _DefaultClaimScreenState();
}

class _DefaultClaimScreenState extends State<_DefaultClaimScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  Future<void> _verify() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a claim code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    await widget.onClaim(code);

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                'Enter your claim code from the tester app',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
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
                onSubmitted: (_) => _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator()
                      : const Text('Verify Claim Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

