import 'package:flutter/material.dart';

/// Default claim code input screen used by wrapper widgets
class DefaultClaimScreen extends StatefulWidget {
  final Future<void> Function(BuildContext, String) onClaim;

  const DefaultClaimScreen({super.key, required this.onClaim});

  @override
  State<DefaultClaimScreen> createState() => _DefaultClaimScreenState();
}

class _DefaultClaimScreenState extends State<DefaultClaimScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isVerifying = false;
  String? _error;

  Future<void> _verify(BuildContext scaffoldContext) async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a claim code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      await widget.onClaim(scaffoldContext, code);
    } catch (e) {
      // Handle error display - use ScaffoldMessenger key or show in UI
      if (mounted) {
        // Try using ScaffoldMessenger key
        if (_scaffoldMessengerKey.currentState != null) {
          _scaffoldMessengerKey.currentState!.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // If ScaffoldMessenger key is not ready, show error in UI
          setState(() {
            _error = 'Error: $e';
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Enter Claim Code')),
        body: Builder(
          builder: (scaffoldContext) => Padding(
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
                  onSubmitted: (_) => _verify(scaffoldContext),
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
                    onPressed: _isVerifying ? null : () => _verify(scaffoldContext),
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
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
