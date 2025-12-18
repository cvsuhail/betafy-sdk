import 'package:flutter/material.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';
import 'default_claim_screen.dart';

/// Wrapper widget with additional customization options.
/// 
/// Use [BetafyWrapperSimple] for the simplest setup.
/// 
/// This wrapper allows custom claim screens and heartbeat intervals.
class BetafyWrapper extends StatefulWidget {
  /// Your app widget
  final Widget child;

  /// Callback when emulator is detected
  final VoidCallback? onEmulatorDetected;

  /// Callback when multi-account abuse is detected
  final VoidCallback? onMultiAccountDetected;

  /// Custom claim code screen builder (optional)
  final Widget Function(BuildContext, Future<void> Function(String))? claimScreen;

  /// Heartbeat interval (default: 1 hour)
  final Duration? heartbeatInterval;

  const BetafyWrapper({
    super.key,
    required this.child,
    this.onEmulatorDetected,
    this.onMultiAccountDetected,
    this.claimScreen,
    this.heartbeatInterval,
  });

  @override
  State<BetafyWrapper> createState() => _BetafyWrapperState();
}

class _BetafyWrapperState extends State<BetafyWrapper> {
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
        heartbeatInterval: widget.heartbeatInterval,
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
        heartbeatInterval: widget.heartbeatInterval,
      );

      if (result.success) {
        final status = await TesterHeartbeatSDK.initializeWithClaim(
          onEmulatorDetected: widget.onEmulatorDetected ?? () {},
          onMultiAccountDetected: widget.onMultiAccountDetected ?? () {},
          heartbeatInterval: widget.heartbeatInterval,
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

