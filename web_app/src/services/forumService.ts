import { collection, getDocs, addDoc, serverTimestamp, query, orderBy } from "firebase/firestore";
import { db, auth } from "../firebase";

export interface ForumPost {
  id: string;
  title: string;
  content: string;
  author: string;
  authorId: string;
  timestamp: any;
  replyCount: number;
}

export const getPosts = async (): Promise<ForumPost[]> => {
  try {
    const q = query(collection(db, 'forum_posts'), orderBy('timestamp', 'desc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    } as ForumPost));
  } catch (error) {
    console.error("Error fetching forum posts:", error);
    return [];
  }
};

export const createPost = async (title: string, content: string) => {
  const user = auth.currentUser;
  if (!user) return;

  try {
    // Fetch user name from profile if available, else use email
    const name = user.displayName || user.email?.split('@')[0] || 'Anonymous';
    
    await addDoc(collection(db, 'forum_posts'), {
      title,
      content,
      author: name,
      authorId: user.uid,
      timestamp: serverTimestamp(),
      replyCount: 0
    });
  } catch (error) {
    console.error("Error creating post:", error);
  }
};
