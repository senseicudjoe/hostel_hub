import { collection, onSnapshot } from "firebase/firestore";
import { useEffect, useState } from "react";
import { db } from "../config/firebase";
import { COLLECTIONS } from "../config/constants";
import { parseFirestoreDate } from "../lib/timestamp";
import type { MaintenanceRow } from "../types/models";

function mapMaintenance(
  docId: string,
  data: Record<string, unknown>,
): MaintenanceRow {
  const requestId = String(data.requestId ?? docId);
  return {
    id: docId,
    requestId,
    studentUid: String(data.studentUid ?? ""),
    title: String(data.title ?? ""),
    description: String(data.description ?? ""),
    category: String(data.category ?? "General"),
    status: String(data.status ?? "pending"),
    assignedTo: String(data.assignedTo ?? ""),
    hostelName: String(data.hostelName ?? ""),
    roomNumber: String(data.roomNumber ?? ""),
    createdAt: parseFirestoreDate(data.createdAt),
  };
}

export function useFirestoreMaintenance() {
  const [requests, setRequests] = useState<MaintenanceRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const ref = collection(db, COLLECTIONS.maintenance);
    const unsub = onSnapshot(
      ref,
      (snap) => {
        const rows = snap.docs
          .map((d) => mapMaintenance(d.id, d.data() as Record<string, unknown>))
          .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
        setRequests(rows);
        setLoading(false);
        setError(null);
      },
      (err) => {
        setRequests([]);
        setLoading(false);
        setError(err.message || "Could not load maintenance");
      },
    );
    return () => unsub();
  }, []);

  return { requests, loading, error };
}
