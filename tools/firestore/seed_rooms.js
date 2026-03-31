#!/usr/bin/env node
/**
 * Seed Firestore `rooms` collection for HostelHub.
 *
 * Credentials (pick one):
 *   A) Service account JSON file (if your org allows key creation):
 *      GOOGLE_APPLICATION_CREDENTIALS=/abs/path/serviceAccountKey.json
 *      or FIREBASE_SERVICE_ACCOUNT_JSON=/abs/path/serviceAccountKey.json
 *   B) Application Default Credentials (no downloaded key — works with):
 *      - `gcloud auth application-default login` (local), or
 *      - Google Cloud Shell (often works out of the box)
 *      For (B) you must pass --project YOUR_PROJECT_ID (or set GOOGLE_CLOUD_PROJECT).
 *
 * Usage:
 *   cd tools/firestore
 *   npm install
 *   GOOGLE_APPLICATION_CREDENTIALS="/abs/path/key.json" node seed_rooms.js --file rooms.seed.json
 *   # or, without a key file:
 *   gcloud auth application-default login
 *   node seed_rooms.js --file rooms.seed.json --project hostelhub-976ee
 *
 * Options:
 *   --project hostelhub-976ee   (optional; otherwise inferred from credentials)
 *   --file rooms.seed.json
 *   --dry-run                  (print what would be written)
 *   --merge                    (use set(..., {merge:true}))
 */

const fs = require("node:fs");
const path = require("node:path");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  if (i === -1) return null;
  return process.argv[i + 1] ?? null;
}

function hasFlag(flag) {
  return process.argv.includes(flag);
}

const fileArg = argValue("--file") || "rooms.seed.json";
const projectArg = argValue("--project");
const dryRun = hasFlag("--dry-run");
const merge = hasFlag("--merge");

const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  process.env.FIREBASE_SERVICE_ACCOUNT_JSON ||
  "";

function resolveProjectId() {
  return (
    projectArg ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    null
  );
}

function initFirebaseAdmin() {
  if (serviceAccountPath) {
    const serviceAccount = loadJson(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: resolveProjectId() || serviceAccount.project_id,
    });
    return;
  }

  const projectId = resolveProjectId();
  if (!projectId) {
    console.error(
      [
        "No service account JSON path set, and no project id for Application Default Credentials.",
        "",
        "Option 1 — service account file (if allowed):",
        '  export GOOGLE_APPLICATION_CREDENTIALS="/abs/path/key.json"',
        "",
        "Option 2 — no key file (use gcloud ADC):",
        "  gcloud auth application-default login",
        "  gcloud config set project YOUR_PROJECT_ID",
        "  node seed_rooms.js --file rooms.seed.json --project YOUR_PROJECT_ID",
        "",
        "Or run the same from Google Cloud Shell (see tools/firestore/README.md).",
      ].join("\n"),
    );
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId,
  });
}

const admin = require("firebase-admin");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

function loadJson(p) {
  const abs = path.isAbsolute(p) ? p : path.resolve(process.cwd(), p);
  const raw = fs.readFileSync(abs, "utf8");
  return JSON.parse(raw);
}

function validateRoom(room) {
  const required = [
    "roomId",
    "hostelName",
    "roomNumber",
    "floor",
    "capacity",
    "currentOccupants",
    "status",
    "qrCode",
  ];
  for (const k of required) {
    if (!(k in room)) throw new Error(`Room missing required field: ${k}`);
  }
  if (typeof room.roomId !== "string" || room.roomId.trim() === "") {
    throw new Error("roomId must be a non-empty string");
  }
  if (typeof room.hostelName !== "string" || room.hostelName.trim() === "") {
    throw new Error("hostelName must be a non-empty string");
  }
  if (typeof room.roomNumber !== "string" || room.roomNumber.trim() === "") {
    throw new Error("roomNumber must be a non-empty string");
  }
  for (const k of ["floor", "capacity", "currentOccupants"]) {
    if (typeof room[k] !== "number" || !Number.isFinite(room[k])) {
      throw new Error(`${k} must be a number`);
    }
  }
  if (
    !["available", "occupied", "maintenance"].includes(String(room.status))
  ) {
    throw new Error(
      `status must be one of: available|occupied|maintenance (got ${room.status})`,
    );
  }
  if (typeof room.qrCode !== "string") throw new Error("qrCode must be a string");
}

async function main() {
  const seed = loadJson(fileArg);
  const rooms = Array.isArray(seed.rooms) ? seed.rooms : [];
  if (rooms.length === 0) {
    throw new Error(`No rooms found in ${fileArg} under key "rooms"`);
  }

  initFirebaseAdmin();

  const db = getFirestore();

  // Firestore batch limit is 500 operations.
  const chunks = [];
  for (let i = 0; i < rooms.length; i += 450) chunks.push(rooms.slice(i, i + 450));

  console.log(
    `Seeding ${rooms.length} room(s) into project "${admin.app().options.projectId}" (collection: rooms)` +
      (dryRun ? " [DRY RUN]" : "") +
      (merge ? " [MERGE]" : ""),
  );

  for (const [chunkIndex, chunk] of chunks.entries()) {
    if (dryRun) {
      console.log(`\nChunk ${chunkIndex + 1}/${chunks.length}`);
      for (const r of chunk) {
        validateRoom(r);
        console.log(`- rooms/${r.roomId}  (${r.hostelName} ${r.roomNumber})`);
      }
      continue;
    }

    const batch = db.batch();
    for (const r of chunk) {
      validateRoom(r);
      const docRef = db.collection("rooms").doc(r.roomId);
      const payload = {
        ...r,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      };
      batch.set(docRef, payload, merge ? { merge: true } : undefined);
    }
    await batch.commit();
    console.log(`Committed chunk ${chunkIndex + 1}/${chunks.length} (${chunk.length} docs)`);
  }

  console.log("Done.");
}

main().catch((e) => {
  console.error(e?.stack || String(e));
  process.exit(1);
});

