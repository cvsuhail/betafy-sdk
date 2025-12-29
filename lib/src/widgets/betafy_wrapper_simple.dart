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
  final Widget Function(BuildContext, Future<void> Function(String))?
      claimScreen;

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
  String? _initError;

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
          _initError = 'SDK Error: $e';
        });
      }
    }
  }

  Future<String?> _handleClaimCode(String claimCode) async {
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
        return null;
      } else {
        return result.error ?? 'Failed to verify claim code';
      }
    } catch (e) {
      return 'Error: $e';
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

    if (_initError != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'SDK Initialization Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isInitializing = true;
                        _initError = null;
                      });
                      _initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
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
