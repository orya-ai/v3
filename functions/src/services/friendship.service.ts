import * as admin from "firebase-admin";
import { AppError } from "../utils/error-handler";
import { UserData, FriendRequestData, FriendData } from "../types";

const db = admin.firestore();

export class FriendshipService {
  private static instance: FriendshipService;

  private constructor() {
    // Private constructor to enforce singleton pattern
  }

  static getInstance(): FriendshipService {
    if (!FriendshipService.instance) {
      FriendshipService.instance = new FriendshipService();
    }
    return FriendshipService.instance;
  }

  async sendFriendRequest(senderId: string, recipientId: string) {
    if (senderId === recipientId) {
      throw new AppError("invalid-argument", "Cannot send friend request to yourself");
    }

    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    // Check if users exist and get their data
    const [senderDoc, recipientDoc] = await Promise.all([
      db.collection("users").doc(senderId).get(),
      db.collection("users").doc(recipientId).get(),
    ]);

    if (!senderDoc.exists || !recipientDoc.exists) {
      throw new AppError("not-found", "User not found");
    }

    const senderData = senderDoc.data() as UserData;
    const recipientData = recipientDoc.data() as UserData;

    // Check if friend request already exists
    const existingRequest = await db
        .collection("users")
        .doc(recipientId)
        .collection("friend_requests_received")
        .doc(senderId)
        .get();

    if (existingRequest.exists) {
      throw new AppError("already-exists", "Friend request already sent");
    }

    // Create friend request in sender's sent requests
    const senderRequestRef = db
        .collection("users")
        .doc(senderId)
        .collection("friend_requests_sent")
        .doc(recipientId);

    batch.set(senderRequestRef, {
      userId: recipientId,
      displayName: recipientData.displayName || "",
      photoURL: recipientData.photoURL || "",
      status: "pending",
      timestamp,
    } as FriendRequestData);

    // Create friend request in recipient's received requests
    const recipientRequestRef = db
        .collection("users")
        .doc(recipientId)
        .collection("friend_requests_received")
        .doc(senderId);

    batch.set(recipientRequestRef, {
      userId: senderId,
      displayName: senderData.displayName || "",
      photoURL: senderData.photoURL || "",
      status: "pending",
      timestamp,
    } as FriendRequestData);

    await batch.commit();
    return { success: true, requestId: recipientRequestRef.id };
  }

  async acceptFriendRequest(currentUserId: string, senderId: string) {
    if (currentUserId === senderId) {
      throw new AppError("invalid-argument", "Invalid operation");
    }

    const batch = db.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    // Get user data for denormalization
    const [currentUserDoc, senderDoc] = await Promise.all([
      db.collection("users").doc(currentUserId).get(),
      db.collection("users").doc(senderId).get(),
    ]);

    if (!currentUserDoc.exists || !senderDoc.exists) {
      throw new AppError("not-found", "User not found");
    }

    const currentUserData = currentUserDoc.data() as UserData;
    const senderData = senderDoc.data() as UserData;

    // References to request documents
    const receivedRequestRef = db
        .collection("users")
        .doc(currentUserId)
        .collection("friend_requests_received")
        .doc(senderId);

    const sentRequestRef = db
        .collection("users")
        .doc(senderId)
        .collection("friend_requests_sent")
        .doc(currentUserId);

    // Add to friends collection for current user
    const currentUserFriendRef = db
        .collection("users")
        .doc(currentUserId)
        .collection("friends")
        .doc(senderId);

    // Add to friends collection for the other user
    const senderFriendRef = db
        .collection("users")
        .doc(senderId)
        .collection("friends")
        .doc(currentUserId);

    // Batch all operations
    batch.delete(receivedRequestRef);
    batch.delete(sentRequestRef);

    batch.set(currentUserFriendRef, {
      userId: senderId,
      displayName: senderData.displayName || "",
      photoURL: senderData.photoURL || "",
      timestamp,
    } as FriendData);

    batch.set(senderFriendRef, {
      userId: currentUserId,
      displayName: currentUserData.displayName || "",
      photoURL: currentUserData.photoURL || "",
      timestamp,
    } as FriendData);

    await batch.commit();
    return { success: true };
  }

