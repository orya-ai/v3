import { onCall } from "firebase-functions/v2/https";
import { handleError, assertAuthenticated, assertData } from "../utils/error-handler";
import { FriendshipService } from "../services/friendship.service";

export const removeFriend = onCall(
  {
    enforceAppCheck: true,
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      assertAuthenticated(request);
      assertData<{ friendId: string }>(request.data, ["friendId"]);

      const { friendId } = request.data;
      const currentUserId = request.auth.uid;

      const friendshipService = FriendshipService.getInstance();
      const result = await friendshipService.removeFriend(currentUserId, friendId);

      return { success: true, data: result };
    } catch (error) {
      handleError(error);
    }
  }
);
