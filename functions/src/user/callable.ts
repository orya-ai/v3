import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

export const searchUsers = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }
  const currentUid = request.auth.uid;
  const query = request.data.query as string;
  if (!query || typeof query !== "string" || query.trim().length === 0) {
    throw new HttpsError("invalid-argument", "A valid 'query' is required.");
  }
  const searchTerm = query.trim().toLowerCase();
  try {
    const usersRef = db.collection("users");
    const nameQuery = usersRef
      .where("displayName_lowercase", ">=", searchTerm)
      .where("displayName_lowercase", "<=", searchTerm + "\uf8ff")
      .limit(10).get();
    const emailQuery = usersRef
      .where("email_lowercase", ">=", searchTerm)
      .where("email_lowercase", "<=", searchTerm + "\uf8ff")
      .limit(10).get();
    const [nameResults, emailResults] = await Promise.all([
      nameQuery,
      emailQuery,
    ]);
    const userMap = new Map();
    const processSnapshot = (snapshot: FirebaseFirestore.QuerySnapshot) => {
      snapshot.forEach((doc) => {
        if (doc.id !== currentUid) {
          userMap.set(doc.id, {uid: doc.id, ...doc.data()});
        }
      });
    };
    processSnapshot(nameResults);
    processSnapshot(emailResults);
    return Array.from(userMap.values());
  } catch (error) {
    logger.error("Error searching users:", error);
    throw new HttpsError("internal", "Error searching users.");
  }
});
