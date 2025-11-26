# 🚀 Deployment Guide

## ✅ Configuration Complete

Your `firebase.json` has been updated with the correct functions configuration:

```json
{
  "functions": {
    "source": "firebase/functions",
    "predeploy": [
      "npm --prefix \"$RESOURCE_DIR\" run build"
    ]
  },
  "firestore": {
    "rules": "firebase/firestore.rules"
  }
}
```

## 📋 Pre-Deployment Checklist

### 1. **Upgrade Firebase Plan** ⚠️ REQUIRED

Cloud Functions require the **Blaze (pay-as-you-go) plan**:

1. Go to [Firebase Console](https://console.firebase.google.com/project/betafy-2e207/settings/plan)
2. Click **"Upgrade to Blaze"**
3. Note: Blaze plan has a **free tier** - you won't be charged unless you exceed free limits
4. Free tier includes:
   - 2 million Cloud Function invocations/month
   - 400,000 GB-seconds of compute time/month
   - 5 GB Firestore storage

### 2. **Enable Required Services**

After upgrading, enable these in Firebase Console:

- ✅ **Authentication** → Enable "Anonymous" sign-in method
- ✅ **Firestore Database** → Create database in "Native mode"
- ✅ **Cloud Functions** → Already configured (will be enabled automatically)

## 🚀 Deployment Commands

### Deploy Firestore Rules

```bash
cd /Users/cvsuhail/Desktop/betafy
firebase deploy --only firestore:rules
```

### Deploy Cloud Function

```bash
cd /Users/cvsuhail/Desktop/betafy
firebase deploy --only functions:logHeartbeat
```

Or deploy all functions:

```bash
firebase deploy --only functions
```

### Deploy Everything

```bash
firebase deploy
```

## 🔍 Verify Deployment

### Check Functions

```bash
firebase functions:list
```

You should see:
```
logHeartbeat
```

### Test the Function

You can test the function using the Firebase Console:
1. Go to [Functions](https://console.firebase.google.com/project/betafy-2e207/functions)
2. Click on `logHeartbeat`
3. Use the "Test" tab to send a test payload

### Test from Flutter App

```bash
cd example
flutter run
```

The app will automatically:
1. Initialize Firebase
2. Sign in anonymously
3. Send heartbeat on app open
4. Call the `logHeartbeat` Cloud Function

## 📝 Function Details

**Function Name**: `logHeartbeat`  
**Type**: HTTPS Callable  
**Location**: `firebase/functions/src/index.ts`

**What it does**:
- Validates tester assignment to gig
- Checks for device/install ID mismatches (anti-abuse)
- Stores heartbeat data in Firestore
- Tracks 14-day streaks
- Returns completion status

## 🐛 Troubleshooting

### Error: "Blaze plan required"
**Solution**: Upgrade your Firebase project to Blaze plan (free tier available)

### Error: "Function not found"
**Solution**: Make sure you deployed the function:
```bash
firebase deploy --only functions:logHeartbeat
```

### Error: "Authentication required"
**Solution**: Enable Anonymous authentication in Firebase Console

### Error: "Tester not assigned to gig"
**Solution**: Create a tester document in Firestore:
```
/gigs/{gigId}/testers/{testerId}
```

### Error: "Missing API"
**Solution**: The APIs will be enabled automatically when you deploy. If errors persist, enable manually:
- Cloud Functions API
- Cloud Build API
- Artifact Registry API

## 📊 Firestore Structure

After deployment, your Firestore will have this structure:

```
/gigs/{gigId}/
  └─> /testers/{testerId}/
      ├─> deviceId: string
      ├─> installId: string
      ├─> lastSessionId: string
      ├─> lastSeen: timestamp
      ├─> isEmulator: boolean
      ├─> locked: boolean
      └─> /days/{date}/
          ├─> opens: number
          ├─> timestamps: array<string>
          └─> lastUpdated: timestamp
```

## 🎯 Next Steps

1. ✅ Upgrade to Blaze plan
2. ✅ Enable Anonymous authentication
3. ✅ Create Firestore database
4. ✅ Deploy Firestore rules
5. ✅ Deploy Cloud Function
6. ✅ Test with example app
7. ✅ Create test gig/tester in Firestore

## 💡 Creating Test Data

To test the function, create a tester in Firestore:

```bash
# Using Firebase CLI
firebase firestore:set /gigs/GIG123/testers/USER123 \
  '{"deviceId":"","installId":"","locked":false}'
```

Or use the Firebase Console:
1. Go to Firestore Database
2. Start collection: `gigs`
3. Document ID: `GIG123`
4. Add subcollection: `testers`
5. Document ID: `USER123`
6. Add fields: `deviceId` (string, empty), `installId` (string, empty), `locked` (boolean, false)

---

**Status**: ✅ Configuration ready, waiting for Blaze plan upgrade

