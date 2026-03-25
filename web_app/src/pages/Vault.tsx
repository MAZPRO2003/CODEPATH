import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { db, auth } from '../firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';

interface Submission {
  id: string;
  title: string;
  company?: string;
  language: string;
  code: string;
  timestamp: any;
}

const Vault: React.FC = () => {
  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => { fetchSubmissions(); }, []);

  const fetchSubmissions = async () => {
    if (!auth.currentUser) return;
    setLoading(true);
    try {
      const q = query(collection(db, 'submissions'), where('uid', '==', auth.currentUser.uid));
      const snap = await getDocs(q);
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() })) as Submission[];
      data.sort((a, b) => {
        const tA = a.timestamp?.toDate ? a.timestamp.toDate().getTime() : new Date(a.timestamp || 0).getTime();
        const tB = b.timestamp?.toDate ? b.timestamp.toDate().getTime() : new Date(b.timestamp || 0).getTime();
        return tB - tA;
      });
      setSubmissions(data);
    } catch (e) { console.error('Fetch failed:', e); }
    setLoading(false);
  };

  const formatDate = (ts: any) => {
    if (!ts) return '';
    const d = ts.toDate ? ts.toDate() : new Date(ts);
    return d.toLocaleDateString() + ' · ' + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div style={{ padding: '32px', color: 'white', overflowY: 'auto', height: '100%', boxSizing: 'border-box' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '28px' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>🔐 Solution Vault</h1>
          <p style={{ margin: '4px 0 0', color: 'var(--text-secondary)' }}>Your submitted solutions. Tap a question to view code.</p>
        </div>
        <button onClick={fetchSubmissions} style={{ padding: '8px 16px', background: 'rgba(0,209,255,0.1)', color: 'var(--accent-blue)', border: '1px solid rgba(0,209,255,0.3)', borderRadius: '8px', cursor: 'pointer' }}>
          Refresh
        </button>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '80px 0', color: 'var(--text-secondary)' }}>Loading...</div>
      ) : submissions.length === 0 ? (
        <div className="glass-card" style={{ padding: '60px', textAlign: 'center' }}>
          <div style={{ fontSize: '48px', marginBottom: '16px' }}>🔐</div>
          <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: '16px' }}>No solutions yet. Submit a problem to save it here.</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {submissions.map(sub => (
            <div
              key={sub.id}
              className="glass-card"
              style={{ padding: '16px 20px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '16px' }}
              onClick={() => {
                const slug = sub.title.toLowerCase().replace(/\s+/g, '-');
                navigate(`/problem/${sub.company?.toLowerCase() || 'leetcode'}/${slug}`);
              }}
            >
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 'bold', fontSize: '15px', color: 'white' }}>{sub.title}</div>
                <div style={{ fontSize: '12px', color: 'var(--text-secondary)', marginTop: '4px' }}>
                  {sub.company || 'Practice'} · {sub.language?.toUpperCase()} · {formatDate(sub.timestamp)}
                </div>
              </div>
              <div style={{ color: 'var(--accent-blue)', fontSize: '12px', fontWeight: 'bold' }}>To Editor →</div>
            </div>
          ))}
        </div>
      )}

      {/* Code Modal Removed. Redirects to Editor Now. */}
    </div>
  );
};

export default Vault;
