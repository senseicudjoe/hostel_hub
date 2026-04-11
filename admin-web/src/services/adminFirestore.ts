import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  increment,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from "firebase/firestore";
import { db } from "../config/firebase";
import { COLLECTIONS, ROOM_STATUS } from "../config/constants";
import type { RoomRow } from "../types/models";

function newId(prefix: string, len = 8): string {
  const raw = crypto.randomUUID().replace(/-/g, "");
  return `${prefix}_${raw.slice(0, len)}`;
}

export async function createRoom(input: {
  hostelName: string;
  roomNumber: string;
  floor: number;
  capacity: number;
}): Promise<string> {
  const roomId = newId("room");
  const qrCode = `qr_${crypto.randomUUID().replace(/-/g, "")}`;
  await setDoc(doc(db, COLLECTIONS.rooms, roomId), {
    roomId,
    hostelName: input.hostelName.trim(),
    roomNumber: input.roomNumber.trim(),
    floor: input.floor,
    capacity: input.capacity,
    currentOccupants: 0,
    status: ROOM_STATUS.available,
    qrCode,
    imageUrls: [],
  });
  return roomId;
}

export async function updateRoom(
  roomDocId: string,
  patch: Partial<{
    hostelName: string;
    roomNumber: string;
    floor: number;
    capacity: number;
    status: string;
  }>,
): Promise<void> {
  const clean: Record<string, unknown> = {};
  if (patch.hostelName != null) clean.hostelName = patch.hostelName.trim();
  if (patch.roomNumber != null) clean.roomNumber = patch.roomNumber.trim();
  if (patch.floor != null) clean.floor = patch.floor;
  if (patch.capacity != null) clean.capacity = patch.capacity;
  if (patch.status != null) clean.status = patch.status;
  await updateDoc(
    doc(db, COLLECTIONS.rooms, roomDocId),
    clean as Record<string, string | number>,
  );
}

export async function deleteRoom(roomDocId: string): Promise<void> {
  const snap = await getDocs(
    query(collection(db, COLLECTIONS.allocations), where("roomId", "==", roomDocId)),
  );
  const hasActive = snap.docs.some((d) => d.data().status === "active");
  if (hasActive) {
    throw new Error(
      "Remove all active residents from this room before deleting it.",
    );
  }
  await deleteDoc(doc(db, COLLECTIONS.rooms, roomDocId));
}

/** Mirrors `FirestoreService.allocateRoom`. */
export async function allocateStudentToRoom(
  studentUid: string,
  room: RoomRow,
): Promise<void> {
  const allocSnap = await getDocs(
    query(
      collection(db, COLLECTIONS.allocations),
      where("studentUid", "==", studentUid),
    ),
  );
  const already = allocSnap.docs.some((d) => d.data().status === "active");
  if (already) {
    throw new Error("This student already has an active room allocation.");
  }

  if (room.status === ROOM_STATUS.maintenance) {
    throw new Error("Room is in maintenance — cannot assign.");
  }
  if (room.currentOccupants >= room.capacity) {
    throw new Error("Room is at capacity.");
  }

  const roomFirestoreId = room.id;
  const allocationId = newId("alloc");
  const newOccupants = room.currentOccupants + 1;
  const newStatus =
    newOccupants >= room.capacity ? ROOM_STATUS.occupied : ROOM_STATUS.available;

  const batch = writeBatch(db);
  batch.set(doc(db, COLLECTIONS.allocations, allocationId), {
    allocationId,
    studentUid,
    roomId: roomFirestoreId,
    hostelName: room.hostelName,
    roomNumber: room.roomNumber,
    allocatedAt: serverTimestamp(),
    status: "active",
  });
  batch.update(doc(db, COLLECTIONS.rooms, roomFirestoreId), {
    currentOccupants: increment(1),
    status: newStatus,
  });
  batch.update(doc(db, COLLECTIONS.users, studentUid), {
    hostel: room.hostelName,
    roomNumber: room.roomNumber,
  });
  await batch.commit();
}

/** Mirrors `FirestoreService.deallocateRoom`. */
export async function deallocateStudent(
  allocationId: string,
  studentUid: string,
  roomId: string,
): Promise<void> {
  const roomRef = doc(db, COLLECTIONS.rooms, roomId);
  const allocRef = doc(db, COLLECTIONS.allocations, allocationId);
  const userRef = doc(db, COLLECTIONS.users, studentUid);

  await runTransaction(db, async (tx) => {
    const roomSnap = await tx.get(roomRef);
    const data = roomSnap.data() ?? {};
    const currentOccupants = (data.currentOccupants as number) ?? 1;
    const currentStatus = (data.status as string) ?? ROOM_STATUS.available;

    const newStatus =
      currentStatus === ROOM_STATUS.maintenance
        ? ROOM_STATUS.maintenance
        : ROOM_STATUS.available;

    tx.update(allocRef, { status: "expired" });
    tx.update(roomRef, {
      currentOccupants: Math.max(0, currentOccupants - 1),
      status: newStatus,
    });
    tx.update(userRef, { hostel: "", roomNumber: "" });
  });
}

export async function updateMaintenanceRequest(input: {
  requestId: string;
  status: string;
  assignedTo?: string;
}): Promise<void> {
  await updateDoc(doc(db, COLLECTIONS.maintenance, input.requestId), {
    status: input.status,
    assignedTo: input.assignedTo ?? "",
    updatedAt: serverTimestamp(),
  });
}
