import { useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

const nav = [
  { to: "/dashboard", label: "Dashboard", icon: IconDashboard },
  { to: "/rooms", label: "Rooms", icon: IconRooms },
  { to: "/maintenance", label: "Maintenance", icon: IconWrench },
  { to: "/announcements", label: "Announce", icon: IconMegaphone },
  { to: "/profile", label: "Profile", icon: IconUser },
] as const;

export function AdminLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <div className="flex min-h-screen bg-surface">
      <aside
        className={`fixed inset-y-0 left-0 z-40 flex w-64 flex-col border-r border-line bg-card shadow-card transition-transform lg:static lg:translate-x-0 ${
          mobileOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="flex h-16 shrink-0 items-center gap-2 border-b border-line px-5">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-brand text-sm font-bold text-white">
            H
          </div>
          <div>
            <p className="text-sm font-bold text-ink">HostelHub</p>
            <p className="text-[11px] font-medium text-ink-muted">Admin</p>
          </div>
        </div>
        <nav className="flex flex-1 flex-col gap-0.5 overflow-y-auto p-3 pb-4">
          {nav.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              onClick={() => setMobileOpen(false)}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold transition-colors ${
                  isActive
                    ? "bg-brand-light text-brand"
                    : "text-ink-muted hover:bg-input hover:text-ink"
                }`
              }
            >
              <Icon className="h-5 w-5 shrink-0 opacity-90" />
              {label}
            </NavLink>
          ))}
        </nav>
        <div className="shrink-0 border-t border-line p-4">
          <p className="truncate text-xs font-medium text-ink">{user?.name}</p>
          <p className="truncate text-[11px] text-ink-muted">{user?.email}</p>
          <button
            type="button"
            onClick={async () => {
              await logout();
              navigate("/login", { replace: true });
            }}
            className="mt-3 w-full rounded-lg border border-line py-2 text-xs font-semibold text-ink-muted transition hover:bg-input hover:text-ink"
          >
            Sign out
          </button>
        </div>
      </aside>

      {mobileOpen ? (
        <button
          type="button"
          aria-label="Close menu"
          className="fixed inset-0 z-30 bg-ink/20 lg:hidden"
          onClick={() => setMobileOpen(false)}
        />
      ) : null}

      <div className="flex min-w-0 flex-1 flex-col lg:pl-0">
        <header className="sticky top-0 z-20 flex h-14 items-center gap-3 border-b border-line bg-brand px-4 text-white shadow-sm lg:h-16 lg:px-6">
          <button
            type="button"
            className="rounded-lg p-2 hover:bg-white/10 lg:hidden"
            aria-label="Open menu"
            onClick={() => setMobileOpen(true)}
          >
            <IconMenu className="h-6 w-6" />
          </button>
          <h1 className="text-base font-bold tracking-tight lg:text-lg">
            HostelHub Admin
          </h1>
        </header>
        <main className="flex-1 p-4 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

function IconMenu(props: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={props.className}>
      <path d="M4 6h16v2H4V6zm0 5h16v2H4v-2zm0 5h16v2H4v-2z" />
    </svg>
  );
}

function IconDashboard(props: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      className={props.className}
    >
      <path d="M4 13h6V4H4v9zm10 7h6V11h-6v9zM4 20h6v-5H4v5zm10-13h6V4h-6v3z" />
    </svg>
  );
}

function IconRooms(props: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      className={props.className}
    >
      <path d="M4 21V8l8-4 8 4v13M9 21V12h6v9" />
    </svg>
  );
}

function IconWrench(props: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      className={props.className}
    >
      <path d="M14.7 6.3a1 1 0 000 1.4l1.6 1.6a1 1 0 001.4 0l3.77-3.77a6 6 0 01-7.94 7.94l-6.91 6.91a2.12 2.12 0 01-3-3l6.91-6.91a6 6 0 017.94-7.94l-3.76 3.76z" />
    </svg>
  );
}

function IconMegaphone(props: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      className={props.className}
    >
      <path d="M3 11v3a1 1 0 001 1h2l4 4V7L6 10H4a1 1 0 00-1 1zM16 8a5 5 0 010 8M19 3a9 9 0 010 18" />
    </svg>
  );
}

function IconUser(props: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      className={props.className}
    >
      <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2M12 11a4 4 0 100-8 4 4 0 000 8z" />
    </svg>
  );
}
