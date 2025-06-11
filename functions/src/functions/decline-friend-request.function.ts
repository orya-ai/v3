import { onCall } from "firebase-functions/v2/https";
import { handleError, assertAuthenticated, assertData } from "../utils/error-handler";
import { FriendshipService } from "../services/friendship.service";

export const declineFriendRequest = onCall(
  {
    enforceAppCheck: true,
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      assertAuthenticated(request);
      assertData<{ senderId: string }>(request.data, ["senderId"]);

      const { senderId } = request.data;
      const currentUserId = request.auth.uid;

      const friendshipService = FriendshipService.getInstance();
      const result = await friendshipService.declineFriendRequest(currentUserId, senderId);

      return { success: true, data: result };
    } catch (error) {
      handleError(error);
    }
  }
);
