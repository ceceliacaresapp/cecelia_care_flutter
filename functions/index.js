// functions/index.js
//
// Cloud Functions for Cecelia Care.
//
// onTaskCreated: when a new careTasks document is added under an elder
// profile, send an FCM push to the assignee's registered tokens. If the
// task is unassigned the function exits silently.

const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.onTaskCreated = functions.firestore
  .document('elderProfiles/{elderId}/careTasks/{taskId}')
  .onCreate(async (snap, context) => {
    const task = snap.data();
    if (!task || !task.assignedTo) return null;

    try {
      const tokensSnap = await admin
        .firestore()
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
