# Fixing Deployment Issues

## 🔧 Issues Found

1. **Permission denied** - npm install failing
2. **tsc command not found** - TypeScript not installed
3. **No Firebase project** - Project not selected

---

## ✅ Solution Steps

### Step 1: Fix Permissions and Clean Install

```bash
cd betafy-sdk/firebase/functions

# Remove node_modules and lock file
rm -rf node_modules package-lock.json

# Fix permissions (if needed)
sudo chown -R $(whoami) ~/.npm

# Install dependencies with clean cache
npm cache clean --force
npm install
```

### Step 2: Verify TypeScript Installation

```bash
# Check if TypeScript is installed
npx tsc --version

# If not found, install globally or use npx
npm install -g typescript
# OR use npx (recommended)
npx tsc --version
```

### Step 3: Set Firebase Project

```bash
# List available projects
firebase projects:list

# Set active project
firebase use <your-project-id>

# OR add project
firebase use --add
# Then select your project from the list
```

### Step 4: Build and Deploy

```bash
# Build TypeScript
npm run build
# OR if tsc not found globally:
npx tsc

# Deploy functions
firebase deploy --only functions
```

---

## 🚀 Complete Fix Script

Run these commands in order:

```bash
cd betafy-sdk/firebase/functions

# 1. Clean install
rm -rf node_modules package-lock.json
npm cache clean --force
npm install

# 2. Verify TypeScript
npx tsc --version

# 3. Set Firebase project
firebase use <your-project-id>
# OR
firebase use --add

# 4. Build
npx tsc

# 5. Deploy
firebase deploy --only functions
```

---

## 🔍 Alternative: Use npx for Everything

If you continue having issues, use `npx` to run commands:

```bash
# Install dependencies
npm install

# Build using npx
npx tsc

# Deploy
firebase deploy --only functions
```

---

## 📝 Update package.json Scripts

You can update `package.json` to use npx:

```json
{
  "scripts": {
    "build": "npx tsc",
    "lint": "npx eslint --ext .ts src",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "npm run build && firebase deploy --only functions"
  }
}
```

---

## 🐛 If Issues Persist

### Permission Issues
```bash
# Fix npm permissions
sudo chown -R $(whoami) ~/.npm
sudo chown -R $(whoami) node_modules
```

### TypeScript Not Found
```bash
# Install TypeScript locally
npm install --save-dev typescript

# Then use npx
npx tsc
```

### Firebase Project Issues
```bash
# Check if you're logged in
firebase login

# List projects
firebase projects:list

# Initialize if needed (in parent directory)
cd ../..
firebase init functions
```

---

## ✅ Quick Fix Commands

Copy and paste these:

```bash
cd betafy-sdk/firebase/functions
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
npx tsc
firebase use <your-project-id>
firebase deploy --only functions
```

Replace `<your-project-id>` with your actual Firebase project ID.

