import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-surface px-4">
      <div className="w-full max-w-md rounded-2xl border border-line bg-card p-8 shadow-card">
        <div className="mb-8 flex flex-col items-center text-center">
          <div className="mb-3 flex h-14 w-14 items-center justify-center rounded-xl bg-brand text-2xl font-bold text-white">
            H
          </div>
          <h1 className="text-xl font-bold text-ink">HostelHub Admin</h1>
          <p className="mt-1 text-sm text-ink-muted">
            Sign in with your admin Firebase account
          </p>
        </div>

        {error ? (
          <div className="mb-4 rounded-lg border border-semantic-error/30 bg-semantic-error/10 px-3 py-2 text-sm text-semantic-error">
            {error}
          </div>
        ) : null}

        <form
          className="space-y-4"
          onSubmit={async (e) => {
            e.preventDefault();
            setError(null);
            setBusy(true);
            try {
              await login(email, password);
              navigate("/dashboard", { replace: true });
            } catch (err) {
              const message =
                err instanceof Error ? err.message : "Sign in failed.";
              setError(message);
            } finally {
              setBusy(false);
            }
          }}
        >
          <div>
            <label
              htmlFor="email"
              className="mb-1 block text-xs font-semibold text-ink-muted"
            >
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="username"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                setError(null);
              }}
              placeholder="you@ashesi.edu.gh"
              className="w-full rounded-lg border border-line bg-input px-3 py-2.5 text-sm text-ink outline-none ring-brand/30 transition placeholder:text-ink-hint focus:border-brand focus:ring-2"
            />
          </div>
          <div>
            <label
              htmlFor="password"
              className="mb-1 block text-xs font-semibold text-ink-muted"
            >
              Password
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
                setError(null);
              }}
              placeholder="••••••••"
              className="w-full rounded-lg border border-line bg-input px-3 py-2.5 text-sm text-ink outline-none ring-brand/30 transition placeholder:text-ink-hint focus:border-brand focus:ring-2"
            />
          </div>
          <button
            type="submit"
            disabled={busy}
            className="w-full rounded-lg bg-brand py-3 text-sm font-bold text-white shadow-sm transition hover:bg-brand-dark disabled:opacity-60"
          >
            {busy ? "Signing in…" : "Sign in"}
          </button>
        </form>

        <p className="mt-6 text-center text-[11px] leading-relaxed text-ink-muted">
          Only users with <span className="font-semibold">role: admin</span> in
          the Firestore <code className="rounded bg-input px-1">users</code>{" "}
          doc can access this console. Adjust Security Rules if reads fail.
        </p>
      </div>
    </div>
  );
}
