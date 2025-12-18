# tester_heartbeat_sdk

Flutter SDK for Play Store beta testing programs. It tracks tester heartbeats, prevents multi‑account abuse, and pushes usage analytics into Firebase.

## Features
- Device fingerprinting without MAC addresses (androidId / identifierForVendor + immutable installId)
- Automatic heartbeat on every app open with offline queue + retries
- Emulator detection + callbacks
- Multi-account detection via Firebase Cloud Function
- Firestore structure with 14-day streak tracking

## Quick Start

### 🚀 3 Simple Steps

**1. Add dependency:**
```yaml
dependencies:
  tester_heartbeat_sdk:
    git:
      url: https://github.com/your-username/betafy-sdk.git
      path: betafy-sdk
      ref: main
```

**2. Initialize Firebase (your existing code):**
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

**3. Wrap your app:**
```dart
BetafyWrapperSimple(
  sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
  child: MaterialApp(home: HomeScreen()),
)
```

**That's it!** See [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) for complete guide.

### Manual Setup (Advanced)

If you need more control:

1. Add the package:
   ```yaml
   dependencies:
     tester_heartbeat_sdk:
       path: ../tester_heartbeat_sdk
   ```

2. Initialize with claim mode:
   ```dart
   final status = await TesterHeartbeatSDK.initializeWithClaim(
     onEmulatorDetected: () {},
     onMultiAccountDetected: () {},
   );
   ```

3. Handle claim flow:
   ```dart
   if (status == ClaimStatus.unclaimed) {
     final result = await TesterHeartbeatSDK.verifyClaimCode(claimCode);
   }
   ```

See [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) for complete manual setup.

### For Direct Testing (Legacy Mode)

If you already have `gigId` and `testerId` available:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TesterHeartbeatSDK.initialize(
    gigId: 'GIG123',
    testerId: 'USER123',
    onEmulatorDetected: () {},
    onMultiAccountDetected: () {},
  );
  runApp(MyApp());
}
```

3. Optional manual heartbeat:
   ```dart
   await TesterHeartbeatSDK.sendHeartbeat();
   ```

## 📚 Documentation

### 🚀 Getting Started

- **[INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)** - ⭐ **Complete integration guide for other apps**
- **[SIMPLE_SETUP.md](./SIMPLE_SETUP.md)** - Quick 3-step setup guide
- **[GITHUB_INTEGRATION.md](./GITHUB_INTEGRATION.md)** - Add SDK from GitHub repository

### 📖 Detailed Guides

- **[HOW_IT_WORKS_DIFFERENT_FIREBASE.md](./HOW_IT_WORKS_DIFFERENT_FIREBASE.md)** - How SDK works with different Firebase projects
- **[CLAIM_FLOW_GUIDE.md](./CLAIM_FLOW_GUIDE.md)** - Detailed claim flow explanation
- **[MULTI_ACCOUNT_PREVENTION.md](./MULTI_ACCOUNT_PREVENTION.md)** - Multi-account prevention guide
- **[IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)** - Advanced implementation guide

## Firebase Setup
1. Create Firebase project and enable:
   - Authentication (Anonymous)
   - Firestore (native mode)
   - Cloud Functions
2. Run `flutterfire configure` to pull `firebase_options.dart`.
3. Deploy security rules (see `firebase/firestore.rules`):
   ```bash
   firebase deploy --only firestore:rules
   ```
4. Deploy Cloud Functions:
   ```bash
   cd firebase/functions
   npm install
   npm run lint
   firebase deploy --only functions
   ```
   
   This deploys both `logHeartbeat` and `verifyClaimCode` functions.

See [FIREBASE_QUICK_REFERENCE.md](./FIREBASE_QUICK_REFERENCE.md) for detailed Firebase setup.

## Firestore Structure
```
/gigs/{gigId}
  name: string
  active: bool
  testers/{testerId}
    deviceId
    installId
    locked: bool
    days/{yyyy-MM-dd}
      opens: number
      timestamps: array<string>
      lastUpdated: timestamp
```

## Security Rules Template
See `firebase/firestore.rules` for least-privilege read/writes scoped to the Cloud Function service account. Apps use callable functions only—direct writes are blocked.

## Analytics Dashboard
Aggregate on `/gigs/{gigId}/testers/{testerId}/days`. Plot `opens` per day and derive 14-day streak status using `completed` flag from the Cloud Function.

## Example App
`example/` shows a minimal Flutter app that initializes the SDK and provides a manual heartbeat button for QA.

## Testing
- `test/heartbeat_service_test.dart` contains starter tests with mocktail.
- Run `flutter test`.

## Cloud Function Overview
Input payload:
```json
{
  "gigId": "GIG123",
  "testerId": "USER123",
  "deviceId": "device-abc",
  "installId": "install-uuid",
  "sessionId": "session-uuid",
  "timestamps": ["2024-01-01T00:00:00Z"],
  "isEmulator": false
}
```
Function validates gig assignment, ensures device binding, records heartbeat document, and returns `{ "completed": true }` when streak reaches 14 continuous days.
<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