  async declineFriendRequest(currentUserId: string, senderId: string) {
    if (currentUserId === senderId) {
      throw new AppError("invalid-argument", "Invalid operation");
    }

    const batch = db.batch();

    // References to request documents
    const receivedRequestRef = db
        .collection("users")
        .doc(currentUserId)
        .collection("friend_requests_received")
        .doc(senderId);

    const sentRequestRef = db
        .collection("users")
        .doc(senderId)
        .collection("friend_requests_sent")
        .doc(currentUserId);

    batch.delete(receivedRequestRef);
    batch.delete(sentRequestRef);

    await batch.commit();
    return { success: true };
  }

  async removeFriend(currentUserId: string, friendId: string) {
    if (currentUserId === friendId) {
      throw new AppError("invalid-argument", "Invalid operation");
    }

    const batch = db.batch();

    // References to friend documents
    const currentUserFriendRef = db
        .collection("users")
        .doc(currentUserId)
        .collection("friends")
        .doc(friendId);

    const friendUserRef = db
        .collection("users")
        .doc(friendId)
        .collection("friends")
        .doc(currentUserId);

    batch.delete(currentUserFriendRef);
    batch.delete(friendUserRef);

    await batch.commit();
    return { success: true };
  }

  async updateUserData(userId: string, updatedData: Partial<UserData>) {
    const BATCH_SIZE = 500; // Firestore batch limit

    // Process updates in batches to avoid hitting batch limits
    const processInBatches = async (
        query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData>,
        updateFn: (
        doc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
      ) => FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> | null
    ) => {
      let lastDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | null = null;
      let hasMore = true;

      while (hasMore) {
        const batch = db.batch();
        let batchCount = 0;

        // Get the next batch of documents
        let querySnapshot = query;
        if (lastDoc) {
          querySnapshot = query.startAfter(lastDoc);
        }

        const snapshot = await querySnapshot.limit(BATCH_SIZE).get();

        // Process each document in the batch
        snapshot.docs.forEach((doc) => {
          const updateData = updateFn(doc);
          if (updateData && Object.keys(updateData).length > 0) {
            batch.update(doc.ref, updateData);
            batchCount++;
          }
          lastDoc = doc;
        });

        // Commit the batch if there are updates
        if (batchCount > 0) {
          await batch.commit();
        }

        // Check if we've processed all documents
        hasMore = !snapshot.empty && snapshot.size === BATCH_SIZE;
      }
    };


    try {
      // Process received friend requests
      const receivedRequestsQuery = db
          .collection("users")
          .doc(userId)
          .collection("friend_requests_received");

      await processInBatches(receivedRequestsQuery, () => {
        const updateData: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {};
        if ("displayName" in updatedData) {
          updateData.senderDisplayName = updatedData.displayName || "";
        }
        if ("photoURL" in updatedData) {
          updateData.senderPhotoUrl = updatedData.photoURL || "";
        }
        return Object.keys(updateData).length > 0 ? updateData : null;
      });

      // Process sent friend requests
      const sentRequestsQuery = db
          .collection("users")
          .doc(userId)
          .collection("friend_requests_sent");

      await processInBatches(sentRequestsQuery, () => {
        const updateData: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {};
        if ("displayName" in updatedData) {
          updateData.recipientDisplayName = updatedData.displayName || "";
        }
        if ("photoURL" in updatedData) {
          updateData.recipientPhotoUrl = updatedData.photoURL || "";
        }
        return Object.keys(updateData).length > 0 ? updateData : null;
      });

      // Process friends
      const friendsQuery = db
          .collectionGroup("friends")
          .where("userId", "==", userId);

      await processInBatches(friendsQuery, () => {
        const updateData: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData> = {};
        if ("displayName" in updatedData) {
          updateData.displayName = updatedData.displayName || "";
        }
        if ("photoURL" in updatedData) {
          updateData.photoUrl = updatedData.photoURL || "";
        }
        return Object.keys(updateData).length > 0 ? updateData : null;
      });

      return { success: true };
    } catch (error) {
      console.error("Error updating user data:", error);
      throw new AppError("internal", "Failed to update user data");
    }
  }
}
