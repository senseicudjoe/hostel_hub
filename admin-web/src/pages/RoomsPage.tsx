import { useEffect, useMemo, useState } from "react";
import { StatusBadge } from "../components/StatusBadge";
import { HOSTEL_NAMES, ROOM_STATUS } from "../config/constants";
import { useAllocations } from "../hooks/useAllocations";
import { useFirestoreRooms } from "../hooks/useFirestoreRooms";
import { useStudents } from "../hooks/useStudents";
import type { RoomRow } from "../types/models";
import {
  allocateStudentToRoom,
  createRoom,
  deallocateStudent,
  deleteRoom,
  updateRoom,
} from "../services/adminFirestore";

const STATUS_OPTIONS = [
  ROOM_STATUS.available,
  ROOM_STATUS.occupied,
  ROOM_STATUS.maintenance,
] as const;

export function RoomsPage() {
  const { rooms, loading, error } = useFirestoreRooms();
  const { students, loading: studentsLoading } = useStudents();
  const { allocations, loading: allocLoading } = useAllocations();

  const [flash, setFlash] = useState<{ type: "ok" | "err"; text: string } | null>(
    null,
  );
  const [busy, setBusy] = useState(false);

  const [hostelFilter, setHostelFilter] = useState<string | null>(null);

  const hostels = useMemo(() => {
    const fromData = [...new Set(rooms.map((r) => r.hostelName))].filter(Boolean);
    const merged = [...new Set([...HOSTEL_NAMES, ...fromData])].sort();
    return merged;
  }, [rooms]);

  useEffect(() => {
    if (hostels.length === 0) {
      setHostelFilter(null);
      return;
    }
    setHostelFilter((f) => (f && hostels.includes(f) ? f : hostels[0]!));
  }, [hostels]);

  const filteredRooms = useMemo(() => {
    if (!hostelFilter) return rooms;
    return rooms.filter((r) => r.hostelName === hostelFilter);
  }, [rooms, hostelFilter]);

  const count = (s: string) =>
    filteredRooms.filter((r) => r.status === s).length;

  // —— Add room ——
  const [newHostel, setNewHostel] = useState<string>(HOSTEL_NAMES[0]);
  const [newHostelCustom, setNewHostelCustom] = useState("");
  const [newNumber, setNewNumber] = useState("");
  const [newFloor, setNewFloor] = useState(1);
  const [newCap, setNewCap] = useState(2);

  // —— Assign ——
  const [assignStudentUid, setAssignStudentUid] = useState("");
  const [assignRoomId, setAssignRoomId] = useState("");

  // —— Edit room ——
  const [editing, setEditing] = useState<RoomRow | null>(null);
  const [editHostel, setEditHostel] = useState("");
  const [editNumber, setEditNumber] = useState("");
  const [editFloor, setEditFloor] = useState(1);
  const [editCap, setEditCap] = useState(2);
  const [editStatus, setEditStatus] = useState<string>(ROOM_STATUS.available);

  useEffect(() => {
    if (!editing) return;
    setEditHostel(editing.hostelName);
    setEditNumber(editing.roomNumber);
    setEditFloor(editing.floor);
    setEditCap(editing.capacity);
    setEditStatus(editing.status);
  }, [editing]);

  const studentName = (uid: string) =>
    students.find((s) => s.uid === uid)?.name ?? uid.slice(0, 8) + "…";

  return (
    <div className="mx-auto max-w-6xl space-y-8">
      <div>
        <h2 className="text-lg font-bold text-ink">Room management</h2>
        <p className="text-sm text-ink-muted">
          Add rooms, assign or remove students — same data as the mobile app (
          <code className="rounded bg-input px-1 text-xs">rooms</code>,{" "}
          <code className="rounded bg-input px-1 text-xs">allocations</code>,{" "}
          <code className="rounded bg-input px-1 text-xs">users</code>).
        </p>
      </div>

      {flash ? (
        <div
          className={`rounded-lg border px-4 py-3 text-sm ${
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

      {/* Add room */}
      <section className="rounded-xl border border-line bg-card p-5 shadow-card">
        <h3 className="mb-3 text-sm font-bold text-ink">Add room</h3>
        <form
          className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end"
          onSubmit={async (e) => {
            e.preventDefault();
            const hn =
              newHostel === "__custom__"
                ? newHostelCustom.trim()
                : newHostel;
            if (!hn || !newNumber.trim()) {
              setFlash({ type: "err", text: "Hostel and room number are required." });
              return;
            }
            setBusy(true);
            setFlash(null);
            try {
              await createRoom({
                hostelName: hn,
                roomNumber: newNumber.trim(),
                floor: newFloor,
                capacity: newCap,
              });
              setNewNumber("");
              setFlash({ type: "ok", text: "Room created." });
            } catch (err) {
              setFlash({
                type: "err",
                text: err instanceof Error ? err.message : "Could not create room.",
              });
            } finally {
              setBusy(false);
            }
          }}
        >
          <div className="min-w-[160px] flex-1">
            <label className="mb-1 block text-xs font-semibold text-ink-muted">
              Hostel
            </label>
            <select
              value={newHostel}
              onChange={(e) => setNewHostel(e.target.value)}
              className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
            >
              {HOSTEL_NAMES.map((h) => (
                <option key={h} value={h}>
                  {h}
                </option>
              ))}
              <option value="__custom__">Other (type below)</option>
            </select>
          </div>
          {newHostel === "__custom__" ? (
            <div className="min-w-[180px] flex-1">
              <label className="mb-1 block text-xs font-semibold text-ink-muted">
                Custom hostel name
              </label>
              <input
                value={newHostelCustom}
                onChange={(e) => setNewHostelCustom(e.target.value)}
                className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
                placeholder="Hostel name"
              />
            </div>
          ) : null}
          <div className="w-28">
            <label className="mb-1 block text-xs font-semibold text-ink-muted">
              Room #
            </label>
            <input
              value={newNumber}
              onChange={(e) => setNewNumber(e.target.value)}
              className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
              placeholder="204"
            />
          </div>
          <div className="w-20">
            <label className="mb-1 block text-xs font-semibold text-ink-muted">
              Floor
            </label>
            <input
              type="number"
              min={0}
              value={newFloor}
              onChange={(e) => setNewFloor(Number(e.target.value))}
              className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
            />
          </div>
          <div className="w-24">
            <label className="mb-1 block text-xs font-semibold text-ink-muted">
              Capacity
            </label>
            <input
              type="number"
              min={1}
              value={newCap}
              onChange={(e) => setNewCap(Number(e.target.value))}
              className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
            />
          </div>
          <button
            type="submit"
            disabled={busy || loading}
            className="rounded-lg bg-brand px-4 py-2 text-sm font-bold text-white hover:bg-brand-dark disabled:opacity-50"
          >
            Add room
          </button>
        </form>
      </section>

      {/* Assign student */}
      <section className="rounded-xl border border-line bg-card p-5 shadow-card">
        <h3 className="mb-3 text-sm font-bold text-ink">Assign student to room</h3>
        <p className="mb-3 text-xs text-ink-muted">
          Picks a student with no active allocation and increments room occupancy
          (same logic as the Flutter app).
        </p>
        <div className="flex flex-col gap-3 lg:flex-row lg:items-end">
          <div className="min-w-[200px] flex-1">
            <label className="mb-1 block text-xs font-semibold text-ink-muted">
              Student
            </label>
            <select
              value={assignStudentUid}
              onChange={(e) => setAssignStudentUid(e.target.value)}
              className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
              disabled={studentsLoading}
            >
              <option value="">Select student…</option>
              {students.map((s) => (
                <option key={s.uid} value={s.uid}>
                  {s.name} ({s.email})
                </option>
              ))}
            </select>
          </div>
          <div className="min-w-[200px] flex-1">
            <label className="mb-1 block text-xs font-semibold text-ink-muted">
              Room
            </label>
            <select
              value={assignRoomId}
              onChange={(e) => setAssignRoomId(e.target.value)}
              className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
              disabled={loading}
            >
              <option value="">Select room…</option>
              {rooms
                .filter(
                  (r) =>
                    r.status !== ROOM_STATUS.maintenance &&
                    r.currentOccupants < r.capacity,
                )
                .map((r) => (
                  <option key={r.id} value={r.id}>
                    {r.hostelName} · {r.roomNumber} ({r.currentOccupants}/
                    {r.capacity})
                  </option>
                ))}
            </select>
          </div>
          <button
            type="button"
            disabled={busy || !assignStudentUid || !assignRoomId}
            onClick={async () => {
              const room = rooms.find((r) => r.id === assignRoomId);
              if (!room) return;
              setBusy(true);
              setFlash(null);
              try {
                await allocateStudentToRoom(assignStudentUid, room);
                setFlash({ type: "ok", text: "Student assigned." });
              } catch (err) {
                setFlash({
                  type: "err",
                  text: err instanceof Error ? err.message : "Assignment failed.",
                });
              } finally {
                setBusy(false);
              }
            }}
            className="rounded-lg bg-brand px-4 py-2 text-sm font-bold text-white hover:bg-brand-dark disabled:opacity-50"
          >
            Assign
          </button>
        </div>
      </section>

      {/* Active allocations */}
      <section className="rounded-xl border border-line bg-card shadow-card">
        <div className="border-b border-line px-5 py-3">
          <h3 className="text-sm font-bold text-ink">Active room assignments</h3>
          <p className="text-xs text-ink-muted">
            Remove a student to free the bed (updates allocation, room counts, and
            their profile).
          </p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[560px] text-left text-sm">
            <thead>
              <tr className="border-b border-line bg-input/50 text-xs font-bold uppercase text-ink-muted">
                <th className="px-4 py-2">Student</th>
                <th className="px-4 py-2">Room</th>
                <th className="px-4 py-2">Hostel</th>
                <th className="px-4 py-2 w-28" />
              </tr>
            </thead>
            <tbody>
              {allocLoading ? (
                <tr>
                  <td colSpan={4} className="px-4 py-6 text-ink-muted">
                    Loading…
                  </td>
                </tr>
              ) : allocations.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-4 py-6 text-ink-muted">
                    No active allocations.
                  </td>
                </tr>
              ) : (
                allocations.map((a) => (
                  <tr key={a.id} className="border-b border-line last:border-0">
                    <td className="px-4 py-2 font-medium text-ink">
                      {studentName(a.studentUid)}
                    </td>
                    <td className="px-4 py-2">{a.roomNumber}</td>
                    <td className="px-4 py-2 text-ink-muted">{a.hostelName}</td>
                    <td className="px-4 py-2">
                      <button
                        type="button"
                        disabled={busy}
                        onClick={async () => {
                          setBusy(true);
                          setFlash(null);
                          try {
                            await deallocateStudent(
                              a.allocationId,
                              a.studentUid,
                              a.roomId,
                            );
                            setFlash({ type: "ok", text: "Student removed from room." });
                          } catch (err) {
                            setFlash({
                              type: "err",
                              text:
                                err instanceof Error
                                  ? err.message
                                  : "Could not remove.",
                            });
                          } finally {
                            setBusy(false);
                          }
                        }}
                        className="text-xs font-bold text-semantic-error hover:underline"
                      >
                        Remove
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* Browse by hostel */}
      <div>
        <h3 className="mb-2 text-sm font-bold text-ink">Rooms by hostel</h3>
        {loading ? (
          <p className="text-sm text-ink-muted">Loading rooms…</p>
        ) : null}
        {!loading && hostels.length > 0 ? (
          <div className="mb-3 flex flex-wrap gap-2">
            {hostels.map((h) => (
              <button
                key={h}
                type="button"
                onClick={() => setHostelFilter(h)}
                className={`rounded-full border px-3 py-1.5 text-xs font-semibold transition ${
                  hostelFilter === h
                    ? "border-brand bg-brand-light text-brand"
                    : "border-line bg-card text-ink-muted hover:border-brand/40"
                }`}
              >
                {h.split(" ")[0]}
              </button>
            ))}
          </div>
        ) : null}

        {!loading && rooms.length > 0 ? (
          <p className="mb-3 text-xs font-semibold text-ink-muted">
            Occupied {count("occupied")} · Available {count("available")} ·
            Maintenance {count("maintenance")}
          </p>
        ) : null}

        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {filteredRooms.map((room) => (
            <article
              key={room.id}
              className="rounded-xl border border-line bg-card p-4 shadow-card"
            >
              <div className="flex items-start justify-between gap-2">
                <div>
                  <p className="text-lg font-bold text-ink">
                    Room {room.roomNumber}
                  </p>
                  <p className="text-xs text-ink-muted">{room.hostelName}</p>
                </div>
                <StatusBadge status={room.status} />
              </div>
              <dl className="mt-3 grid grid-cols-2 gap-2 text-xs">
                <div>
                  <dt className="text-ink-hint">Floor</dt>
                  <dd className="font-semibold text-ink">{room.floor}</dd>
                </div>
                <div>
                  <dt className="text-ink-hint">Capacity</dt>
                  <dd className="font-semibold text-ink">{room.capacity}</dd>
                </div>
                <div className="col-span-2">
                  <dt className="text-ink-hint">Occupants</dt>
                  <dd className="font-semibold text-ink">
                    {room.currentOccupants} / {room.capacity}
                  </dd>
                </div>
              </dl>
              <div className="mt-3 flex flex-wrap gap-2 border-t border-line pt-3">
                <button
                  type="button"
                  onClick={() => setAssignRoomId(room.id)}
                  className="text-xs font-semibold text-brand hover:underline"
                >
                  Use in assign
                </button>
                <button
                  type="button"
                  onClick={() => setEditing(room)}
                  className="text-xs font-semibold text-ink-muted hover:text-ink"
                >
                  Edit
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={async () => {
                    if (
                      !confirm(
                        `Delete room ${room.roomNumber}? Only works if nobody is assigned.`,
                      )
                    )
                      return;
                    setBusy(true);
                    setFlash(null);
                    try {
                      await deleteRoom(room.id);
                      setFlash({ type: "ok", text: "Room deleted." });
                    } catch (err) {
                      setFlash({
                        type: "err",
                        text:
                          err instanceof Error ? err.message : "Could not delete.",
                      });
                    } finally {
                      setBusy(false);
                    }
                  }}
                  className="text-xs font-semibold text-semantic-error hover:underline"
                >
                  Delete
                </button>
              </div>
            </article>
          ))}
        </div>

        {!loading && filteredRooms.length === 0 ? (
          <p className="text-center text-sm text-ink-muted">
            {rooms.length === 0
              ? "No rooms yet — add one above."
              : "No rooms for this hostel filter."}
          </p>
        ) : null}
      </div>

      {/* Edit modal */}
      {editing ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4">
          <div className="w-full max-w-md rounded-xl border border-line bg-card p-6 shadow-card">
            <h4 className="mb-4 text-base font-bold text-ink">Edit room</h4>
            <div className="space-y-3">
              <div>
                <label className="mb-1 block text-xs font-semibold text-ink-muted">
                  Hostel
                </label>
                <input
                  value={editHostel}
                  onChange={(e) => setEditHostel(e.target.value)}
                  className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold text-ink-muted">
                  Room number
                </label>
                <input
                  value={editNumber}
                  onChange={(e) => setEditNumber(e.target.value)}
                  className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
                />
              </div>
              <div className="flex gap-3">
                <div className="flex-1">
                  <label className="mb-1 block text-xs font-semibold text-ink-muted">
                    Floor
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={editFloor}
                    onChange={(e) => setEditFloor(Number(e.target.value))}
                    className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
                  />
                </div>
                <div className="flex-1">
                  <label className="mb-1 block text-xs font-semibold text-ink-muted">
                    Capacity
                  </label>
                  <input
                    type="number"
                    min={1}
                    value={editCap}
                    onChange={(e) => setEditCap(Number(e.target.value))}
                    className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
                  />
                </div>
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold text-ink-muted">
                  Status
                </label>
                <select
                  value={editStatus}
                  onChange={(e) => setEditStatus(e.target.value)}
                  className="w-full rounded-lg border border-line bg-input px-3 py-2 text-sm"
                >
                  {STATUS_OPTIONS.map((s) => (
                    <option key={s} value={s}>
                      {s}
                    </option>
                  ))}
                </select>
              </div>
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setEditing(null)}
                className="rounded-lg border border-line px-4 py-2 text-sm font-semibold text-ink-muted"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={async () => {
                  setBusy(true);
                  setFlash(null);
                  try {
                    await updateRoom(editing.id, {
                      hostelName: editHostel,
                      roomNumber: editNumber,
                      floor: editFloor,
                      capacity: editCap,
                      status: editStatus,
                    });
                    setEditing(null);
                    setFlash({ type: "ok", text: "Room updated." });
                  } catch (err) {
                    setFlash({
                      type: "err",
                      text:
                        err instanceof Error ? err.message : "Could not update.",
                    });
                  } finally {
                    setBusy(false);
                  }
                }}
                className="rounded-lg bg-brand px-4 py-2 text-sm font-bold text-white"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
