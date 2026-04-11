import { getApp, getApps, initializeApp, type FirebaseApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

/**
 * Same Web app as Flutter `lib/firebase_options.dart` → `DefaultFirebaseOptions.web`.
 * Client API keys are not secret; protect data with Firestore Security Rules.
 */
const firebaseConfig = {
  apiKey: "AIzaSyDWdKZOKTK8fUTuSlOWI-9aFVWIGNQUtKg",
  appId: "1:619553419913:web:e87a0eef7b9a0e1a264c58",
  messagingSenderId: "619553419913",
  projectId: "hostelhub-976ee",
  authDomain: "hostelhub-976ee.firebaseapp.com",
  storageBucket: "hostelhub-976ee.firebasestorage.app",
  measurementId: "G-KF24TCKXDJ",
};

const app: FirebaseApp = getApps().length
  ? getApp()
  : initializeApp(firebaseConfig);

export const firebaseApp = app;
export const auth = getAuth(app);
export const db = getFirestore(app);
