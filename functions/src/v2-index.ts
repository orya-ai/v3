import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

interface UserData {
  displayName?: string;
  photoURL?: string;
  email?: string;
  uid?: string;
  // Add other known properties here instead of using [key: string]: any
}

interface FriendRequestData {
  recipientId: string;
  requestId?: string; // For update operations
}

interface FriendData {
  friendId: string;
}

interface UpdateFriendRequestData extends FriendRequestData {
  requestId: string;
}

// Helper function to get user data
async function getUserData(userId: string) {
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User not found");
  }
  return userDoc.data() as UserData;
}

// 1. Send Friend Request
export const sendFriendRequest = onCall(
    { enforceAppCheck: false, region: "us-central1" },
    async (request) => {
    // Check if user is authenticated
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be authenticated to send friend requests"
        );
      }

      const senderId = request.auth.uid;
      const { recipientId } = request.data as FriendRequestData;

      // Validate input
      if (!recipientId) {
        throw new HttpsError(
            "invalid-argument",
            "Recipient ID is required"
        );
      }

      if (senderId === recipientId) {
        throw new HttpsError(
            "invalid-argument",
            "Cannot send friend request to yourself"
        );
      }

      const batch = db.batch();
      const timestamp = admin.firestore.FieldValue.serverTimestamp();

      try {
      // Get sender and recipient data
        const [senderData, recipientData] = await Promise.all([
          getUserData(senderId),
          getUserData(recipientId)
        ]);

        // Check if request already exists
        const existingRequest = await db
            .collection("users")
            .doc(recipientId)
            .collection("friend_requests_received")
            .doc(senderId)
            .get();

        if (existingRequest.exists) {
          throw new HttpsError(
              "already-exists",
              "Friend request already sent"
          );
        }

        // Check if already friends
        const existingFriend = await db
            .collection("users")
            .doc(recipientId)
            .collection("friends")
            .doc(senderId)
            .get();

        if (existingFriend.exists) {
          throw new HttpsError(
              "already-exists",
              "User is already your friend"
          );
        }

        // Create friend request in sender's sent requests
        const senderRequestRef = db
            .collection("users")
            .doc(senderId)
            .collection("friend_requests_sent")
            .doc(recipientId);

        batch.set(senderRequestRef, {
          recipientId,
          recipientDisplayName: recipientData?.displayName || "",
          recipientPhotoUrl: recipientData?.photoURL || "",
          status: "pending",
          timestamp
        });

        // Create friend request in recipient's received requests
        const recipientRequestRef = db
            .collection("users")
            .doc(recipientId)
            .collection("friend_requests_received")
            .doc(senderId);

        batch.set(recipientRequestRef, {
          senderId,
          senderDisplayName: senderData?.displayName || "",
          senderPhotoUrl: senderData?.photoURL || "",
          status: "pending",
          timestamp,
          requestId: senderRequestRef.id
        });

        await batch.commit();
        return { success: true, requestId: senderRequestRef.id };
      } catch (error) {
        logger.error("Error sending friend request:", error);
        throw new HttpsError(
            "internal",
            "Failed to send friend request",
            error
        );
      }
    }
);

// 2. Accept Friend Request
export const acceptFriendRequest = onCall(
    { enforceAppCheck: false, region: "us-central1" },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be authenticated to accept friend requests"
        );
      }

      const { requestId, recipientId } = request.data as UpdateFriendRequestData;
      const userId = request.auth.uid;

      if (!requestId || !recipientId) {
        throw new HttpsError(
            "invalid-argument",
            "Request ID and Recipient ID are required"
        );
      }

      const batch = db.batch();
      const timestamp = admin.firestore.FieldValue.serverTimestamp();

      try {
      // Get user data
        const [userData, requesterData] = await Promise.all([
          getUserData(userId),
          getUserData(recipientId)
        ]);

        // Remove the request from both users' request collections
        const receivedRequestRef = db
            .collection("users")
            .doc(userId)
            .collection("friend_requests_received")
            .doc(recipientId);

        const sentRequestRef = db
            .collection("users")
            .doc(recipientId)
            .collection("friend_requests_sent")
            .doc(userId);

        // Add to friends collection for both users
        const userFriendRef = db
            .collection("users")
            .doc(userId)
            .collection("friends")
            .doc(recipientId);

        const requesterFriendRef = db
            .collection("users")
            .doc(recipientId)
            .collection("friends")
            .doc(userId);

        // Update status to accepted
        batch.update(receivedRequestRef, {
          status: "accepted",
          updatedAt: timestamp
        });

        batch.update(sentRequestRef, {
          status: "accepted",
          updatedAt: timestamp
        });

        // Add to friends collection
        batch.set(userFriendRef, {
          friendId: recipientId,
          displayName: requesterData?.displayName || "",
          photoUrl: requesterData?.photoURL || "",
          timestamp
        });

        batch.set(requesterFriendRef, {
          friendId: userId,
          displayName: userData?.displayName || "",
          photoUrl: userData?.photoURL || "",
          timestamp
        });

        await batch.commit();
        return { success: true };
      } catch (error) {
        logger.error("Error accepting friend request:", error);
        throw new HttpsError(
            "internal",
            "Failed to accept friend request",
            error
        );
      }
    }
);

