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
exports.logHeartbeat = void 0;
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
    if (deviceMismatch) {
        await testerRef.set({
            locked: true,
            suspiciousDevice: data.deviceId,
            lastSessionId: data.sessionId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return {
            completed: false,
            multiAccountDetected: true,
            deviceMismatch: true,
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
