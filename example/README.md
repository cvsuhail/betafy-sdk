# Betafy SDK Example App

This example demonstrates how to integrate the Betafy SDK into your Flutter app with a modern, beautiful UI.

## 📋 Prerequisites

1. Flutter SDK installed (>=3.4.0)
2. A device or emulator to test on
3. Firebase project (optional - the SDK uses its own Firebase backend)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd betafy-sdk/example
flutter pub get
```

### 2. Run the Example

**Run the simple wrapper example:**
```bash
flutter run -t lib/main.dart
```

**Run the advanced claim flow example:**
```bash
flutter run -t lib/main_claim_example.dart
```

## 📱 Example Implementations

### Simple Example (`main.dart`)

Uses `BetafyWrapperSimple` - the easiest way to integrate the SDK:

```dart
BetafyWrapperSimple(
  sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
  child: MaterialApp(...),
)
```

**Features:**
- ✅ Automatic claim code screen
- ✅ Automatic SDK initialization
- ✅ Handles all claim flow automatically
- ✅ Zero configuration needed

### Advanced Example (`main_claim_example.dart`)

Shows manual claim flow implementation:

```dart
// Check if claimed
final isClaimed = await TesterHeartbeatSDK.isClaimed();

// Verify claim code
final result = await TesterHeartbeatSDK.verifyClaimCode(
  claimCode,
  sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
);
```

**Features:**
- ✅ Custom claim UI
- ✅ Manual claim verification
- ✅ Full control over the flow

## 🎨 UI Features

The example app showcases a modern, minimal design:

- ✨ **Gradient backgrounds** with smooth color transitions
- 🎯 **Clean card-based layouts** with proper shadows
- 🔤 **Beautiful typography** with proper spacing and hierarchy
- 🎨 **Color-coded status indicators** (purple for active, green for success)
- ⚡ **Smooth animations** and transitions
- 📱 **Responsive design** that works on all screen sizes

## 🔧 Configuration

### Using Local Dependency

The example uses the SDK from the parent directory (local path):

```yaml
dependencies:
  tester_heartbeat_sdk:
    path: ../
```

This is the recommended approach for development and testing.

### For Production Apps

Use the SDK from GitHub or pub.dev:

```yaml
dependencies:
  tester_heartbeat_sdk:
    git:
      url: https://github.com/YOUR_USERNAME/betafy-sdk.git
      ref: main
```

### Firebase Setup

The SDK uses its own Firebase project (`betafy-2e207`) for backend operations. You don't need to configure anything - just provide `BetafyFirebaseOptions.currentPlatform`.

If your app also uses Firebase, initialize it separately:

```dart
// Your app's Firebase (optional)
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// SDK uses betafy-2e207 automatically
```

## 🧪 Testing

1. **Get a claim code** from the tester app (betafy)
2. **Run the example app**
3. **Enter the claim code** when prompted
4. **Verify** that the SDK is tracking

## 📚 More Information

- **[INTEGRATION_EXAMPLE.md](./INTEGRATION_EXAMPLE.md)** - Complete code examples for integrating the SDK
- **[INTEGRATION_GUIDE.md](../INTEGRATION_GUIDE.md)** - Detailed integration guide
- **[LOGIC.md](../LOGIC.md)** - How the claim flow works
- **[README.md](../README.md)** - SDK overview and features

## 🐛 Troubleshooting

### "SDK not found"
- Run `flutter pub get`
- Check GitHub repository access

### "Firebase not initialized"
- The SDK handles its own Firebase initialization
- Just provide `BetafyFirebaseOptions.currentPlatform`

### "Claim code invalid"
- Make sure the claim code is from the tester app
- Check that the code hasn't expired (30 minutes)
- Verify the code hasn't been used already