// 3. Decline Friend Request
export const declineFriendRequest = onCall(
    { enforceAppCheck: false, region: "us-central1" },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be authenticated to decline friend requests"
        );
      }

      const { requestId, recipientId } = request.data as UpdateFriendRequestData;
      const userId = request.auth.uid;

      if (!requestId || !recipientId) {
        throw new HttpsError(
            "invalid-argument",
            "Request ID and Recipient ID are required"
        );
      }

      const batch = db.batch();

      try {
      // Remove the request from both users' request collections
        const receivedRequestRef = db
            .collection("users")
            .doc(userId)
            .collection("friend_requests_received")
            .doc(recipientId);

        const sentRequestRef = db
            .collection("users")
            .doc(recipientId)
            .collection("friend_requests_sent")
            .doc(userId);

        batch.delete(receivedRequestRef);
        batch.delete(sentRequestRef);

        await batch.commit();
        return { success: true };
      } catch (error) {
        logger.error("Error declining friend request:", error);
        throw new HttpsError(
            "internal",
            "Failed to decline friend request",
            error
        );
      }
    }
);

// 4. Remove Friend
export const removeFriend = onCall(
    { enforceAppCheck: false, region: "us-central1" },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be authenticated to remove friends"
        );
      }

      const { friendId } = request.data as FriendData;
      const userId = request.auth.uid;

      if (!friendId) {
        throw new HttpsError(
            "invalid-argument",
            "Friend ID is required"
        );
      }

      const batch = db.batch();

      try {
      // Remove friend from both users' friends collections
        const userFriendRef = db
            .collection("users")
            .doc(userId)
            .collection("friends")
            .doc(friendId);

        const friendUserRef = db
            .collection("users")
            .doc(friendId)
            .collection("friends")
            .doc(userId);

        batch.delete(userFriendRef);
        batch.delete(friendUserRef);

        await batch.commit();
        return { success: true };
      } catch (error) {
        logger.error("Error removing friend:", error);
        throw new HttpsError(
            "internal",
            "Failed to remove friend",
            error
        );
      }
    }
);

// 5. Update denormalized user data when user profile changes
export const onUserUpdate = onDocumentUpdated(
    "users/{userId}",
    async (event) => {
      const userId = event.params.userId;
      const beforeData = event.data?.before.data() as UserData | undefined;
      const afterData = event.data?.after.data() as UserData | undefined;

      if (!beforeData || !afterData) {
        return null;
      }

      // Check if displayName or photoURL changed
      if (
        beforeData.displayName === afterData.displayName &&
      beforeData.photoURL === afterData.photoURL
      ) {
        return null; // No relevant changes
      }

      const batch = db.batch();
      const batchSize = 500; // Firestore batch limit
      let batchCount = 0;

      try {
      // Update friend requests where this user is the sender
        const sentRequestsQuery = db
            .collectionGroup("friend_requests_sent")
            .where("senderId", "==", userId);

        const sentRequestsSnapshot = await sentRequestsQuery.get();

        for (const doc of sentRequestsSnapshot.docs) {
          batch.update(doc.ref, {
            senderDisplayName: afterData.displayName || "",
            senderPhotoUrl: afterData.photoURL || ""
          });
          batchCount++;

          if (batchCount >= batchSize) {
            await batch.commit();
            batchCount = 0;
          }
        }

        // Update friend requests where this user is the recipient
        const receivedRequestsQuery = db
            .collectionGroup("friend_requests_received")
            .where("recipientId", "==", userId);

        const receivedRequestsSnapshot = await receivedRequestsQuery.get();

        for (const doc of receivedRequestsSnapshot.docs) {
          batch.update(doc.ref, {
            recipientDisplayName: afterData.displayName || "",
            recipientPhotoUrl: afterData.photoURL || ""
          });
          batchCount++;

          if (batchCount >= batchSize) {
            await batch.commit();
            batchCount = 0;
          }
        }

        // Update friends collections where this user is a friend
        const friendsQuery = db
            .collectionGroup("friends")
            .where("friendId", "==", userId);

        const friendsSnapshot = await friendsQuery.get();

        for (const doc of friendsSnapshot.docs) {
          batch.update(doc.ref, {
            displayName: afterData.displayName || "",
            photoUrl: afterData.photoURL || ""
          });
          batchCount++;

          if (batchCount >= batchSize) {
            await batch.commit();
            batchCount = 0;
          }
        }

        // Commit any remaining operations
        if (batchCount > 0) {
          await batch.commit();
        }

        return { success: true, updated: true };
      } catch (error) {
        logger.error("Error updating denormalized user data:", error);
        throw new HttpsError(
            "internal",
            "Failed to update denormalized user data",
            error
        );
      }
    }
);
