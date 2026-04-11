import { useMemo } from "react";
import { useAuth } from "../auth/AuthContext";
import { useFirestoreMaintenance } from "../hooks/useFirestoreMaintenance";

function last7DayCounts(
  requests: { createdAt: Date }[],
): { label: string; count: number }[] {
  const labels: string[] = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() - i);
    labels.push(
      d.toLocaleDateString(undefined, { weekday: "short", day: "numeric" }),
    );
  }
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  start.setDate(start.getDate() - 6);
  const counts = [0, 0, 0, 0, 0, 0, 0];
  for (const r of requests) {
    const t = r.createdAt.getTime();
    if (t < start.getTime()) continue;
    const dayIndex = Math.floor((t - start.getTime()) / 86_400_000);
    if (dayIndex >= 0 && dayIndex < 7) counts[dayIndex]++;
  }
  return labels.map((label, i) => ({ label, count: counts[i] ?? 0 }));
}

function formatRelative(d: Date): string {
  const diff = Date.now() - d.getTime();
  const h = Math.floor(diff / 3_600_000);
  if (h < 1) return "Just now";
  if (h < 24) return `${h}h ago`;
  const days = Math.floor(h / 24);
  if (days === 1) return "Yesterday";
  return `${days}d ago`;
}

export function DashboardPage() {
  const { user } = useAuth();
  const { requests, loading, error } = useFirestoreMaintenance();
  const first = user?.name.split(" ")[0] ?? "Admin";

  const total = requests.length;
  const pending = requests.filter((r) => r.status === "pending").length;
  const resolved = requests.filter((r) => r.status === "resolved").length;
  const inProg = requests.filter((r) => r.status === "in_progress").length;

  const categoryRows = useMemo(() => {
    const m = new Map<string, number>();
    for (const r of requests) {
      const c = r.category?.trim() || "General";
      m.set(c, (m.get(c) ?? 0) + 1);
    }
    return [...m.entries()]
      .sort((a, b) => b[1] - a[1])
      .map(([label, count]) => ({ label, count }));
  }, [requests]);

  const maxCat = Math.max(...categoryRows.map((c) => c.count), 1);

  const week = useMemo(() => last7DayCounts(requests), [requests]);
  const maxWeek = Math.max(...week.map((w) => w.count), 1);

  const recent = useMemo(
    () =>
      requests.slice(0, 6).map((r) => ({
        text: `${r.requestId}: ${r.title}`,
        time: formatRelative(r.createdAt),
      })),
    [requests],
  );

  return (
    <div className="mx-auto max-w-6xl space-y-8">
      <div>
        <h2 className="text-lg font-bold text-ink lg:text-xl">
          Good morning, {first}
        </h2>
        <p className="text-sm text-ink-muted">
          Here&apos;s what&apos;s happening in your hostels today
        </p>
      </div>

      {error ? (
        <div className="rounded-lg border border-semantic-error/30 bg-semantic-error/10 px-4 py-3 text-sm text-semantic-error">
          {error}
        </div>
      ) : null}

      <section>
        <h3 className="mb-3 text-sm font-bold text-ink">Overview</h3>
        {loading ? (
          <p className="text-sm text-ink-muted">Loading maintenance stats…</p>
        ) : (
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <KpiCard
              title="Total requests"
              value={String(total)}
              hint="Firestore"
              accent="bg-semantic-info"
            />
            <KpiCard
              title="Pending"
              value={String(pending)}
              hint="Awaiting action"
              accent="bg-semantic-warning"
            />
            <KpiCard
              title="Resolved"
              value={String(resolved)}
              hint="Completed"
              accent="bg-semantic-success"
            />
            <KpiCard
              title="In progress"
              value={String(inProg)}
              hint="Active work"
              accent="bg-brand"
            />
          </div>
        )}
      </section>

      <section className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-xl border border-line bg-card p-5 shadow-card">
          <h3 className="mb-4 text-sm font-bold text-ink">Requests by category</h3>
          {categoryRows.length === 0 ? (
            <p className="text-sm text-ink-muted">No requests yet.</p>
          ) : (
            <ul className="space-y-3">
              {categoryRows.map((c) => (
                <li key={c.label}>
                  <div className="mb-1 flex justify-between text-xs font-semibold">
                    <span className="text-ink">{c.label}</span>
                    <span className="text-ink-muted">{c.count}</span>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-input">
                    <div
                      className="h-full rounded-full bg-brand transition-all"
                      style={{ width: `${(c.count / maxCat) * 100}%` }}
                    />
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="rounded-xl border border-line bg-card p-5 shadow-card">
          <h3 className="mb-4 text-sm font-bold text-ink">Last 7 days</h3>
          <div className="flex h-36 items-end justify-between gap-1 px-1">
            {week.map((w, i) => (
              <div key={w.label} className="flex flex-1 flex-col items-center gap-2">
                <div
                  className="w-full max-w-[2.5rem] rounded-t-md"
                  style={{
                    height: `${Math.max(10, (w.count / maxWeek) * 100)}%`,
                    minHeight: "6px",
                    background:
                      i === week.length - 1
                        ? "#A53A3E"
                        : "rgba(165, 58, 62, 0.25)",
                  }}
                />
                <span className="text-center text-[9px] font-semibold leading-tight text-ink-muted">
                  {w.label}
                </span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="rounded-xl border border-line bg-card p-5 shadow-card">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-sm font-bold text-ink">Recent maintenance</h3>
        </div>
        {recent.length === 0 ? (
          <p className="text-sm text-ink-muted">No recent requests.</p>
        ) : (
          <ul className="divide-y divide-line">
            {recent.map((a, i) => (
              <li
                key={i}
                className="flex items-center justify-between gap-3 py-3 text-sm first:pt-0 last:pb-0"
              >
                <span className="min-w-0 truncate text-ink">{a.text}</span>
                <span className="shrink-0 text-xs text-ink-muted">{a.time}</span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

function KpiCard({
  title,
  value,
  hint,
  accent,
}: {
  title: string;
  value: string;
  hint: string;
  accent: string;
}) {
  return (
    <div className="relative overflow-hidden rounded-xl border border-line bg-card p-4 shadow-card">
      <div className={`absolute left-0 top-0 h-full w-1 ${accent}`} />
      <p className="text-xs font-semibold text-ink-muted">{title}</p>
      <p className="mt-1 text-2xl font-bold text-ink">{value}</p>
      <p className="mt-1 text-[11px] text-ink-hint">{hint}</p>
    </div>
  );
}
