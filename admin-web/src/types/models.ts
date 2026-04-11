export interface RoomRow {
  id: string;
  roomId: string;
  hostelName: string;
  roomNumber: string;
  floor: number;
  capacity: number;
  currentOccupants: number;
  status: string;
}

export interface MaintenanceRow {
  id: string;
  requestId: string;
  studentUid: string;
  title: string;
  description: string;
  category: string;
  status: string;
  assignedTo: string;
  hostelName: string;
  roomNumber: string;
  createdAt: Date;
}
