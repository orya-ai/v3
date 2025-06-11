import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2/options";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Set global options for all functions
setGlobalOptions({
  region: "us-central1",
  memory: "256MiB",
  timeoutSeconds: 60,
});

// Export functions from their respective files
export { acceptFriendRequest } from "./functions/accept-friend-request.function";
export { declineFriendRequest } from "./functions/decline-friend-request.function";
export { sendFriendRequest } from "./functions/send-friend-request.function";
export { removeFriend } from "./functions/remove-friend.function";

// Export onUserUpdate if it exists
export { onUserUpdate } from "./functions/on-user-update.function";
