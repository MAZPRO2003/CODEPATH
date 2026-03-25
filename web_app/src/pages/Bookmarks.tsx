import React, { useEffect, useState } from 'react';
import { db, auth } from '../firebase';
import { collection, query, where, getDocs, deleteDoc, doc } from 'firebase/firestore';
import { useNavigate } from 'react-router-dom';

interface Bookmark {
  id: string;
  title: string;
  difficulty: string;
  company: string;
  url: string;
}

const Bookmarks: React.FC = () => {
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  const fetchBookmarks = async () => {
    if (!auth.currentUser) return;
    setLoading(true);
    try {
      const q = query(collection(db, 'bookmarks'), where('uid', '==', auth.currentUser.uid));
      const snap = await getDocs(q);
      const data = snap.docs.map((d: any) => ({ id: d.id, ...d.data() })) as Bookmark[];
      setBookmarks(data);
    } catch (e) {
      console.error('Failed to fetch bookmarks:', e);
    }
    setLoading(false);
  };

  useEffect(() => { fetchBookmarks(); }, []);

  const removeBookmark = async (id: string) => {
    await deleteDoc(doc(db, 'bookmarks', id));
    setBookmarks(prev => prev.filter(b => b.id !== id));
  };

  const diffColor = (diff: string) => {
    if (diff?.toLowerCase() === 'easy') return 'var(--accent-green)';
    if (diff?.toLowerCase() === 'medium') return 'var(--accent-amber)';
    return 'var(--accent-rose)';
  };

  const openProblem = (bm: Bookmark) => {
    const company = bm.company || 'saved';
    const slug = bm.url?.split('/problems/')[1]?.split('/')[0] || bm.title?.toLowerCase().replace(/\s+/g, '-');
    navigate(`/problem/${company}/${slug}`);
  };

  return (
    <div style={{ padding: '32px', color: 'white', overflowY: 'auto', height: '100%', boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>🔖 Saved Problems</h1>
          <p style={{ margin: '4px 0 0', color: 'var(--text-secondary)' }}>Your bookmarked questions for quick access.</p>
        </div>
        <button onClick={fetchBookmarks} className="accent-button" style={{ padding: '8px 16px', background: 'rgba(0,209,255,0.1)', color: 'var(--accent-blue)', border: '1px solid rgba(0,209,255,0.3)', borderRadius: '8px', cursor: 'pointer' }}>
          Refresh
        </button>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '100px 0' }}>Loading saved problems...</div>
      ) : bookmarks.length === 0 ? (
        <div className="glass-card" style={{ padding: '60px', textAlign: 'center' }}>
          <div style={{ fontSize: '48px', marginBottom: '16px' }}>🔖</div>
          <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: '18px' }}>No bookmarks yet.</p>
          <p style={{ color: 'rgba(255,255,255,0.25)', fontSize: '14px' }}>Open a problem and save it to revisit later.</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {bookmarks.map(bm => (
            <div
              key={bm.id}
              className="glass-card"
              style={{ padding: '16px 20px', display: 'flex', alignItems: 'center', gap: '16px', cursor: 'pointer' }}
              onClick={() => openProblem(bm)}
            >
              <div style={{ width: '4px', height: '40px', background: diffColor(bm.difficulty), borderRadius: '4px', flexShrink: 0 }} />
              <div style={{ flex: 1 }}>
                <h3 style={{ margin: 0, fontSize: '15px', color: 'white' }}>{bm.title}</h3>
                <div style={{ display: 'flex', gap: '8px', marginTop: '6px', alignItems: 'center' }}>
                  <span style={{ padding: '2px 8px', background: `${diffColor(bm.difficulty)}20`, borderRadius: '6px', fontSize: '11px', color: diffColor(bm.difficulty), fontWeight: 'bold' }}>
                    {bm.difficulty}
                  </span>
                  {bm.company && (
                    <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>{bm.company}</span>
                  )}
                </div>
              </div>
              <button
                onClick={e => { e.stopPropagation(); removeBookmark(bm.id); }}
                style={{ background: 'rgba(255,50,50,0.1)', border: '1px solid rgba(255,50,50,0.3)', borderRadius: '8px', color: 'var(--accent-rose)', padding: '6px 10px', cursor: 'pointer', fontSize: '12px' }}
              >
                Remove
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Bookmarks;
