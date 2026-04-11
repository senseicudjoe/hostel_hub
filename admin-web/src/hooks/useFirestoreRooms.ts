import { collection, onSnapshot } from "firebase/firestore";
import { useEffect, useState } from "react";
import { db } from "../config/firebase";
import { COLLECTIONS } from "../config/constants";
import type { RoomRow } from "../types/models";

function mapRoom(docId: string, data: Record<string, unknown>): RoomRow {
  const roomId = (data.roomId as string) || docId;
  return {
    id: docId,
    roomId,
    hostelName: String(data.hostelName ?? ""),
    roomNumber: String(data.roomNumber ?? ""),
    floor: Number(data.floor ?? 0),
    capacity: Number(data.capacity ?? 0),
    currentOccupants: Number(data.currentOccupants ?? 0),
    status: String(data.status ?? "available"),
  };
}

export function useFirestoreRooms() {
  const [rooms, setRooms] = useState<RoomRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const ref = collection(db, COLLECTIONS.rooms);
    const unsub = onSnapshot(
      ref,
      (snap) => {
        const rows = snap.docs
          .map((d) => mapRoom(d.id, d.data() as Record<string, unknown>))
          .sort((a, b) => a.hostelName.localeCompare(b.hostelName));
        setRooms(rows);
        setLoading(false);
        setError(null);
      },
      (err) => {
        setRooms([]);
        setLoading(false);
        setError(err.message || "Could not load rooms");
      },
    );
    return () => unsub();
  }, []);

  return { rooms, loading, error };
}
