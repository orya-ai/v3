import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { FriendshipService } from "../services/friendship.service";
import { UserData } from "../types";

export const onUserUpdate = onDocumentUpdated(
  {
    document: "users/{userId}",
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    try {
      if (!event.data) {
        console.log("No data associated with the event");
        return;
      }

      const beforeData = event.data.before.data() as UserData;
      const afterData = event.data.after.data() as UserData;
      const userId = event.params.userId;

      // Check if displayName or photoURL changed
      const updatedFields: Partial<UserData> = {};

      if (beforeData.displayName !== afterData.displayName) {
        updatedFields.displayName = afterData.displayName;
      }

      if (beforeData.photoURL !== afterData.photoURL) {
        updatedFields.photoURL = afterData.photoURL;
      }

      // If no relevant fields changed, exit early
      if (Object.keys(updatedFields).length === 0) {
        return;
      }

      const friendshipService = FriendshipService.getInstance();
      await friendshipService.updateUserData(userId, updatedFields);
    } catch (error) {
      console.error("Error in onUserUpdate:", error);
      throw error; // Let the error be handled by the global error handler
    }
  }
);
