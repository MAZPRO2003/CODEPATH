import { 
  collection, doc, setDoc, deleteDoc, updateDoc, 
  onSnapshot, query, where, orderBy, getDocs, 
  serverTimestamp, getDoc 
} from "firebase/firestore";
import { db, auth } from "../firebase";

export const startMatchmaking = (onMatch: (battleId: string) => void) => {
  const uid = auth.currentUser?.uid;
  if (!uid) return () => {};

  const queueRef = collection(db, 'matchmaking_queue');
  const myQueueDoc = doc(queueRef, uid);

  // 1. Join queue
  setDoc(myQueueDoc, {
    timestamp: serverTimestamp(),
    status: 'waiting',
    battleId: null,
  });

  // 2. Listen for matches found by others
  const unsubscribeMyQueue = onSnapshot(myQueueDoc, async (snapshot) => {
    if (snapshot.exists()) {
      const data = snapshot.data();
      if (data.status === 'matched' && data.battleId) {
        unsubscribeMyQueue();
        onMatch(data.battleId);
        await deleteDoc(myQueueDoc);
      }
    }
  });

  // 3. Active matchmaking search loop
  const interval = setInterval(async () => {
    try {
      const q = query(queueRef, where('status', '==', 'waiting'), orderBy('timestamp'));
      const snapshot = await getDocs(q);

      for (const queueDoc of snapshot.docs) {
        if (queueDoc.id !== uid) {
          // Found an opponent!
          const battleRef = doc(collection(db, 'battles'));
          const battleId = battleRef.id;

          // Create Battle Document
          await setDoc(battleRef, {
            player1_id: uid,
            player2_id: queueDoc.id,
            player1_progress: 0.0,
            player2_progress: 0.0,
            status: 'ongoing',
            created_at: serverTimestamp(),
          });

          // Match the opponent
          await updateDoc(doc(queueRef, queueDoc.id), {
            status: 'matched',
            battleId: battleId
          });

          // Stop loop and cleanup myself
          clearInterval(interval);
          unsubscribeMyQueue();
          onMatch(battleId);
          await deleteDoc(myQueueDoc);
          break;
        }
      }
    } catch (error) {
      console.error("Matchmaking cycle error:", error);
    }
  }, 3000);

  // Return cleanup/cancel function
  return () => {
    clearInterval(interval);
    unsubscribeMyQueue();
    deleteDoc(myQueueDoc).catch(() => {});
  };
};

export const updateProgress = async (battleId: string, progress: number) => {
  const uid = auth.currentUser?.uid;
  if (!uid) return;

  const battleRef = doc(db, 'battles', battleId);
  const snap = await getDoc(battleRef);

  if (snap.exists()) {
    const data = snap.data();
    const isPlayer1 = data.player1_id === uid;
    const field = isPlayer1 ? 'player1_progress' : 'player2_progress';

    await updateDoc(battleRef, {
      [field]: progress
    });
  }
};

export const subscribeToBattle = (battleId: string, onUpdate: (data: any) => void) => {
  return onSnapshot(doc(db, 'battles', battleId), (snapshot) => {
    if (snapshot.exists()) {
      onUpdate(snapshot.data());
    }
  });
};
