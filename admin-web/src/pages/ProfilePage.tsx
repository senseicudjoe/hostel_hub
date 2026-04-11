import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function ProfilePage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  return (
    <div className="mx-auto max-w-lg space-y-6">
      <div>
        <h2 className="text-lg font-bold text-ink">Profile</h2>
        <p className="text-sm text-ink-muted">
          Loaded from Firebase Auth + Firestore{" "}
          <code className="rounded bg-input px-1 text-xs">users</code>.
        </p>
      </div>

      <div className="rounded-xl border border-line bg-card p-6 shadow-card">
        <div className="flex items-center gap-4">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-brand-light text-xl font-bold text-brand">
            {user?.name.charAt(0) ?? "?"}
          </div>
          <div className="min-w-0">
            <p className="truncate font-bold text-ink">{user?.name}</p>
            <p className="truncate text-sm text-ink-muted">{user?.email}</p>
            <p className="mt-1 text-xs font-semibold text-brand">Admin</p>
          </div>
        </div>

        <dl className="mt-6 space-y-3 border-t border-line pt-6 text-sm">
          <div className="flex justify-between gap-4">
            <dt className="text-ink-muted">UID</dt>
            <dd className="max-w-[60%] truncate font-mono text-xs text-ink">
              {user?.uid}
            </dd>
          </div>
          <div className="flex justify-between">
            <dt className="text-ink-muted">Role</dt>
            <dd className="font-semibold text-ink">{user?.role}</dd>
          </div>
          <div className="flex justify-between">
            <dt className="text-ink-muted">Member since</dt>
            <dd className="font-semibold text-ink">
              {user?.createdAt.toLocaleDateString()}
            </dd>
          </div>
        </dl>

        <button
          type="button"
          onClick={async () => {
            await logout();
            navigate("/login", { replace: true });
          }}
          className="mt-8 w-full rounded-lg border border-semantic-error/40 py-2.5 text-sm font-bold text-semantic-error transition hover:bg-semantic-error/5"
        >
          Sign out
        </button>
      </div>
    </div>
  );
}
