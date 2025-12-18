## 🔍 How Claim Flow Identifies Testers

### Simple Explanation

**Problem**: How do we know which tester is using which app install?

**Solution**: Post-install claim flow with claim codes.

### The Flow

```
┌─────────────────────────────────────────────────┐
│ 1. TESTER JOINS GIG (Tester App)               │
└─────────────────────────────────────────────────┘
    ↓
    Tester clicks "Join Gig"
    ↓
    Backend generates unique claim code: "A9K3-ZP2Q"
    ↓
    Code stored in betafy-2e207:
    /claimCodes/A9K3-ZP2Q
      - gigId: "gig123"
      - testerId: "tester456"
      - packageName: "com.example.app"
      - expiresAt: 30 minutes
    ↓
    Tester sees code in tester app

┌─────────────────────────────────────────────────┐
│ 2. TESTER INSTALLS YOUR APP                    │
└─────────────────────────────────────────────────┘
    ↓
    Tester installs via Play Store
    ↓
    Opens your app
    ↓
    SDK checks: Is this install claimed?
    ↓
    NO → Shows claim code screen

┌─────────────────────────────────────────────────┐
│ 3. TESTER ENTERS CLAIM CODE                    │
└─────────────────────────────────────────────────┘
    ↓
    Tester enters "A9K3-ZP2Q"
    ↓
    SDK sends to betafy-2e207:
    {
      claimCode: "A9K3-ZP2Q",
      installId: "install-xyz",  // Unique per install
      deviceId: "device-abc",
      packageName: "com.example.app"
    }
    ↓
    Backend verifies:
    - Code exists? ✅
    - Not expired? ✅
    - Not used? ✅
    - Package matches? ✅
    ↓
    Backend binds:
    installId → testerId → gigId
    ↓
    Stores in betafy-2e207:
    /installs/install-xyz
      - testerId: "tester456"
      - gigId: "gig123"
    ↓
    SDK stores locally:
    "gig123|tester456" in SharedPreferences

┌─────────────────────────────────────────────────┐
│ 4. TRACKING STARTS                              │
└─────────────────────────────────────────────────┘
    ↓
    Every app open:
    SDK sends heartbeat to betafy-2e207:
    {
      gigId: "gig123",      // From local storage
      testerId: "tester456", // From local storage
      installId: "install-xyz",
      deviceId: "device-abc",
      timestamps: [...]
    }
    ↓
    Backend stores in betafy-2e207:
    /gigs/gig123/testers/tester456/days/2024-01-15
      - opens: 5
      - timestamps: [...]
```

### Key Points

1. **Claim Code = Link**
   - Connects tester account to app install
   - Generated when tester joins gig
   - Expires in 30 minutes

2. **Install ID = Unique Identifier**
   - Generated once per app install
   - Stored permanently on device
   - Used to identify this specific install

3. **Binding = Connection**
   - `installId` → `testerId` → `gigId`
   - Stored in betafy-2e207
   - Also stored locally on device

4. **Tracking = Using Binding**
   - SDK reads local binding (gigId, testerId)
   - Sends with every heartbeat
   - Backend knows which tester is using which install

### Why This Works

- ✅ **Play Store Compliant**: No deep linking hacks
- ✅ **User Consent**: Tester explicitly enters code
- ✅ **Reliable**: Works even if app opened from launcher
- ✅ **Secure**: Code expires, one-time use
- ✅ **Trackable**: All data linked to tester account

### Data Storage

**In betafy-2e207:**
```
/claimCodes/{claimCode}
  - gigId, testerId, packageName, expiresAt

/installs/{installId}
  - testerId, gigId, deviceId

/gigs/{gigId}/testers/{testerId}/days/{date}
  - opens, timestamps (heartbeat data)
```

**On Device (SharedPreferences):**
```
"gig123|tester456"  // Simple binding storage
```

**Result**: Every heartbeat knows which tester sent it!

---

## 🎨 Optional: Customization

### Handle Callbacks

```dart
BetafyWrapperSimple(
  onEmulatorDetected: () {
    print('Emulator detected');
  },
  onMultiAccountDetected: () {
    print('Abuse detected');
  },
  sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
  child: MaterialApp(...),
)
```

### Custom Claim Screen

```dart
BetafyWrapperSimple(
  claimScreen: (context, onClaim) {
    return MyCustomClaimScreen(onClaim: onClaim);
  },
  sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform,
  child: MaterialApp(...),
)
```

---

## 🐛 Common Issues

### "Cloud Function not found"
- Check internet connection
- Verify `sdkFirebaseOptions` is provided

### "Firebase already initialized"
```dart
if (Firebase.apps.isEmpty) {
  await Firebase.initializeApp(...);
}
```

### "SDK not working"
- Ensure `sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform` is provided
- Check internet connection

---

## 📋 Checklist

- [ ] Added SDK dependency
- [ ] Ran `flutter pub get`
- [ ] Firebase initialized
- [ ] Wrapped app with `BetafyWrapperSimple`
- [ ] Added `sdkFirebaseOptions: BetafyFirebaseOptions.currentPlatform`

---

## 🎯 Summary

**Just 3 steps:**
1. Add dependency
2. Initialize Firebase (your existing code)
3. Wrap app with `BetafyWrapperSimple` + `sdkFirebaseOptions`

**Result:**
- ✅ SDK tracks testers automatically
- ✅ Data goes to betafy-2e207
- ✅ Your app works normally
- ✅ No conflicts

---

**That's it! Your app is integrated.** 🚀

For more details, see:
- [SIMPLE_SETUP.md](./SIMPLE_SETUP.md) - More examples
- [HOW_IT_WORKS_DIFFERENT_FIREBASE.md](./HOW_IT_WORKS_DIFFERENT_FIREBASE.md) - Architecture details
