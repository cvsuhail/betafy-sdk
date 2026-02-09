# Betafy SDK Integration Examples

This guide shows how to integrate the Betafy SDK into your Flutter app with code examples.

## 🎯 Integration Methods

### Method 1: Simple Wrapper (Recommended for Most Apps)

The easiest way to integrate the SDK. Handles everything automatically.

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optional: Initialize your app's Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BetafyWrapperSimple(
      // Required: SDK's Firebase configuration
      sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
      
      // Optional: Callbacks for security events
      onEmulatorDetected: () {
        debugPrint('⚠️ Emulator detected!');
      },
      onMultiAccountDetected: () {
        debugPrint('⚠️ Multi-account abuse detected!');
      },
      
      // Your app
      child: MaterialApp(
        title: 'My App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
```

**What it does:**
- ✅ Automatically shows claim code screen if not claimed
- ✅ Handles SDK initialization
- ✅ Tracks heartbeats automatically
- ✅ Beautiful, modern UI out of the box

---

### Method 2: Advanced Wrapper (Custom Claim Screen)

Use this when you want a custom claim screen but still want automatic handling.

```dart
import 'package:flutter/material.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BetafyWrapper(
      // Required: SDK's Firebase configuration
      sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
      
      // Custom claim screen
      claimScreen: (context, onClaimCallback) {
        return MyCustomClaimScreen(onClaim: onClaimCallback);
      },
      
      // Your app
      child: MaterialApp(
        home: const HomeScreen(),
      ),
    );
  }
}

class MyCustomClaimScreen extends StatefulWidget {
  final Future<void> Function(BuildContext, String) onClaim;
  
  const MyCustomClaimScreen({super.key, required this.onClaim});

  @override
  State<MyCustomClaimScreen> createState() => _MyCustomClaimScreenState();
}

class _MyCustomClaimScreenState extends State<MyCustomClaimScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verify() async {
    setState(() => _isVerifying = true);
    try {
      await widget.onClaim(context, _controller.text.trim());
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your custom UI here
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Enter Claim Code',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isVerifying ? null : _verify,
                child: _isVerifying
                    ? const CircularProgressIndicator()
                    : const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

### Method 3: Manual Integration (Full Control)

Use this when you need complete control over the entire flow.

```dart
import 'package:flutter/material.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';

class ManualIntegrationExample extends StatefulWidget {
  const ManualIntegrationExample({super.key});

  @override
  State<ManualIntegrationExample> createState() => _ManualIntegrationExampleState();
}

class _ManualIntegrationExampleState extends State<ManualIntegrationExample> {
  bool _isClaimed = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkClaimStatus();
  }

  Future<void> _checkClaimStatus() async {
    setState(() => _isChecking = true);
    
    // Check if already claimed
    final isClaimed = await TesterHeartbeatSDK.isClaimed();
    
    if (isClaimed) {
      // Initialize with existing claim
      final status = await TesterHeartbeatSDK.initializeWithClaim(
        sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
        onEmulatorDetected: () => debugPrint('Emulator detected'),
        onMultiAccountDetected: () => debugPrint('Multi-account detected'),
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

  Future<void> _verifyClaimCode(String code) async {
    final result = await TesterHeartbeatSDK.verifyClaimCode(
      code,
      sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
      onEmulatorDetected: () => debugPrint('Emulator detected'),
      onMultiAccountDetected: () => debugPrint('Multi-account detected'),
    );

    if (result.success) {
      setState(() => _isClaimed = true);
    } else {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Failed to verify')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isClaimed) {
      return MyClaimScreen(onVerify: _verifyClaimCode);
    }

    return MyMainApp();
  }
}

// Helper methods
class TesterHeartbeatSDKHelper {
  // Send manual heartbeat
  static void sendHeartbeat() {
    TesterHeartbeatSDK.sendHeartbeat();
  }
  
  // Clear claim binding (for testing)
  static Future<void> clearClaim() async {
    await TesterHeartbeatSDK.clearClaimBinding();
  }
  
  // Check claim status
  static Future<bool> isClaimed() async {
    return await TesterHeartbeatSDK.isClaimed();
  }
}
```

---

## 📦 Adding to Your Project

### From Local Path (Development)

```yaml
dependencies:
  tester_heartbeat_sdk:
    path: ../path/to/betafy-sdk
```

### From GitHub

```yaml
dependencies:
  tester_heartbeat_sdk:
    git:
      url: https://github.com/YOUR_USERNAME/betafy-sdk.git
      ref: main
```

### From pub.dev (When Published)

```yaml
dependencies:
  tester_heartbeat_sdk: ^0.1.0
```

---

## 🎨 UI Customization

The SDK provides a beautiful default UI, but you can customize it:

### Custom Colors

```dart
BetafyWrapperSimple(
  sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
  child: MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple, // Your brand color
      ),
    ),
    home: const HomeScreen(),
  ),
)
```

### Custom Claim Screen

Use `BetafyWrapper` instead of `BetafyWrapperSimple` and provide your custom `claimScreen` builder (see Method 2 above).

---

## 🔍 API Reference

### TesterHeartbeatSDK

Main SDK class with static methods:

#### `verifyClaimCode()`
```dart
Future<ClaimResult> verifyClaimCode(
  String claimCode, {
  required FirebaseOptions sdkFirebaseOptions,
  VoidCallback? onEmulatorDetected,
  VoidCallback? onMultiAccountDetected,
})
```

#### `initializeWithClaim()`
```dart
Future<ClaimStatus> initializeWithClaim({
  required FirebaseOptions sdkFirebaseOptions,
  VoidCallback? onEmulatorDetected,
  VoidCallback? onMultiAccountDetected,
})
```

#### `isClaimed()`
```dart
Future<bool> isClaimed()
```

#### `sendHeartbeat()`
```dart
void sendHeartbeat()
```

#### `clearClaimBinding()`
```dart
Future<void> clearClaimBinding()
```

---

## 🧪 Testing

### Testing Claim Flow

1. Run your app with the SDK integrated
2. Get a claim code from the tester dashboard
3. Enter the code when prompted
4. Verify that the SDK is now active

### Reset Claim for Testing

```dart
await TesterHeartbeatSDK.clearClaimBinding();
// App will show claim screen again on next launch
```

---

## 🐛 Common Issues

### "Firebase already initialized"

This is normal if your app also uses Firebase. The SDK handles multiple Firebase instances.

### "Claim code invalid"

- Check the code hasn't expired (30 minutes)
- Verify it hasn't been used already
- Make sure you're copying the full code (XXXX-XXXX)

### "SDK not found"

Run `flutter pub get` to install dependencies.

---

## 📚 More Resources

- [Main README](../README.md) - SDK overview
- [INTEGRATION_GUIDE](../INTEGRATION_GUIDE.md) - Detailed integration guide
- [LOGIC](../LOGIC.md) - How the claim system works
- [Example Apps](./lib/) - Working code examples

---

## 💡 Best Practices

1. **Use BetafyWrapperSimple** for most apps - it handles everything
2. **Keep claim codes secure** - they're single-use and expire
3. **Test on real devices** - emulator detection is active
4. **Handle callbacks** - know when security events occur
5. **Monitor heartbeats** - check the dashboard for tester activity

---

## 🎉 You're Ready!

The SDK is now integrated. Your app will automatically:
- Show a claim screen to new testers
- Track tester activity with heartbeats
- Prevent abuse with device verification
- Report analytics to the dashboard

Happy testing! 🚀
