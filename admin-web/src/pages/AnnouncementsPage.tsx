import { useState } from "react";
import { doc, serverTimestamp, setDoc } from "firebase/firestore";
import { useAuth } from "../auth/AuthContext";
import { db } from "../config/firebase";
import { COLLECTIONS } from "../config/constants";
import { audienceOptions } from "../data/mockData";
import {
  mapAudienceToTargetRole,
  type AudienceOption,
} from "../lib/announcementAudience";

function newAnnouncementId(): string {
  const raw = crypto.randomUUID().replace(/-/g, "");
  return `ann_${raw.slice(0, 12)}`;
}

export function AnnouncementsPage() {
  const { user } = useAuth();
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [audience, setAudience] = useState<AudienceOption>("All Residents");
  const [scheduled, setScheduled] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h2 className="text-lg font-bold text-ink">Compose announcement</h2>
        <p className="text-sm text-ink-muted">
          Publishes to Firestore{" "}
          <code className="rounded bg-input px-1 text-xs">announcements</code>.
          Hall names still map to{" "}
          <code className="rounded bg-input px-1 text-xs">targetRole: all</code>{" "}
          until the mobile schema adds a hall field.
        </p>
      </div>

      {toast ? (
        <div className="rounded-lg border border-semantic-success/30 bg-semantic-success/10 px-4 py-3 text-sm font-medium text-semantic-success">
          {toast}
        </div>
      ) : null}

      {error ? (
        <div className="rounded-lg border border-semantic-error/30 bg-semantic-error/10 px-4 py-3 text-sm text-semantic-error">
          {error}
        </div>
      ) : null}

      <form
        className="space-y-5 rounded-xl border border-line bg-card p-6 shadow-card"
        onSubmit={async (e) => {
          e.preventDefault();
          setError(null);
          setToast(null);
          if (!title.trim() || !body.trim()) {
            setError("Add a title and body first.");
            return;
          }
          if (scheduled) {
            setError(
              "Scheduled sends are not implemented yet (needs Cloud Scheduler or Functions). Uncheck “Schedule” to publish now.",
            );
            return;
          }
          if (!user) {
            setError("You must be signed in.");
            return;
          }
          setBusy(true);
          try {
            const announcementId = newAnnouncementId();
            await setDoc(
              doc(db, COLLECTIONS.announcements, announcementId),
              {
                announcementId,
                title: title.trim(),
                body: body.trim(),
                sentBy: user.name,
                targetRole: mapAudienceToTargetRole(audience),
                createdAt: serverTimestamp(),
              },
            );
            setTitle("");
            setBody("");
            setScheduled(false);
            setToast("Announcement published to Firestore.");
            setTimeout(() => setToast(null), 5000);
          } catch (err) {
            setError(
              err instanceof Error
                ? err.message
                : "Could not publish announcement.",
            );
          } finally {
            setBusy(false);
          }
        }}
      >
        <div>
          <label className="mb-1 block text-xs font-semibold text-ink-muted">
            Title
          </label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full rounded-lg border border-line bg-input px-3 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
            placeholder="e.g. Water shutdown — Block B"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-semibold text-ink-muted">
            Message
          </label>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            rows={5}
            className="w-full resize-y rounded-lg border border-line bg-input px-3 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
            placeholder="Write the announcement body…"
          />
        </div>
        <div>
          <label className="mb-1 block text-xs font-semibold text-ink-muted">
            Audience
          </label>
          <select
            value={audience}
            onChange={(e) =>
              setAudience(e.target.value as AudienceOption)
            }
            className="w-full rounded-lg border border-line bg-input px-3 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
          >
            {audienceOptions.map((o) => (
              <option key={o} value={o}>
                {o}
              </option>
            ))}
          </select>
        </div>

        <label className="flex cursor-pointer items-center gap-2 text-sm font-medium text-ink">
          <input
            type="checkbox"
            checked={scheduled}
            onChange={(e) => {
              setScheduled(e.target.checked);
              setError(null);
            }}
            className="h-4 w-4 rounded border-line text-brand focus:ring-brand"
          />
          Schedule send (not wired yet)
        </label>

        {scheduled ? (
          <div>
            <label className="mb-1 block text-xs font-semibold text-ink-muted">
              Send at
            </label>
            <input
              type="datetime-local"
              className="w-full rounded-lg border border-line bg-input px-3 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
            />
          </div>
        ) : null}

        <div className="flex flex-wrap gap-3 pt-2">
          <button
            type="submit"
            disabled={busy}
            className="rounded-lg bg-brand px-5 py-2.5 text-sm font-bold text-white hover:bg-brand-dark disabled:opacity-60"
          >
            {busy ? "Publishing…" : scheduled ? "Schedule" : "Send now"}
          </button>
          <button
            type="button"
            className="rounded-lg border border-line px-5 py-2.5 text-sm font-semibold text-ink-muted hover:bg-input"
            onClick={() => {
              setTitle("");
              setBody("");
              setScheduled(false);
              setToast(null);
              setError(null);
            }}
          >
            Clear
          </button>
        </div>
      </form>
    </div>
  );
}
