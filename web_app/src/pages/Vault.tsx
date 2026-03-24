import React, { useEffect, useState } from 'react';
import { db, auth } from '../firebase';
import { collection, query, where, getDocs, orderBy } from 'firebase/firestore';

interface Submission {
  id: string;
  title: string;
  language: string;
  code: string;
  timestamp: any;
}

const Vault: React.FC = () => {
  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchSubmissions();
  }, []);

  const fetchSubmissions = async () => {
    if (!auth.currentUser) return;
    setLoading(true);
    try {
      const q = query(
        collection(db, "submissions"),
        where("uid", "==", auth.currentUser.uid),
        orderBy("timestamp", "desc")
      );
      const snap = await getDocs(q);
      const data = snap.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Submission[];
      setSubmissions(data);
    } catch (e) {
      console.error("Fetch submissions failed:", e);
    }
    setLoading(false);
  };

  const formatDate = (ts: any) => {
    if (!ts) return 'Unknown date';
    const date = ts.toDate ? ts.toDate() : new Date(ts);
    return date.toLocaleDateString() + ' at ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div style={{ padding: '32px', color: 'white', overflowY: 'auto', height: '100%', boxSizing: 'border-box' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>Algorithm Vault</h1>
          <p style={{ margin: '4px 0 0', color: 'var(--text-secondary)' }}>Your saved snippets and locked solutions archive.</p>
        </div>
        <button onClick={fetchSubmissions} className="accent-button" style={{ padding: '8px 16px', background: 'rgba(0, 209, 255, 0.1)', color: 'var(--accent-blue)', border: '1px solid rgba(0, 209, 255, 0.3)' }}>
          Refresh
        </button>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '100px 0' }}>Decrypting Vault nodes...</div>
      ) : submissions.length === 0 ? (
        <div className="glass-card" style={{ padding: '40px', textAlign: 'center' }}>
          <p style={{ color: 'rgba(255,255,255,0.4)' }}>Your vault is empty. Solve problems and click 'Submit' to store them here.</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          {submissions.map(sub => (
            <div key={sub.id} className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
              <div style={{ padding: '16px 24px', background: 'rgba(255,255,255,0.02)', borderBottom: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <h3 style={{ margin: 0, fontSize: '16px' }}>{sub.title}</h3>
                <span style={{ fontSize: '11px', color: 'var(--accent-blue)', fontWeight: 'bold', textTransform: 'uppercase' }}>{sub.language}</span>
              </div>
              <div style={{ padding: '12px 24px', fontSize: '12px', color: 'var(--text-secondary)', borderBottom: '1px solid rgba(255,255,255,0.02)' }}>
                Solved on {formatDate(sub.timestamp)}
              </div>
              <div style={{ padding: '24px', background: '#0D141C' }}>
                <pre style={{ margin: 0, fontFamily: 'monospace', fontSize: '13px', color: '#d4d4d4', overflowX: 'auto', lineHeight: '1.5' }}>
                  <code>{sub.code}</code>
                </pre>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Vault;
