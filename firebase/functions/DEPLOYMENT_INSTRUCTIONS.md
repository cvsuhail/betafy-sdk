# Cloud Functions Deployment Instructions

## 📦 Complete Cloud Functions Code

This directory contains all the code needed to deploy Cloud Functions to Firebase.

---

## 📁 File Structure

```
firebase/functions/
├── src/
│   └── index.ts          # Main functions code
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript config
└── lib/                  # Compiled JS (auto-generated)
```

---

## 🚀 Quick Deployment

### Step 1: Navigate to Functions Directory

```bash
cd betafy-sdk/firebase/functions
```

### Step 2: Install Dependencies

```bash
npm install
```

### Step 3: Build TypeScript

```bash
npm run build
```

### Step 4: Deploy to Firebase

```bash
firebase deploy --only functions
```

This deploys both functions:
- `logHeartbeat` - Tracks tester heartbeats
- `verifyClaimCode` - Verifies claim codes

---

## 📋 Functions Included

### 1. `logHeartbeat`
**Purpose**: Tracks tester app opens and usage

**Input**:
```typescript
{
  gigId: string;
  testerId: string;
  deviceId: string;
  installId: string;
  sessionId: string;
  timestamps: string[];
  isEmulator: boolean;
}
```

**Output**:
```typescript
{
  completed: boolean;        // 14-day streak completed
  multiAccountDetected: boolean;
  deviceMismatch: boolean;
}
```

**Features**:
- Tracks daily app opens
- Detects multi-account abuse (per-gig)
- Validates device binding
- Calculates 14-day streak
- Flags suspicious activity

### 2. `verifyClaimCode`
**Purpose**: Verifies claim codes and binds installs to testers

**Input**:
```typescript
{
  claimCode: string;
  installId: string;
  deviceId: string;
  packageName: string;
  isEmulator: boolean;
}
```

**Output**:
```typescript
{
  success: boolean;
  gigId: string;
  testerId: string;
}
```

**Features**:
- Validates claim code (exists, not expired, not used)
- Verifies package name
- Prevents multiple accounts in same gig on same device
- Binds installId to testerId
- Tracks device usage

---

## 🔧 Configuration Files

### package.json
```json
{
  "name": "tester-heartbeat-functions",
  "version": "0.1.0",
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "lint": "eslint --ext .ts src",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "npm run build && firebase deploy --only functions"
  },
  "engines": {
    "node": "20"
  },
  "dependencies": {
    "firebase-admin": "^12.6.0",
    "firebase-functions": "^5.0.1"
  },
  "devDependencies": {
    "@types/node": "^22.7.4",
    "eslint": "^9.12.0",
    "firebase-functions-test": "^3.1.1",
    "typescript": "^5.6.2"
  }
}
```

### tsconfig.json
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017"
  },
  "compileOnSave": true,
  "include": [
    "src"
  ]
}
```

---

## 🧪 Testing Locally

### Start Emulators

```bash
npm run serve
```

This will:
1. Build TypeScript
2. Start Firebase emulators
3. Functions available at `http://localhost:5001`

### Test Functions

You can test using the Firebase console or your Flutter app pointing to emulators.

---

## 📊 Firestore Collections Used

Functions interact with these collections:

### `/gigs/{gigId}/testers/{testerId}`
- Stores tester data
- Tracks deviceId, installId
- Stores daily heartbeat data

### `/gigs/{gigId}/testers/{testerId}/days/{date}`
- Daily heartbeat records
- Opens count, timestamps

### `/claimCodes/{claimCode}`
- Claim code data
- Expiry, usage status

### `/installs/{installId}`
- Install bindings
- Links installId to testerId

### `/devices/{deviceId}`
- Global device tracking
- Multi-account prevention

---

## 🔐 Security

### Authentication
- Functions require anonymous authentication
- Enable in Firebase Console: Authentication → Sign-in method → Anonymous

### Firestore Rules
- Functions use admin SDK (bypasses rules)
- Client apps should use callable functions only
- Direct writes should be restricted

---

## 🐛 Troubleshooting

### Error: "Functions did not deploy"
- Check Firebase CLI is installed: `firebase --version`
- Check you're logged in: `firebase login`
- Check project is selected: `firebase use <project-id>`

### Error: "Module not found"
- Run `npm install` again
- Check `package.json` dependencies

### Error: "TypeScript compilation failed"
- Check `tsconfig.json` is correct
- Run `npm run build` to see errors

### Error: "Function timeout"
- Functions have default 60s timeout
- Increase if needed in function definition

---

## 📈 Monitoring

### View Logs
```bash
firebase functions:log
```

### View Specific Function Logs
```bash
firebase functions:log --only logHeartbeat
firebase functions:log --only verifyClaimCode
```

### Firebase Console
- Go to Functions section
- View execution logs, errors, metrics

---

## 🔄 Updating Functions

### After Making Changes

1. **Edit code** in `src/index.ts`
2. **Build**: `npm run build`
3. **Deploy**: `firebase deploy --only functions`

### Deploy Specific Function

```bash
firebase deploy --only functions:logHeartbeat
firebase deploy --only functions:verifyClaimCode
```

---

## ✅ Deployment Checklist

- [ ] Firebase CLI installed
- [ ] Logged into Firebase: `firebase login`
- [ ] Project selected: `firebase use <project-id>`
- [ ] Dependencies installed: `npm install`
- [ ] TypeScript compiles: `npm run build`
- [ ] Functions deploy: `firebase deploy --only functions`
- [ ] Functions appear in Firebase Console
- [ ] Test with Flutter app

---

## 📝 Notes

- Functions use Node.js 20
- TypeScript is compiled to JavaScript in `lib/` folder
- Don't edit files in `lib/` - they're auto-generated
- Always run `npm run build` before deploying
- Check logs if functions aren't working

---

## 🎯 Quick Commands

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Lint code
npm run lint

# Test locally
npm run serve

# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:logHeartbeat

# View logs
firebase functions:log
```

---

Your Cloud Functions are ready to deploy! 🚀

