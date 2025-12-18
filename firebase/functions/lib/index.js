"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyClaimCode = exports.logHeartbeat = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
admin.initializeApp();
const db = admin.firestore();
exports.logHeartbeat = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    validatePayload(data);
    const { gigId, testerId } = data;
    const testerRef = db.doc(`gigs/${gigId}/testers/${testerId}`);
    const testerSnap = await testerRef.get();
    if (!testerSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Tester not assigned to gig');
    }
    const testerData = testerSnap.data() || {};
    const deviceMismatch = (testerData.deviceId && testerData.deviceId !== data.deviceId) ||
        (testerData.installId && testerData.installId !== data.installId);
    // ENHANCED: Check if deviceId is used by another tester IN THIS GIG
    let multiAccountDetected = false;
    if (deviceMismatch) {
        // Device/install changed for this tester
        multiAccountDetected = true;
    }
    else {
        // Check if this deviceId is used by another tester in THIS SPECIFIC GIG
        const gigDeviceCheck = await db
            .collection('gigs')
            .doc(gigId)
            .collection('testers')
            .where('deviceId', '==', data.deviceId)
            .get();
        const otherTestersInGig = gigDeviceCheck.docs.filter(doc => doc.id !== testerId);
        if (otherTestersInGig.length > 0) {
            // Another tester is using this device in the same gig - MULTI-ACCOUNT DETECTED
            multiAccountDetected = true;
        }
    }
    if (deviceMismatch || multiAccountDetected) {
        await testerRef.set({
            locked: true,
            suspiciousDevice: data.deviceId,
            lastSessionId: data.sessionId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            multiAccountDetected: true,
        }, { merge: true });
        // Update device tracking
        await db.collection('devices').doc(data.deviceId).set({
            testerIds: admin.firestore.FieldValue.arrayUnion(testerId),
            flagged: true,
            flaggedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return {
            completed: false,
            multiAccountDetected: true,
            deviceMismatch: deviceMismatch,
        };
    }
    await testerRef.set({
        deviceId: data.deviceId,
        installId: data.installId,
        lastSessionId: data.sessionId,
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        isEmulator: data.isEmulator,
        locked: testerData.locked ?? false,
    }, { merge: true });
    // Update global device tracking
    await db.collection('devices').doc(data.deviceId).set({
        testerIds: admin.firestore.FieldValue.arrayUnion(testerId),
        gigIds: admin.firestore.FieldValue.arrayUnion(gigId),
        lastUsed: admin.firestore.FieldValue.serverTimestamp(),
        packageName: data.device?.appPackageName || '',
    }, { merge: true });
    const today = new Date();
    const dateKey = today.toISOString().slice(0, 10);
    const dayRef = testerRef.collection('days').doc(dateKey);
    await dayRef.set({
        opens: admin.firestore.FieldValue.increment(data.timestamps.length),
        timestamps: admin.firestore.FieldValue.arrayUnion(...data.timestamps),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    const completed = await hasFourteenDayStreak(testerRef);
    return {
        completed,
        multiAccountDetected: false,
        deviceMismatch: false,
    };
});
function validatePayload(data) {
    const required = [
        'gigId',
        'testerId',
        'deviceId',
        'installId',
        'sessionId',
        'timestamps',
        'isEmulator',
    ];
    for (const key of required) {
        if (data[key] === undefined) {
            throw new functions.https.HttpsError('invalid-argument', `Missing field ${key}`);
        }
    }
}
async function hasFourteenDayStreak(testerRef) {
    const cutoff = new Date();
    cutoff.setUTCDate(cutoff.getUTCDate() - 13);
    const snaps = await testerRef
        .collection('days')
        .orderBy('lastUpdated', 'desc')
        .limit(14)
        .get();
    if (snaps.size < 14) {
        return false;
    }
    const sorted = snaps.docs
        .map((doc) => ({
        date: new Date(doc.id),
        opens: doc.get('opens') ?? 0,
    }))
        .sort((a, b) => a.date.getTime() - b.date.getTime());
    for (let i = 0; i < 14; i++) {
        const day = sorted[i];
        if (day.opens <= 0) {
            return false;
        }
        const expected = new Date(cutoff);
        expected.setUTCDate(cutoff.getUTCDate() + i);
        const sameDay = day.date.getUTCFullYear() === expected.getUTCFullYear() &&
            day.date.getUTCMonth() === expected.getUTCMonth() &&
            day.date.getUTCDate() === expected.getUTCDate();
        if (!sameDay) {
            return false;
        }
    }
    return true;
}
exports.verifyClaimCode = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    const { claimCode, installId, deviceId, packageName, isEmulator } = data;
    if (!claimCode || !installId || !deviceId || !packageName) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: claimCode, installId, deviceId, packageName');
    }
    // Look up claim code
    const claimDoc = await db.collection('claimCodes').doc(claimCode).get();
    if (!claimDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Invalid claim code');
    }
    const claimData = claimDoc.data();
    const { gigId, testerId, used, expiresAt } = claimData;
    // Check if already used
    if (used === true) {
        throw new functions.https.HttpsError('failed-precondition', 'Claim code has already been used');
    }
    // Check if expired
    const expiresAtDate = expiresAt.toDate();
    if (new Date() > expiresAtDate) {
        throw new functions.https.HttpsError('deadline-exceeded', 'Claim code has expired');
    }
    // Verify package name matches
    if (claimData.packageName !== packageName) {
        throw new functions.https.HttpsError('permission-denied', 'Claim code is not valid for this app package');
    }
    // Check if installId is already bound to another tester
    const installsSnapshot = await db
        .collection('gigs')
        .doc(gigId)
        .collection('testers')
        .where('installId', '==', installId)
        .limit(1)
        .get();
    if (!installsSnapshot.empty) {
        const existingTester = installsSnapshot.docs[0];
        if (existingTester.id !== testerId) {
            throw new functions.https.HttpsError('already-exists', 'This install is already bound to another tester');
        }
    }
    // PREVENT MULTIPLE ACCOUNTS ON SAME DEVICE FOR SAME GIG
    // Rule: Same tester can join multiple gigs, but multiple testers cannot join same gig on same device
    // Check if deviceId is already used by another tester in THIS SPECIFIC GIG
    const deviceCheckSnapshot = await db
        .collection('gigs')
        .doc(gigId)
        .collection('testers')
        .where('deviceId', '==', deviceId)
        .limit(1)
        .get();
    if (!deviceCheckSnapshot.empty) {
        const existingTesterWithDevice = deviceCheckSnapshot.docs[0];
        if (existingTesterWithDevice.id !== testerId) {
            // Device already used by another tester in THIS GIG - PREVENT CLAIM
            throw new functions.https.HttpsError('permission-denied', 'This device is already being used by another tester account for this gig. Only one account per device per gig is allowed.');
        }
        // Same tester, same device, same gig - this is a re-claim, allow it
    }
    // Get tester document
    const testerRef = db.doc(`gigs/${gigId}/testers/${testerId}`);
    const testerSnap = await testerRef.get();
    if (!testerSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Tester not found in gig');
    }
    // Update tester with install binding
    await testerRef.set({
        installId: installId,
        deviceId: deviceId,
        isEmulator: isEmulator,
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        packageName: packageName,
    }, { merge: true });
    // Mark claim code as used
    await db.collection('claimCodes').doc(claimCode).update({
        used: true,
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
        usedByInstallId: installId,
    });
    // Store install binding for quick lookup
    await db.collection('installs').doc(installId).set({
        gigId: gigId,
        testerId: testerId,
        deviceId: deviceId,
        packageName: packageName,
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    // Track device globally (for monitoring, not prevention across gigs)
    // Same tester can use same device for multiple gigs
    await db.collection('devices').doc(deviceId).set({
        testerIds: admin.firestore.FieldValue.arrayUnion(testerId),
        gigIds: admin.firestore.FieldValue.arrayUnion(gigId),
        lastUsed: admin.firestore.FieldValue.serverTimestamp(),
        packageName: packageName,
        // Track per-gig usage for monitoring
        [`gig_${gigId}_tester`]: testerId,
    }, { merge: true });
    return {
        success: true,
        gigId: gigId,
        testerId: testerId,
    };
});
