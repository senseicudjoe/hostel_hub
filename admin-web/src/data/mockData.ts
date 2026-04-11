export type RoomStatus = "occupied" | "available" | "maintenance";

export interface MockRoom {
  id: string;
  number: string;
  hostelName: string;
  floor: number;
  capacity: number;
  status: RoomStatus;
}

export interface MockMaintenance {
  id: string;
  title: string;
  category: string;
  status: "pending" | "in_progress" | "resolved";
  studentRef: string;
  createdAt: string;
}

export const mockRooms: MockRoom[] = [
  {
    id: "r1",
    number: "204",
    hostelName: "Unity Hall",
    floor: 2,
    capacity: 2,
    status: "occupied",
  },
  {
    id: "r2",
    number: "205",
    hostelName: "Unity Hall",
    floor: 2,
    capacity: 2,
    status: "available",
  },
  {
    id: "r3",
    number: "312",
    hostelName: "Freedom Hall",
    floor: 3,
    capacity: 4,
    status: "occupied",
  },
  {
    id: "r4",
    number: "108",
    hostelName: "Independence Hall",
    floor: 1,
    capacity: 2,
    status: "maintenance",
  },
  {
    id: "r5",
    number: "401",
    hostelName: "Freedom Hall",
    floor: 4,
    capacity: 2,
    status: "available",
  },
  {
    id: "r6",
    number: "118",
    hostelName: "Unity Hall",
    floor: 1,
    capacity: 2,
    status: "occupied",
  },
];

export const mockMaintenance: MockMaintenance[] = [
  {
    id: "req_8f2a1",
    title: "Leaking faucet in shared bath",
    category: "Plumbing",
    status: "pending",
    studentRef: "stu_…42",
    createdAt: "2026-03-26",
  },
  {
    id: "req_8f2a2",
    title: "AC not cooling",
    category: "HVAC",
    status: "in_progress",
    studentRef: "stu_…91",
    createdAt: "2026-03-25",
  },
  {
    id: "req_8f2a3",
    title: "Broken desk drawer",
    category: "Furniture",
    status: "resolved",
    studentRef: "stu_…03",
    createdAt: "2026-03-22",
  },
  {
    id: "req_8f2a4",
    title: "Lights flickering",
    category: "Electrical",
    status: "pending",
    studentRef: "stu_…77",
    createdAt: "2026-03-27",
  },
];

export const categoryCounts = [
  { label: "Plumbing", count: 12 },
  { label: "Electrical", count: 8 },
  { label: "HVAC", count: 5 },
  { label: "Furniture", count: 4 },
  { label: "Other", count: 3 },
];

export const weeklyTrend = [4, 6, 5, 8, 7, 9, 6];

export const recentActivity = [
  { text: "Request req_8f2a4 marked pending", time: "2h ago" },
  { text: "Room 312 status → occupied", time: "5h ago" },
  { text: "Announcement sent to Unity Hall", time: "Yesterday" },
  { text: "req_8f2a3 resolved", time: "Yesterday" },
];

export const audienceOptions = [
  "All Residents",
  "Unity Hall",
  "Freedom Hall",
  "Independence Hall",
  "Students Only",
  "Staff Only",
] as const;
