// functions/index.js
//
// Cloud Functions for Cecelia Care.
//
// Triggers:
//   onTaskCreated      — pushes FCM to the assignee when a careTask is created.
//
// Callable (family invite flow):
//   createInviteCode   — admin generates a short code for an elder profile.
//   redeemInviteCode   — recipient trades a code for caregiver/viewer access.
//   revokeInviteCode   — admin (or code creator) disables an unused code.
//
// Notes for the invite flow:
//   • Codes are stored at `inviteCodes/{CODE}` with the doc id AS the code.
//     Top-level collection + doc-id lookup means redemption is one O(1)
//     read against a public collection — clients have get() allowed so
//     the redemption UI can display "You've been invited to help care
//     for Helen" BEFORE committing. Writes are denied to clients and
//     happen exclusively here.
//   • Codes exclude ambiguous chars (0/O, 1/I/L) so people don't misread
//     them over the phone.
//   • Default TTL: 14 days. Default maxUses: 1. Admins can override.
//   • Atomicity: redeemInviteCode uses a Firestore transaction so two
//     people can't "exhaust" the last slot concurrently.

const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = () => admin.firestore();

// ---------------------------------------------------------------------------
// Existing trigger — unchanged
// ---------------------------------------------------------------------------

exports.onTaskCreated = functions.firestore
  .document('elderProfiles/{elderId}/careTasks/{taskId}')
  .onCreate(async (snap, context) => {
    const task = snap.data();
    if (!task || !task.assignedTo) return null;

    try {
      const tokensSnap = await db()
        .collection('users')
        .doc(task.assignedTo)
        .collection('fcmTokens')
        .get();

      if (tokensSnap.empty) return null;

      const tokens = tokensSnap.docs.map((d) => d.id);

      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: 'New task assigned to you',
          body: task.title || 'Open Cecelia Care to view.',
        },
        data: {
          type: 'care_task',
          elderId: context.params.elderId,
          taskId: context.params.taskId,
        },
      });
    } catch (e) {
      console.error('onTaskCreated error', e);
    }
    return null;
  });

// ---------------------------------------------------------------------------
// Family invite flow
// ---------------------------------------------------------------------------

// Alphabet excludes 0/O, 1/I/L so the code is unambiguous on paper or
// over the phone. 32 chars ^ 8 positions = ~1.1 trillion codes.
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const CODE_LENGTH = 8;
const DEFAULT_TTL_DAYS = 14;
const MAX_TTL_DAYS = 90;
const DEFAULT_MAX_USES = 1;
const MAX_MAX_USES = 25;

function generateCode() {
  let out = '';
  const buf = require('crypto').randomBytes(CODE_LENGTH);
  for (let i = 0; i < CODE_LENGTH; i++) {
    out += CODE_ALPHABET[buf[i] % CODE_ALPHABET.length];
  }
  return out;
}

/**
 * Generates a unique code that doesn't collide with an existing doc id.
 * Retries up to N times — at 1.1T namespace the expected collision rate
 * is effectively zero, but the retry keeps us safe during lab testing
 * where codes can be created at high rates.
 */
async function allocateUniqueCode() {
  for (let attempt = 0; attempt < 6; attempt++) {
    const code = generateCode();
    const snap = await db().collection('inviteCodes').doc(code).get();
    if (!snap.exists) return code;
  }
  throw new functions.https.HttpsError(
    'internal',
    'Could not allocate a unique invite code. Please try again.',
  );
}

/**
 * Throws if the caller is not the primary admin on the elder profile.
 * Uses `isAdminRole` semantics that mirror the Firestore rules.
 */
async function requireAdminOnElder(uid, elderId) {
  const elderSnap = await db().collection('elderProfiles').doc(elderId).get();
  if (!elderSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Elder profile not found.');
  }
  const data = elderSnap.data();
  const isAdmin =
    data.primaryAdminUserId === uid ||
    (data.caregiverRoles && data.caregiverRoles[uid] === 'admin');
  if (!isAdmin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only the admin of this profile can invite others.',
    );
  }
  return { elderSnap, elderData: data };
}

/**
 * createInviteCode
 *
 * Request:  { elderId: string, role?: 'viewer'|'caregiver',
 *             ttlDays?: number, maxUses?: number }
 * Response: { code, expiresAt (ISO string), shareUrl }
 */
