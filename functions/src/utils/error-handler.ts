import { HttpsError } from "firebase-functions/v2/https";

export class AppError extends Error {
  constructor(
    public readonly code: string,
    public readonly message: string,
    public readonly details?: unknown
  ) {
    super(message);
    this.name = "AppError";
  }
}

export function handleError(error: unknown): never {
  if (error instanceof AppError) {
    throw new HttpsError(error.code as any, error.message, error.details);
  }
  if (error instanceof Error) {
    throw new HttpsError("internal", error.message, { original: error });
  }
  throw new HttpsError("internal", "An unknown error occurred");
}

export function assertAuthenticated(request: any): asserts request is { auth: { uid: string } } {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
}

export function assertData<T extends Record<string, any>>(
  data: unknown,
  requiredFields: (keyof T)[] = []
): asserts data is T {
  if (!data || typeof data !== "object") {
    throw new HttpsError("invalid-argument", "Expected data to be an object");
  }

  for (const field of requiredFields) {
    if (!(field in data)) {
      throw new HttpsError("invalid-argument", `Missing required field: ${String(field)}`);
    }
  }
}
