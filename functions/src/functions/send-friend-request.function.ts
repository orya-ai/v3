import { onCall } from "firebase-functions/v2/https";
import { handleError, assertAuthenticated, assertData } from "../utils/error-handler";
import { FriendshipService } from "../services/friendship.service";

export const sendFriendRequest = onCall(
  {
    enforceAppCheck: true,
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      assertAuthenticated(request);
      assertData<{ recipientId: string }>(request.data, ["recipientId"]);

      const { recipientId } = request.data;
      const senderId = request.auth.uid;

      const friendshipService = FriendshipService.getInstance();
      const result = await friendshipService.sendFriendRequest(senderId, recipientId);

      return { success: true, data: result };
    } catch (error) {
      handleError(error);
    }
  }
);
