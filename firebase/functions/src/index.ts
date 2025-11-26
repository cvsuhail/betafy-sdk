import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();
const db = admin.firestore();

type HeartbeatPayload = {
  gigId: string;
  testerId: string;
  deviceId: string;
  installId: string;
  sessionId: string;
  timestamps: string[];
  isEmulator: boolean;
};

export const logHeartbeat = functions.https.onCall(
  async (data: HeartbeatPayload, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required'
      );
    }

    validatePayload(data);

    const { gigId, testerId } = data;
    const testerRef = db.doc(`gigs/${gigId}/testers/${testerId}`);
    const testerSnap = await testerRef.get();
    if (!testerSnap.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Tester not assigned to gig'
      );
    }

    const testerData = testerSnap.data() || {};
    const deviceMismatch =
      (testerData.deviceId && testerData.deviceId !== data.deviceId) ||
      (testerData.installId && testerData.installId !== data.installId);

    if (deviceMismatch) {
      await testerRef.set(
        {
          locked: true,
          suspiciousDevice: data.deviceId,
          lastSessionId: data.sessionId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return {
        completed: false,
        multiAccountDetected: true,
        deviceMismatch: true,
      };
    }

    await testerRef.set(
      {
        deviceId: data.deviceId,
        installId: data.installId,
        lastSessionId: data.sessionId,
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        isEmulator: data.isEmulator,
        locked: testerData.locked ?? false,
      },
      { merge: true }
    );

    const today = new Date();
    const dateKey = today.toISOString().slice(0, 10);
    const dayRef = testerRef.collection('days').doc(dateKey);
    await dayRef.set(
      {
        opens: admin.firestore.FieldValue.increment(data.timestamps.length),
        timestamps: admin.firestore.FieldValue.arrayUnion(...data.timestamps),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const completed = await hasFourteenDayStreak(testerRef);

    return {
      completed,
      multiAccountDetected: false,
      deviceMismatch: false,
    };
  }
);

function validatePayload(data: HeartbeatPayload) {
  const required: (keyof HeartbeatPayload)[] = [
    'gigId',
    'testerId',
    'deviceId',
    'installId',
    'sessionId',
    'timestamps',
    'isEmulator',
  ];

  for (const key of required) {
    if ((data as any)[key] === undefined) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Missing field ${key}`
      );
    }
  }
}

async function hasFourteenDayStreak(
  testerRef: FirebaseFirestore.DocumentReference
) {
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
    const sameDay =
      day.date.getUTCFullYear() === expected.getUTCFullYear() &&
      day.date.getUTCMonth() === expected.getUTCMonth() &&
      day.date.getUTCDate() === expected.getUTCDate();
    if (!sameDay) {
      return false;
    }
  }

  return true;
}

