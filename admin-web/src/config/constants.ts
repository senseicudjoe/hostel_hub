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

/** Ashesi University campus hostel names. */
export const HOSTEL_NAMES = [
  "Sutherland Hall",
  "Sisulu Hall",
  "Amu Hall",
  "Oteng Korankye II Hall",
  "Maathai Hall",
  "Tawiah Hall",
] as const;

export const ROOM_STATUS = {
  available: "available",
  occupied: "occupied",
  maintenance: "maintenance",
} as const;
