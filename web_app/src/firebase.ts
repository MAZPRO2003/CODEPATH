import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyC99acqH_0y2M3CaqwZMePsF10_8gf9e2I",
  authDomain: "codechef-779c2.firebaseapp.com",
  projectId: "codechef-779c2",
  storageBucket: "codechef-779c2.firebasestorage.app",
  messagingSenderId: "559509235392",
  appId: "1:559509235392:web:9bbfd91216f83d4f186f25",
  measurementId: "G-ZQDEV5P363"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);

export default app;
