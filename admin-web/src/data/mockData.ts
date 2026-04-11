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
    number: "S-204",
    hostelName: "Sutherland Hall",
    floor: 2,
    capacity: 4,
    status: "occupied",
  },
  {
    id: "r2",
    number: "SI-205",
    hostelName: "Sisulu Hall",
    floor: 2,
    capacity: 4,
    status: "available",
  },
  {
    id: "r3",
    number: "A-312",
    hostelName: "Amu Hall",
    floor: 3,
    capacity: 4,
    status: "occupied",
  },
  {
    id: "r4",
    number: "Q-108",
    hostelName: "Oteng Korankye II Hall",
    floor: 1,
    capacity: 4,
    status: "maintenance",
  },
  {
    id: "r5",
    number: "M-201",
    hostelName: "Maathai Hall",
    floor: 2,
    capacity: 2,
    status: "available",
  },
  {
    id: "r6",
    number: "T-118",
    hostelName: "Tawiah Hall",
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
  { text: "Announcement sent to Sutherland Hall", time: "Yesterday" },
  { text: "req_8f2a3 resolved", time: "Yesterday" },
];

export const audienceOptions = [
  "All Residents",
  "Sutherland Hall",
  "Sisulu Hall",
  "Amu Hall",
  "Oteng Korankye II Hall",
  "Maathai Hall",
  "Tawiah Hall",
  "Students Only",
  "Staff Only",
] as const;
