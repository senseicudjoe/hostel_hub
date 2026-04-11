const STYLES: Record<string, string> = {
  pending:
    "bg-semantic-warning/15 text-amber-900 border-amber-200",
  assigned:
    "bg-status-submitted/10 text-status-submitted border-blue-200",
  in_progress:
    "bg-status-inprogress/10 text-status-inprogress border-orange-200",
  resolved:
    "bg-semantic-success/10 text-semantic-success border-green-200",
  cancelled:
    "bg-ink-muted/10 text-ink-muted border-line",
  confirmed:
    "bg-status-acknowledged/10 text-status-acknowledged border-purple-200",
  occupied:
    "bg-brand-light text-brand-dark border-brand-light",
  available:
    "bg-semantic-success/10 text-semantic-success border-green-100",
  maintenance:
    "bg-ink-muted/10 text-ink-muted border-line",
  default:
    "bg-input text-ink-muted border-line",
};

function normalizeKey(status: string): string {
  return status.toLowerCase().trim().replace(/\s+/g, "_");
}

function labelFor(status: string): string {
  const k = normalizeKey(status);
  const map: Record<string, string> = {
    pending: "Pending",
    assigned: "Assigned",
    in_progress: "In progress",
    resolved: "Resolved",
    cancelled: "Cancelled",
    confirmed: "Confirmed",
    occupied: "Occupied",
    available: "Available",
    maintenance: "Maintenance",
  };
  return map[k] ?? status;
}

export function StatusBadge({ status }: { status: string }) {
  const key = normalizeKey(status);
  const cls = STYLES[key] ?? STYLES.default;
  return (
    <span
      className={`inline-flex rounded-full border px-2.5 py-0.5 text-xs font-semibold ${cls}`}
    >
      {labelFor(status)}
    </span>
  );
}
