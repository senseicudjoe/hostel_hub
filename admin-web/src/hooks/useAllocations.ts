import { collection, onSnapshot, query, where } from "firebase/firestore";
import { useEffect, useState } from "react";
import { db } from "../config/firebase";
import { COLLECTIONS } from "../config/constants";

export interface AllocationRow {
  id: string;
  allocationId: string;
  studentUid: string;
  roomId: string;
  hostelName: string;
  roomNumber: string;
  status: string;
}

export function useAllocations() {
  const [allocations, setAllocations] = useState<AllocationRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, COLLECTIONS.allocations),
      where("status", "==", "active"),
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        const rows: AllocationRow[] = snap.docs.map((d) => {
          const data = d.data() as Record<string, unknown>;
          return {
            id: d.id,
            allocationId: String(data.allocationId ?? d.id),
            studentUid: String(data.studentUid ?? ""),
            roomId: String(data.roomId ?? ""),
            hostelName: String(data.hostelName ?? ""),
            roomNumber: String(data.roomNumber ?? ""),
            status: String(data.status ?? ""),
          };
        });
        rows.sort((a, b) => a.hostelName.localeCompare(b.hostelName));
        setAllocations(rows);
        setLoading(false);
        setError(null);
      },
      (err) => {
        setAllocations([]);
        setLoading(false);
        setError(err.message || "Could not load allocations");
      },
    );
    return () => unsub();
  }, []);

  return { allocations, loading, error };
}
