import { collection, onSnapshot, query, where } from "firebase/firestore";
import { useEffect, useState } from "react";
import { db } from "../config/firebase";
import { COLLECTIONS, ROLE_STUDENT } from "../config/constants";
export interface StudentRow {
  uid: string;
  name: string;
  email: string;
}

export function useStudents() {
  const [students, setStudents] = useState<StudentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, COLLECTIONS.users),
      where("role", "==", ROLE_STUDENT),
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        const rows: StudentRow[] = snap.docs.map((d) => {
          const data = d.data() as Record<string, unknown>;
          return {
            uid: d.id,
            name: String(data.name ?? ""),
            email: String(data.email ?? ""),
          };
        });
        rows.sort((a, b) => a.name.localeCompare(b.name));
        setStudents(rows);
        setLoading(false);
        setError(null);
      },
      (err) => {
        setStudents([]);
        setLoading(false);
        setError(err.message || "Could not load students");
      },
    );
    return () => unsub();
  }, []);

  return { students, loading, error };
}
