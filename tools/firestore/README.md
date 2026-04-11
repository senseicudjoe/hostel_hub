# Firestore seed tools (HostelHub)

This folder contains a small script to populate Firestore **`rooms`** so the student **Explore** page can show data.

## What it writes

- **Collection**: `rooms`
- **Document ID**: `roomId`
- **Fields**: matches `lib/models/room_model.dart`

---

## If you cannot create a service account key (org policy)

Many schools/companies block **downloading** JSON keys (`iam.disableServiceAccountKeyCreation`). You still have options:

### 1) Use Application Default Credentials (no key file)

On your machine (needs [Google Cloud SDK](https://cloud.google.com/sdk) / `gcloud`):

```bash
gcloud auth application-default login
gcloud config set project hostelhub-976ee
```

Then:

```bash
cd tools/firestore
npm install
npm run seed:rooms:adc:dry
npm run seed:rooms:adc
```

Or explicitly:

```bash
node seed_rooms.js --file rooms.seed.json --project hostelhub-976ee --merge
```

This uses your **user** credentials via ADC, not a service account JSON file.

### 2) Run the same script in **Google Cloud Shell**

1. Open [Google Cloud Console](https://console.cloud.google.com) → select project **`hostelhub-976ee`**.
2. Click the **Cloud Shell** icon (terminal in the browser).
3. Upload this repo’s `tools/firestore` folder (or clone your repo), then:

```bash
cd tools/firestore
npm install
gcloud auth application-default login   # if needed
node seed_rooms.js --file rooms.seed.json --project hostelhub-976ee --merge
```

Cloud Shell often already has ADC; if the script errors, run `gcloud auth application-default login` once.

### 3) Manual entry in Firebase Console

1. [Firebase Console](https://console.firebase.google.com) → your project → **Firestore Database**.
2. **Start collection** → ID: `rooms`.
3. Add documents; use **Document ID** = `roomId` (e.g. `unity_u201`).
4. Fields (types): same as in `rooms.seed.json` (`hostelName`, `roomNumber`, `floor`, `capacity`, `currentOccupants`, `status`, `qrCode`).

Slow for hundreds of rooms, but fine for a few test rooms.

### 4) One-time Cloud Function (advanced)

Deploy a temporary HTTPS or callable function that writes seed data using the **default Cloud Functions service account** (no downloadable key on your laptop). Remove the function after seeding.

### 5) Ask your org admin

They can allow key creation for a specific service account, or run the seed script for you using Cloud Shell / CI.

---

## Prerequisites (service account JSON — if your org allows it)

1. Firebase Console → Project settings → **Service accounts** → **Generate new private key**.
2. Save the JSON locally **(do not commit it)**.

## Install

```bash
cd tools/firestore
npm install
```

## Run with a key file

```bash
cd tools/firestore
export GOOGLE_APPLICATION_CREDENTIALS="/ABS/PATH/TO/serviceAccountKey.json"
npm run seed:rooms:dry
npm run seed:rooms
```

## Edit the dataset

Update `tools/firestore/rooms.seed.json`.

**Node version:** use **Node 20+** (e.g. `nvm install 20`).
