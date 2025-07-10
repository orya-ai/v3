import * as admin from "firebase-admin";

admin.initializeApp();

// Export functions from organized files

export * from "./user/callable";
export * from "./social/friends";
export * from "./auth/triggers";

