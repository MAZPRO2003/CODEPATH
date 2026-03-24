import { 
  collection, addDoc, query, orderBy, onSnapshot, serverTimestamp 
} from "firebase/firestore";
import { db } from "../firebase";

export interface ChatMessage {
  id: string;
  text: string;
  senderId: string;
  senderName: string;
  timestamp: any;
}

export const sendBattleMessage = async (battleId: string, text: string, senderId: string, senderName: string) => {
  const collectionRef = collection(db, 'battles', battleId, 'messages');
  await addDoc(collectionRef, {
    text,
    senderId,
    senderName,
    timestamp: serverTimestamp()
  });
};

export const subscribeToBattleChat = (battleId: string, callback: (messages: ChatMessage[]) => void) => {
  const q = query(collection(db, 'battles', battleId, 'messages'), orderBy('timestamp', 'asc'));
  return onSnapshot(q, (snapshot) => {
    const msgs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as ChatMessage));
    callback(msgs);
  });
};
