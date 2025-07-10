export interface User {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  email_lowercase?: string;
  displayName_lowercase?: string;
}
