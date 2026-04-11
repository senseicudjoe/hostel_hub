/** Mirrors `lib/core/constants/app_constants.dart` (Firestore + roles). */
export const COLLECTIONS = {
  users: "users",
  rooms: "rooms",
  allocations: "allocations",
  maintenance: "maintenance_requests",
  announcements: "announcements",
} as const;

export const ROLE_ADMIN = "admin";
export const ROLE_STUDENT = "student";

/** Default hostel names (rooms may use any string). */
export const HOSTEL_NAMES = [
  "Unity Hall",
  "Freedom Hall",
  "Independence Hall",
] as const;

export const ROOM_STATUS = {
  available: "available",
  occupied: "occupied",
  maintenance: "maintenance",
} as const;
