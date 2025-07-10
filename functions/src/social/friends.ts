import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

export const sendFriendRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }
  const senderId = request.auth.uid;
  const recipientId = request.data.recipientId as string;

  if (!recipientId) {
    throw new HttpsError("invalid-argument", "Recipient ID is required.");
  }
  if (senderId === recipientId) {
    throw new HttpsError(
      "invalid-argument", "Cannot send a request to yourself.");
  }

  try {
    const requestsRef = db.collection("friend_requests");
    const q1 = requestsRef
      .where("senderId", "==", senderId)
      .where("recipientId", "==", recipientId);
    const q2 = requestsRef
      .where("senderId", "==", recipientId)
      .where("recipientId", "==", senderId);

    const [snap1, snap2] = await Promise.all([q1.get(), q2.get()]);

    if (!snap1.empty || !snap2.empty) {
      throw new HttpsError(
        "already-exists", "Request already sent or received.");
    }

    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderData = senderDoc.data();
    if (!senderDoc.exists || !senderData) {
      throw new HttpsError("not-found", "Sender profile not found.");
    }

    const newRequest = {
      senderId,
      recipientId,
      involvedUsers: [senderId, recipientId],
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.collection("friend_requests").add(newRequest);
    return {success: true};
  } catch (error) {
    logger.error("Error sending friend request:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "Error sending friend request.");
  }
});

export const respondToFriendRequest = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }
  const currentUserId = request.auth.uid;
  const requestId = request.data.requestId as string;
  const response = request.data.response as "accepted" | "declined";

  if (!requestId || !response) {
    throw new HttpsError(
      "invalid-argument", "Request ID and response are required.");
  }

  try {
    const requestRef = db.collection("friend_requests").doc(requestId);
    const requestDoc = await requestRef.get();

    if (
      !requestDoc.exists ||
      requestDoc.data()?.recipientId !== currentUserId
    ) {
      throw new HttpsError(
        "not-found", "Request not found or you are not the recipient.");
    }

    if (response === "declined") {
      await requestRef.delete();
      return {success: true};
    }

    await requestRef.update({status: response});
    return {success: true};
  } catch (error) {
    logger.error("Error responding to friend request:", error);
    throw new HttpsError("internal", "Error responding to friend request.");
  }
});

export const onFriendRequestUpdate = onDocumentUpdated(
  "friend_requests/{requestId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const before = snapshot.before.data();
    const after = snapshot.after.data();

    if (before.status !== "pending" || after.status !== "accepted") {
      return;
    }

    const senderId = after.senderId;
    const recipientId = after.recipientId;

    const batch = db.batch();

    const senderFriendRef = db.collection("users").doc(senderId)
      .collection("friends").doc(recipientId);
    batch.set(senderFriendRef, {
      since: admin.firestore.FieldValue.serverTimestamp(),
    });

    const recipientFriendRef = db.collection("users").doc(recipientId)
      .collection("friends").doc(senderId);
    batch.set(recipientFriendRef, {
      since: admin.firestore.FieldValue.serverTimestamp(),
    });

    batch.delete(snapshot.after.ref);

    try {
      await batch.commit();
      logger.info(`Friendship created: ${senderId} and ${recipientId}`);
    } catch (error) {
      logger.error("Error creating friendship:", error);
    }
  });

export const removeFriend = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }
  const currentUserId = request.auth.uid;
  const friendId = request.data.friendId as string;

  if (!friendId) {
    throw new HttpsError("invalid-argument", "Friend ID is required.");
  }

  try {
    const batch = db.batch();

    const currentUserFriendRef = db
      .collection("users")
      .doc(currentUserId)
      .collection("friends")
      .doc(friendId);
    batch.delete(currentUserFriendRef);

    const friendUserFriendRef = db
      .collection("users")
      .doc(friendId)
      .collection("friends")
      .doc(currentUserId);
    batch.delete(friendUserFriendRef);

    await batch.commit();
    logger.info(`Friendship removed: ${currentUserId} and ${friendId}`);
    return {success: true};
  } catch (error) {
    logger.error("Error removing friend:", error);
    throw new HttpsError("internal", "Error removing friend.");
  }
});

