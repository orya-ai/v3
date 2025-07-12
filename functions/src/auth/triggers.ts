import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {User} from "../user/types";

const db = admin.firestore();

export const onUserCreate = functions.auth
  .user()
  .onCreate((user: functions.auth.UserRecord) => {
    logger.info("A new user is being created:", user);

    const newUser: User = {
      uid: user.uid,
      email: user.email || null,
      displayName: user.displayName || null,
      photoUrl: user.photoURL || null,
      email_lowercase: user.email?.toLowerCase(),
      displayName_lowercase: user.displayName?.toLowerCase(),
    };

    return db
      .collection("users")
      .doc(user.uid)
      .set(newUser)
      .then(() => {
        logger.info(`User profile created for ${user.uid}`);
        return null;
      })
      .catch((error) => {
        logger.error(`Error creating user profile for ${user.uid}:`, error);
        return null;
      });
  });

export const onUserUpdate = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data() as User;
    const oldData = change.before.data() as User;
    const userId = context.params.userId;

    // If the displayName has not changed, do nothing.
    if (newData.displayName === oldData.displayName) {
      return null;
    }

    logger.info(`User ${userId} displayName change detected. Syncing to Auth.`);

    try {
      await admin.auth().updateUser(userId, {
        displayName: newData.displayName,
      });
      logger.info(`Successfully updated Auth displayName for user ${userId}.`);
      return null;
    } catch (error) {
      logger.error(
        `Error updating Auth displayName for user ${userId}:`,
        error
      );
      return null;
    }
  });

export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  logger.info(`User ${user.uid} is being deleted. Cleaning up Firestore data.`);
  const docRef = db.collection("users").doc(user.uid);

  try {
    await docRef.delete();
    logger.info(
      `Successfully deleted Firestore document for user ${user.uid}.`
    );
    return null;
  } catch (error) {
    logger.error(
      `Error deleting Firestore document for user ${user.uid}:`,
      error
    );
    return null;
  }
});
