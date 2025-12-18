# Betafy SDK Example App

This example demonstrates how to integrate the Betafy SDK into a Flutter app using GitHub dependency.

## 📋 Prerequisites

1. Flutter SDK installed
2. Firebase project set up (optional - for your app's Firebase)
3. Access to the betafy-sdk GitHub repository

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd example
flutter pub get
```

### 2. Run the Example

```bash
flutter run
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

## 🔧 Configuration

### Using GitHub Dependency

The example uses the SDK from GitHub:

```yaml
dependencies:
  tester_heartbeat_sdk:
    git:
      url: https://github.com/cvsuhail/betafy-sdk.git
      path: betafy-sdk
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

- See [INTEGRATION_GUIDE.md](../INTEGRATION_GUIDE.md) for complete integration guide
- See [LOGIC.md](../LOGIC.md) for how the claim flow works

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
