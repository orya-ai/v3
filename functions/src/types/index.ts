import * as admin from "firebase-admin";

export interface UserData {
  uid: string;
  email?: string;
  displayName?: string;
  photoURL?: string;
  emailLowercase?: string;
  displayNameLowercase?: string;
  createdAt?: admin.firestore.FieldValue;
  updatedAt?: admin.firestore.FieldValue;
}

export interface FriendRequestData {
  userId: string;
  displayName: string;
  photoURL?: string;
  status: "pending" | "accepted" | "declined";
  timestamp: admin.firestore.FieldValue;
}

export interface FriendData {
  userId: string;
  displayName: string;
  photoURL?: string;
  timestamp: admin.firestore.FieldValue;
}

interface AuthToken {
  [key: string]: unknown;
  uid?: string;
  email?: string;
}

export interface CallableContext {
  auth?: {
    uid: string;
    token: AuthToken;
  };
}
