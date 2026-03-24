import { collection, getDocs, query, orderBy, limit } from "firebase/firestore";
import { db } from "../firebase";

export interface AppUser {
  id: string;
  name: string;
  email: string;
  rating: number;
  isOnline: boolean;
  friends: string[];
}

export const getLeaderboardUsers = async (): Promise<AppUser[]> => {
  try {
    const q = query(
      collection(db, 'users'),
      orderBy('rating', 'desc'),
      limit(50)
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    } as AppUser));
  } catch (error) {
    console.error("Error fetching leaderboard:", error);
    return [];
  }
};
