import { useMemo, useState } from "react";
import { StatusBadge } from "../components/StatusBadge";
import { useFirestoreMaintenance } from "../hooks/useFirestoreMaintenance";
import { updateMaintenanceRequest } from "../services/adminFirestore";

const filters = [
  "All",
  "Pending",
  "Assigned",
  "In Progress",
  "Resolved",
  "Cancelled",
  "Confirmed",
] as const;

const STATUS_VALUES = [
  "pending",
  "assigned",
  "in_progress",
  "resolved",
  "cancelled",
  "confirmed",
] as const;

function matchesFilter(
  status: string,
  statusFilter: (typeof filters)[number],
): boolean {
  if (statusFilter === "All") return true;
  const map: Record<string, string> = {
    Pending: "pending",
    Assigned: "assigned",
    "In Progress": "in_progress",
    Resolved: "resolved",
    Cancelled: "cancelled",
    Confirmed: "confirmed",
  };
  return status === map[statusFilter];
}

export function MaintenancePage() {
  const { requests, loading, error } = useFirestoreMaintenance();
  const [statusFilter, setStatusFilter] =
    useState<(typeof filters)[number]>("All");
  const [search, setSearch] = useState("");
  const [busyId, setBusyId] = useState<string | null>(null);
  const [flash, setFlash] = useState<{ type: "ok" | "err"; text: string } | null>(
    null,
  );

  /** Local draft per request id for status + assignee before Save */
  const [drafts, setDrafts] = useState<
    Record<string, { status: string; assignedTo: string }>
  >({});

  const filtered = useMemo(() => {
    return requests.filter((r) => {
      const okStatus = matchesFilter(r.status, statusFilter);
      const q = search.toLowerCase();
      const okSearch =
        !q ||
        r.title.toLowerCase().includes(q) ||
        r.requestId.toLowerCase().includes(q) ||
        r.studentUid.toLowerCase().includes(q);
      return okStatus && okSearch;
    });
  }, [requests, statusFilter, search]);

  return (
    <div className="mx-auto max-w-7xl space-y-4">
      <div>
        <h2 className="text-lg font-bold text-ink">Maintenance</h2>
        <p className="text-sm text-ink-muted">
          Status changes save to Firestore; students see updates in the app via
          live listeners on their own requests.
        </p>
      </div>

      {flash ? (
        <div
          className={`rounded-lg border px-4 py-2 text-sm ${
            flash.type === "ok"
              ? "border-semantic-success/30 bg-semantic-success/10 text-semantic-success"
              : "border-semantic-error/30 bg-semantic-error/10 text-semantic-error"
          }`}
        >
          {flash.text}
        </div>
      ) : null}

      {error ? (
        <div className="rounded-lg border border-semantic-error/30 bg-semantic-error/10 px-4 py-3 text-sm text-semantic-error">
          {error}
        </div>
      ) : null}

      <div className="rounded-xl border border-line bg-card shadow-card">
        <div className="border-b border-line p-4">
          <input
            type="search"
            placeholder="Search by ID, title, or student UID…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-line bg-input px-3 py-2.5 text-sm outline-none ring-brand/20 focus:border-brand focus:ring-2"
          />
        </div>
        <div className="flex flex-wrap gap-2 border-b border-line px-4 py-3">
          {filters.map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => setStatusFilter(s)}
              className={`rounded-full border px-3 py-1.5 text-xs font-semibold ${
                statusFilter === s
                  ? "border-brand bg-brand-light text-brand"
                  : "border-transparent bg-input text-ink-muted hover:text-ink"
              }`}
            >
              {s}
            </button>
          ))}
        </div>
        <p className="border-b border-line px-4 py-2 text-xs font-semibold text-ink-muted">
          {loading
            ? "Loading…"
            : `${filtered.length} request${filtered.length === 1 ? "" : "s"}`}
        </p>

        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px] text-left text-sm">
            <thead>
              <tr className="border-b border-line bg-input/50 text-xs font-bold uppercase tracking-wide text-ink-muted">
                <th className="px-3 py-3">ID</th>
                <th className="px-3 py-3">Title</th>
                <th className="px-3 py-3">Student</th>
                <th className="px-3 py-3">Status</th>
                <th className="px-3 py-3">Created</th>
                <th className="px-3 py-3 min-w-[280px]">Update (admin)</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((r) => {
                const draft = drafts[r.requestId] ?? {
                  status: r.status,
                  assignedTo: r.assignedTo,
                };
                return (
                  <tr
                    key={r.id}
                    className="border-b border-line last:border-0 hover:bg-input/30"
                  >
                    <td className="px-3 py-3 font-mono text-[11px] text-ink-muted">
                      {r.requestId}
                    </td>
                    <td className="max-w-[180px] px-3 py-3 font-medium text-ink">
                      {r.title}
                    </td>
                    <td className="px-3 py-3 font-mono text-[11px] text-ink-muted">
                      {r.studentUid}
                    </td>
                    <td className="px-3 py-3">
                      <StatusBadge status={r.status} />
                    </td>
                    <td className="whitespace-nowrap px-3 py-3 text-ink-muted">
                      {r.createdAt.toLocaleDateString()}
                    </td>
                    <td className="px-3 py-3 align-top">
                      <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
                        <select
                          value={draft.status}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [r.requestId]: {
                                ...draft,
                                status: e.target.value,
                              },
                            }))
                          }
                          className="rounded border border-line bg-input px-2 py-1.5 text-xs font-medium"
                        >
                          {STATUS_VALUES.map((s) => (
                            <option key={s} value={s}>
                              {s}
                            </option>
                          ))}
                        </select>
                        <input
                          type="text"
                          placeholder="Assigned to (optional)"
                          value={draft.assignedTo}
                          onChange={(e) =>
                            setDrafts((prev) => ({
                              ...prev,
                              [r.requestId]: {
                                ...draft,
                                assignedTo: e.target.value,
                              },
                            }))
                          }
                          className="min-w-[140px] flex-1 rounded border border-line bg-input px-2 py-1.5 text-xs"
                        />
                        <button
                          type="button"
                          disabled={busyId === r.requestId}
                          onClick={async () => {
                            setBusyId(r.requestId);
                            setFlash(null);
                            try {
                              await updateMaintenanceRequest({
                                requestId: r.requestId,
                                status: draft.status,
                                assignedTo: draft.assignedTo,
                              });
                              setDrafts((prev) => {
                                const next = { ...prev };
                                delete next[r.requestId];
                                return next;
                              });
                              setFlash({
                                type: "ok",
                                text: `Updated ${r.requestId}.`,
                              });
                            } catch (err) {
                              setFlash({
                                type: "err",
                                text:
                                  err instanceof Error
                                    ? err.message
                                    : "Update failed.",
                              });
                            } finally {
                              setBusyId(null);
                            }
                          }}
                          className="rounded-lg bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-dark disabled:opacity-50"
                        >
                          {busyId === r.requestId ? "…" : "Save"}
                        </button>
                      </div>
                      {r.assignedTo ? (
                        <p className="mt-1 text-[10px] text-ink-hint">
                          Current: {r.assignedTo}
                        </p>
                      ) : null}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {!loading && filtered.length === 0 ? (
          <p className="p-8 text-center text-sm text-ink-muted">
            No requests match your filter.
          </p>
        ) : null}
      </div>
    </div>
  );
}
