// Firebase options for betafy-sdk backend (betafy-2e207)
// Use this when your app uses a different Firebase project

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for betafy-sdk backend project (betafy-2e207).
/// 
/// Use this when integrating SDK in apps that use a different Firebase project.
/// 
/// Example:
/// ```dart
/// BetafyWrapperSimple(
///   sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
///   child: MyApp(),
/// )
/// ```
class BetafyFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'BetafyFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'BetafyFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'BetafyFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'BetafyFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'BetafyFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDtVtwkl7vzS_NtHSu-t4VLAvLots801k',
    appId: '1:20529395804:android:5c60e663e8a262a0f1ce99',
    messagingSenderId: '20529395804',
    projectId: 'betafy-2e207',
    storageBucket: 'betafy-2e207.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCDtVtwkl7vzS_NtHSu-t4VLAvLots801k',
    appId: '1:20529395804:ios:5c807c956e6e40ddf1ce99',
    messagingSenderId: '20529395804',
    projectId: 'betafy-2e207',
    storageBucket: 'betafy-2e207.firebasestorage.app',
    iosBundleId: 'com.awwads.betafy',
  );
}

