import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  type User,
} from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "../config/firebase";
import { COLLECTIONS, ROLE_ADMIN } from "../config/constants";
import { parseFirestoreDate } from "../lib/timestamp";

export interface AdminUser {
  uid: string;
  name: string;
  email: string;
  role: string;
  createdAt: Date;
}

interface AuthState {
  user: AdminUser | null;
  authReady: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

async function loadProfile(uid: string): Promise<AdminUser | null> {
  const snap = await getDoc(doc(db, COLLECTIONS.users, uid));
  if (!snap.exists()) return null;
  const data = snap.data() as Record<string, unknown>;
  const role = String(data.role ?? "");
  if (role !== ROLE_ADMIN) return null;
  return {
    uid,
    name: String(data.name ?? ""),
    email: String(data.email ?? ""),
    role,
    createdAt: parseFirestoreDate(data.createdAt),
  };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [authReady, setAuthReady] = useState(false);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (fbUser: User | null) => {
      if (!fbUser) {
        setUser(null);
        setAuthReady(true);
        return;
      }
      try {
        const profile = await loadProfile(fbUser.uid);
        if (!profile) {
          await firebaseSignOut(auth);
          setUser(null);
        } else {
          setUser(profile);
        }
      } catch {
        await firebaseSignOut(auth);
        setUser(null);
      } finally {
        setAuthReady(true);
      }
    });
    return () => unsub();
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const cred = await signInWithEmailAndPassword(
      auth,
      email.trim(),
      password,
    );
    const profile = await loadProfile(cred.user.uid);
    if (!profile) {
      await firebaseSignOut(auth);
      throw new Error(
        "This account is not an admin, or your user profile is missing in Firestore.",
      );
    }
    setUser(profile);
  }, []);

  const logout = useCallback(async () => {
    await firebaseSignOut(auth);
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({ user, authReady, login, logout }),
    [user, authReady, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
