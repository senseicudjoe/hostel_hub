import { Navigate, Outlet, Route, Routes } from "react-router-dom";
import { useAuth } from "./auth/AuthContext";
import { AdminLayout } from "./components/AdminLayout";
import { AnnouncementsPage } from "./pages/AnnouncementsPage";
import { DashboardPage } from "./pages/DashboardPage";
import { LoginPage } from "./pages/LoginPage";
import { MaintenancePage } from "./pages/MaintenancePage";
import { ProfilePage } from "./pages/ProfilePage";
import { RoomsPage } from "./pages/RoomsPage";

function AuthLoading() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-surface text-sm text-ink-muted">
      Loading…
    </div>
  );
}

function LoginGate() {
  const { user, authReady } = useAuth();
  if (!authReady) return <AuthLoading />;
  if (user) return <Navigate to="/dashboard" replace />;
  return <LoginPage />;
}

function RequireAuth() {
  const { user, authReady } = useAuth();
  if (!authReady) return <AuthLoading />;
  if (!user) return <Navigate to="/login" replace />;
  return <Outlet />;
}

function RootRedirect() {
  const { user, authReady } = useAuth();
  if (!authReady) return <AuthLoading />;
  return <Navigate to={user ? "/dashboard" : "/login"} replace />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginGate />} />
      <Route path="/" element={<RootRedirect />} />
      <Route element={<RequireAuth />}>
        <Route element={<AdminLayout />}>
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/rooms" element={<RoomsPage />} />
          <Route path="/maintenance" element={<MaintenancePage />} />
          <Route path="/announcements" element={<AnnouncementsPage />} />
          <Route path="/profile" element={<ProfilePage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
