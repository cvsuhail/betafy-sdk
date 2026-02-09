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
    // First, get the gig document to check if testers are stored as a map
    const gigRef = db.doc(`gigs/${gigId}`);
    const gigSnap = await gigRef.get();
    if (!gigSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Gig not found');
    }
    const gigData = gigSnap.data() || {};
    const testersMap = gigData.testers || {};
    // Check if tester exists in the gig's testers map
    let testerData = null;
    let testerExistsInMap = false;
    if (testersMap && typeof testersMap === 'object' && testersMap[testerId]) {
        testerData = testersMap[testerId];
        testerExistsInMap = true;
    }
    // Also check subcollection for backward compatibility
    const testerRef = db.doc(`gigs/${gigId}/testers/${testerId}`);
    const testerSnap = await testerRef.get();
    if (!testerExistsInMap && !testerSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Tester not assigned to gig');
    }
    // Get tester data from subcollection if map doesn't have it
    if (!testerExistsInMap && testerSnap.exists) {
        testerData = testerSnap.data() || {};
    }
    else if (testerExistsInMap && testerSnap.exists) {
        // Merge both sources, subcollection takes precedence for device info
        const subcollectionData = testerSnap.data() || {};
        testerData = { ...testerData, ...subcollectionData };
    }
    const deviceMismatch = (testerData.deviceId && testerData.deviceId !== data.deviceId) ||
        (testerData.installId && testerData.installId !== data.installId);
    // ENHANCED: Check if deviceId is used by another tester IN THIS GIG
    let multiAccountDetected = false;
    // Check in testers map first
    if (testersMap && typeof testersMap === 'object') {
        for (const [otherTesterId, otherTesterData] of Object.entries(testersMap)) {
            if (otherTesterId !== testerId && otherTesterData && typeof otherTesterData === 'object') {
                const otherTester = otherTesterData;
                if (otherTester.deviceId === data.deviceId) {
                    multiAccountDetected = true;
                    break;
                }
            }
        }
    }
    // Also check subcollection
    if (!multiAccountDetected) {
        const gigDeviceCheck = await db
            .collection('gigs')
            .doc(gigId)
            .collection('testers')
            .where('deviceId', '==', data.deviceId)
            .get();
        const otherTestersInGig = gigDeviceCheck.docs.filter(doc => doc.id !== testerId);
        if (otherTestersInGig.length > 0) {
            multiAccountDetected = true;
        }
    }
    if (deviceMismatch) {
        multiAccountDetected = true;
    }
    // Prepare updated tester data
    const updatedTesterData = {
        deviceId: data.deviceId,
        installId: data.installId,
        lastSessionId: data.sessionId,
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        isEmulator: data.isEmulator,
        locked: testerData.locked ?? false,
        ...(multiAccountDetected ? {
            locked: true,
            suspiciousDevice: data.deviceId,
            multiAccountDetected: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        } : {}),
    };
    // Update tester in the gig's testers map
    if (testerExistsInMap) {
        const updatedTestersMap = {
            ...testersMap,
            [testerId]: {
                ...testerData,
                ...updatedTesterData,
                // Update daily stats
                totalOpenCount: (testerData.totalOpenCount || 0) + data.timestamps.length,
                lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
            }
        };
        await gigRef.update({
            testers: updatedTestersMap,
            updatedDate: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    // Also update/create subcollection document for backward compatibility
    await testerRef.set(updatedTesterData, { merge: true });
    // Update device tracking
    await db.collection('devices').doc(data.deviceId).set({
        testerIds: admin.firestore.FieldValue.arrayUnion(testerId),
        gigIds: admin.firestore.FieldValue.arrayUnion(gigId),
        lastUsed: admin.firestore.FieldValue.serverTimestamp(),
        packageName: data.device?.appPackageName || '',
        ...(multiAccountDetected ? {
            flagged: true,
            flaggedAt: admin.firestore.FieldValue.serverTimestamp(),
        } : {}),
    }, { merge: true });
    // Update daily heartbeat tracking in subcollection (for streak calculation)
    const today = new Date();
    const dateKey = today.toISOString().slice(0, 10);
    const dayRef = testerRef.collection('days').doc(dateKey);
    // Get existing day data
    const daySnap = await dayRef.get();
    const existingDayData = daySnap.exists ? (daySnap.data() || {}) : {};
    const existingOpens = existingDayData.opens || 0;
    const existingTimestamps = existingDayData.timestamps || [];
    await dayRef.set({
        opens: existingOpens + data.timestamps.length,
        timestamps: admin.firestore.FieldValue.arrayUnion(...data.timestamps),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        date: dateKey,
        usageDuration: existingDayData.usageDuration || 0,
        deviceSnapshot: testerData.deviceSnapshot || data.device || {},
    }, { merge: true });
    // Also update the day in the testers map if it exists
    if (testerExistsInMap && testerData.days) {
        const updatedDays = { ...testerData.days };
        if (!updatedDays[dateKey]) {
            updatedDays[dateKey] = {
                date: dateKey,
                heartbeatCount: 0,
                openTimes: [],
                usageDuration: 0,
                deviceSnapshot: testerData.deviceSnapshot || data.device || {},
            };
        }
        updatedDays[dateKey] = {
            ...updatedDays[dateKey],
            heartbeatCount: (updatedDays[dateKey].heartbeatCount || 0) + data.timestamps.length,
            openTimes: [...(updatedDays[dateKey].openTimes || []), ...data.timestamps],
            deviceSnapshot: testerData.deviceSnapshot || data.device || {},
        };
        const updatedTestersMapWithDays = {
            ...testersMap,
            [testerId]: {
                ...testersMap[testerId],
                days: updatedDays,
            }
        };
        await gigRef.update({
            testers: updatedTestersMapWithDays,
        });
    }
    const completed = await hasFourteenDayStreak(testerRef);
    if (multiAccountDetected) {
        return {
            completed: false,
            multiAccountDetected: true,
            deviceMismatch: deviceMismatch,
        };
    }
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
    // Use transaction to prevent race conditions
    return await db.runTransaction(async (transaction) => {
        // Look up claim code
        const claimDocRef = db.collection('claimCodes').doc(claimCode);
        const claimDoc = await transaction.get(claimDocRef);
        if (!claimDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Invalid claim code');
        }
        const claimData = claimDoc.data();
        const { gigId, testerId, used, expiresAt } = claimData;
        // Check if already used (atomic check within transaction)
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
        // Get gig document to check testers map
        const gigRef = db.doc(`gigs/${gigId}`);
        const gigSnap = await transaction.get(gigRef);
        if (!gigSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Gig not found');
        }
        const gigData = gigSnap.data() || {};
        const testersMap = gigData.testers || {};
        // Check if installId is already bound to another tester in the map
        if (testersMap && typeof testersMap === 'object') {
            for (const [otherTesterId, otherTesterData] of Object.entries(testersMap)) {
                if (otherTesterId !== testerId && otherTesterData && typeof otherTesterData === 'object') {
                    const otherTester = otherTesterData;
                    if (otherTester.installId === installId) {
                        throw new functions.https.HttpsError('already-exists', 'This install is already bound to another tester');
                    }
                }
            }
        }
        // Also check subcollection for backward compatibility
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
        // Check if deviceId is already used by another tester in THIS SPECIFIC GIG
        // First check in map
        if (testersMap && typeof testersMap === 'object') {
            for (const [otherTesterId, otherTesterData] of Object.entries(testersMap)) {
                if (otherTesterId !== testerId && otherTesterData && typeof otherTesterData === 'object') {
                    const otherTester = otherTesterData;
                    if (otherTester.deviceId === deviceId) {
                        throw new functions.https.HttpsError('permission-denied', 'This device is already being used by another tester account for this gig. Only one account per device per gig is allowed.');
                    }
                }
            }
        }
        // Also check subcollection
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
                throw new functions.https.HttpsError('permission-denied', 'This device is already being used by another tester account for this gig. Only one account per device per gig is allowed.');
            }
        }
        // Get tester from map or subcollection
        let testerData = null;
        if (testersMap && typeof testersMap === 'object' && testersMap[testerId]) {
            testerData = testersMap[testerId];
        }
        const testerRef = db.doc(`gigs/${gigId}/testers/${testerId}`);
        const testerSnap = await transaction.get(testerRef);
        if (!testerData && !testerSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Tester not found in gig');
        }
        // Update tester with install binding in both map and subcollection
        const updatedTesterData = {
            installId: installId,
            deviceId: deviceId,
            isEmulator: isEmulator,
            claimedAt: admin.firestore.FieldValue.serverTimestamp(),
            packageName: packageName,
            status: 'active',
        };
        // Update in map
        if (testersMap && typeof testersMap === 'object') {
            const updatedTestersMap = {
                ...testersMap,
                [testerId]: {
                    ...(testerData || {}),
                    ...updatedTesterData,
                }
            };
            transaction.update(gigRef, {
                testers: updatedTestersMap,
                updatedDate: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        // Update/create subcollection document
        transaction.set(testerRef, updatedTesterData, { merge: true });
        // Mark claim code as used (atomic within transaction)
        transaction.update(claimDocRef, {
            used: true,
            usedAt: admin.firestore.FieldValue.serverTimestamp(),
            usedByInstallId: installId,
        });
        // Store install binding for quick lookup
        const installRef = db.collection('installs').doc(installId);
        transaction.set(installRef, {
            gigId: gigId,
            testerId: testerId,
            deviceId: deviceId,
            packageName: packageName,
            claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        // Track device globally (for monitoring, not prevention across gigs)
        const deviceRef = db.collection('devices').doc(deviceId);
        transaction.set(deviceRef, {
            testerIds: admin.firestore.FieldValue.arrayUnion(testerId),
            gigIds: admin.firestore.FieldValue.arrayUnion(gigId),
            lastUsed: admin.firestore.FieldValue.serverTimestamp(),
            packageName: packageName,
            [`gig_${gigId}_tester`]: testerId,
        }, { merge: true });
        return {
            success: true,
            gigId: gigId,
            testerId: testerId,
        };
    });
});
