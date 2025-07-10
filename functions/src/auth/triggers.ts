import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {User} from "../user/types";

const db = admin.firestore();

export const onUserCreate = functions.auth.user().onCreate((user: functions.auth.UserRecord) => {
  logger.info("A new user is being created:", user);

  const newUser: User = {
    uid: user.uid,
    email: user.email || null,
    displayName: user.displayName || null,
    photoUrl: user.photoURL || null,
    email_lowercase: user.email?.toLowerCase(),
    displayName_lowercase: user.displayName?.toLowerCase(),
  };

  return db.collection("users").doc(user.uid).set(newUser)
    .then(() => {
      logger.info(`User profile created for ${user.uid}`);
      return null;
    })
    .catch((error) => {
      logger.error(`Error creating user profile for ${user.uid}:`, error);
      return null;
    });
});