exports.createInviteCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in before creating an invite.',
    );
  }
  const uid = context.auth.uid;
  const elderId = (data && data.elderId) || '';
  if (!elderId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'elderId is required.',
    );
  }

  const requestedRole = (data && data.role) || 'viewer';
  if (!['viewer', 'caregiver'].includes(requestedRole)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      "role must be 'viewer' or 'caregiver'.",
    );
  }

  const ttlDays = Math.min(
    Math.max(parseInt((data && data.ttlDays) || DEFAULT_TTL_DAYS, 10), 1),
    MAX_TTL_DAYS,
  );
  const maxUses = Math.min(
    Math.max(parseInt((data && data.maxUses) || DEFAULT_MAX_USES, 10), 1),
    MAX_MAX_USES,
  );

  const { elderData } = await requireAdminOnElder(uid, elderId);

  const code = await allocateUniqueCode();
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + ttlDays * 24 * 60 * 60 * 1000,
  );

  // Grab the inviter's display name for UI attribution on the
  // recipient's redemption screen.
  let createdByName = null;
  try {
    const userSnap = await db().collection('users').doc(uid).get();
    if (userSnap.exists) {
      createdByName = userSnap.data().displayName || null;
    }
  } catch (_) {
    /* non-fatal */
  }

  const doc = {
    elderId,
    elderName:
      elderData.preferredName || elderData.profileName || 'Care recipient',
    role: requestedRole,
    createdByUid: uid,
    createdByName,
    createdAt: now,
    expiresAt,
    maxUses,
    uses: 0,
    redeemedByUids: [],
    status: 'active',
  };

  await db().collection('inviteCodes').doc(code).set(doc);

  return {
    code,
    expiresAt: expiresAt.toDate().toISOString(),
    shareUrl: `https://ceceliacare.app/invite/${code}`,
    role: requestedRole,
    maxUses,
  };
});

/**
 * redeemInviteCode
 *
 * Request:  { code: string }
 * Response: { elderId, elderName, role }
 *
 * Runs in a transaction:
 *   1. Read the invite code doc.
 *   2. Reject if expired / revoked / exhausted / already-redeemed-by-uid.
 *   3. Read the elder profile doc.
 *   4. Add UID to caregiverUserIds + caregiverRoles[uid].
 *   5. Increment uses, push UID to redeemedByUids.
 *   6. If uses == maxUses, mark status='exhausted'.
 */
exports.redeemInviteCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in before redeeming a code.',
    );
  }
  const uid = context.auth.uid;
  const rawCode = (data && data.code) || '';
  const code = String(rawCode).trim().toUpperCase();
  if (!/^[A-Z0-9]{6,12}$/.test(code)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'That code doesn\'t look right. Double-check and try again.',
    );
  }

  const codeRef = db().collection('inviteCodes').doc(code);

  return db().runTransaction(async (tx) => {
    const codeSnap = await tx.get(codeRef);
    if (!codeSnap.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'That invite code is not valid.',
      );
    }
    const invite = codeSnap.data();

    if (invite.status === 'revoked') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This invite has been revoked.',
      );
    }
    if (invite.status === 'exhausted') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'All uses of this invite have already been claimed.',
      );
    }
    if (
      invite.expiresAt &&
      invite.expiresAt.toMillis() < admin.firestore.Timestamp.now().toMillis()
    ) {
      tx.update(codeRef, { status: 'expired' });
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This invite has expired. Ask the sender for a new one.',
      );
    }
    if (
      Array.isArray(invite.redeemedByUids) &&
      invite.redeemedByUids.includes(uid)
    ) {
      // Idempotent: report success with the existing elder + role so
      // the client can navigate into it without error.
      return {
        elderId: invite.elderId,
        elderName: invite.elderName,
        role: invite.role,
        alreadyRedeemed: true,
      };
    }

    const elderRef = db().collection('elderProfiles').doc(invite.elderId);
    const elderSnap = await tx.get(elderRef);
    if (!elderSnap.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'The care profile on this invite no longer exists.',
      );
    }
    const elder = elderSnap.data();

    // Guard: user is already on the profile with some role — don't
    // consume a use slot for them. Surface a friendly message instead.
    const currentRoles = elder.caregiverRoles || {};
    const alreadyOnProfile =
      (elder.caregiverUserIds || []).includes(uid) ||
      currentRoles[uid] !== undefined ||
      elder.primaryAdminUserId === uid;
    if (alreadyOnProfile) {
      return {
        elderId: invite.elderId,
        elderName: invite.elderName,
        role: currentRoles[uid] || 'caregiver',
        alreadyOnProfile: true,
      };
    }

    const newUses = (invite.uses || 0) + 1;
    const newStatus = newUses >= invite.maxUses ? 'exhausted' : 'active';

    tx.update(elderRef, {
      caregiverUserIds: admin.firestore.FieldValue.arrayUnion(uid),
      [`caregiverRoles.${uid}`]: invite.role,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(codeRef, {
      uses: newUses,
      status: newStatus,
      redeemedByUids: admin.firestore.FieldValue.arrayUnion(uid),
      lastRedeemedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      elderId: invite.elderId,
      elderName: invite.elderName,
      role: invite.role,
      alreadyRedeemed: false,
    };
  });
});

/**
 * revokeInviteCode
 *
 * Request:  { code: string }
 * Response: { revoked: true }
 *
 * Allowed when: caller is the code creator OR the elder profile admin.
 */
exports.revokeInviteCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in to revoke an invite.',
    );
  }
  const uid = context.auth.uid;
  const code = ((data && data.code) || '').toString().trim().toUpperCase();
  if (!code) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'code is required.',
    );
  }
  const codeRef = db().collection('inviteCodes').doc(code);
  const snap = await codeRef.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError('not-found', 'Code not found.');
  }
  const invite = snap.data();

  if (invite.createdByUid !== uid) {
    // Fall back to admin check on the elder.
    await requireAdminOnElder(uid, invite.elderId);
  }

  await codeRef.update({
    status: 'revoked',
    revokedAt: admin.firestore.FieldValue.serverTimestamp(),
    revokedByUid: uid,
  });

  return { revoked: true };
});
