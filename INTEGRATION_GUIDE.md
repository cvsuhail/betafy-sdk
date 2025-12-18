# Betafy SDK Integration Guide

Simple guide to integrate Betafy SDK in your Flutter app.

---

## 🚀 Quick Integration (3 Steps)

### Step 1: Add Dependency

```yaml
# pubspec.yaml
dependencies:
  tester_heartbeat_sdk:
    git:
      url: https://github.com/cvsuhail/betafy-sdk.git
      path: betafy-sdk
      ref: main
```

Run: `flutter pub get`

### Step 2: Initialize Your Firebase

```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

**Keep your existing Firebase initialization - no changes needed!**

### Step 3: Wrap Your App

```dart
// main.dart
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BetafyWrapperSimple(
      sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
      child: MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}
```

**That's it!** SDK is now tracking tester activity.

---

## 📱 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BetafyWrapperSimple(
      sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
      child: MaterialApp(
        title: 'My App',
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Center(child: Text('SDK is tracking!')),
    );
  }
}
```

---

## 🔥 How Firebase Works

### Your App
- Uses **your Firebase project** for app features
- No changes needed

### SDK
- Uses **betafy-2e207** for tracking
- Automatically handled by SDK
- All tester data goes to betafy-2e207

**Result**: Your app and SDK use different Firebase projects - no conflicts!

---

## ✅ What Happens

1. **App starts** → SDK checks if claimed
2. **If not claimed** → Shows claim code screen
3. **User enters code** → SDK verifies with betafy-2e207
4. **After claim** → App works normally
5. **On app open** → SDK sends heartbeat to betafy-2e207

---

