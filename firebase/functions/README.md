# Firebase Cloud Functions - Complete Package

## 📦 What's Included

This package contains all Cloud Functions needed for the Tester Heartbeat SDK:

1. **`logHeartbeat`** - Tracks tester app opens and usage
2. **`verifyClaimCode`** - Verifies claim codes and binds installs

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Build TypeScript
```bash
npm run build
```

### 3. Deploy to Firebase
```bash
firebase deploy --only functions
```

---

## 📁 Files

- **`src/index.ts`** - Complete functions code (see below)
- **`package.json`** - Dependencies and scripts
- **`tsconfig.json`** - TypeScript configuration

---

## 📋 Complete Functions Code

The complete code is in `src/index.ts`. See [DEPLOYMENT_INSTRUCTIONS.md](./DEPLOYMENT_INSTRUCTIONS.md) for detailed deployment steps.

---

## ✅ Functions Deployed

After deployment, you'll have:

- ✅ `logHeartbeat` - Callable function for tracking
- ✅ `verifyClaimCode` - Callable function for claim verification

Both functions are ready to use from your Flutter apps!

---

For detailed deployment instructions, see [DEPLOYMENT_INSTRUCTIONS.md](./DEPLOYMENT_INSTRUCTIONS.md)






