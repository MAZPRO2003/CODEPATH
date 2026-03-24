import React, { useEffect, useState } from 'react';
import { getLeaderboardUsers, type AppUser } from '../services/firestoreService';
import { auth } from '../firebase';
import { Award, RefreshCw } from 'lucide-react';

const Leaderboard: React.FC = () => {
  const [users, setUsers] = useState<AppUser[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const currentUserId = auth.currentUser?.uid;

  useEffect(() => {
    fetchLeaderboard();
  }, []);

  const fetchLeaderboard = async () => {
    setIsLoading(true);
    const data = await getLeaderboardUsers();
    setUsers(data);
    setIsLoading(false);
  };

  const renderMedal = (index: number) => {
    if (index === 0) return <Award size={24} color="#ffd700" fill="#ffd700" />; // Gold
    if (index === 1) return <Award size={24} color="#c0c0c0" fill="#c0c0c0" />; // Silver
    if (index === 2) return <Award size={24} color="#cd7f32" fill="#cd7f32" />; // Bronze
    return <span style={{ fontWeight: 'bold', color: 'var(--text-secondary)' }}>#{index + 1}</span>;
  };

  return (
    <div style={{ padding: '32px', height: '100%', boxSizing: 'border-box', overflowY: 'auto' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>Global Leaderboard</h1>
          <p style={{ margin: '4px 0 0', color: 'var(--text-secondary)' }}>See how you stack against the top speed coders.</p>
        </div>
        <button onClick={fetchLeaderboard} style={{ background: 'none', border: 'none', color: 'var(--accent-blue)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <RefreshCw size={18} /> Refresh
        </button>
      </div>

      {isLoading ? (
        <div style={{ textAlign: 'center', padding: '100px 0' }}>Loading rankings...</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {users.map((user, index) => {
            const isMe = user.id === currentUserId;
            return (
              <div 
                key={user.id} 
                className="glass-card" 
                style={{
                  padding: '16px 24px',
                  background: isMe ? 'rgba(0, 209, 255, 0.05)' : 'rgba(255,255,255,0.02)',
                  border: isMe ? '2px solid var(--accent-blue)' : '1px solid var(--glass-border)',
                  display: 'flex',
                  alignItems: 'center',
                  transition: 'transform 0.2s',
                }}
                onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-2px)'}
                onMouseLeave={e => e.currentTarget.style.transform = 'translateY(0)'}
              >
                {/* Medal/Rank */}
                <div style={{ width: '50px', display: 'flex', justifyContent: 'center' }}>
                  {renderMedal(index)}
                </div>

                {/* Avatar */}
                <div style={{
                  width: '40px', height: '40px', borderRadius: '50%',
                  background: isMe ? 'var(--accent-blue)' : 'rgba(255,255,255,0.05)',
                  border: '1px solid var(--glass-border)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontWeight: 'bold', fontSize: '16px', color: 'white', marginRight: '16px'
                }}>
                  {user.name ? user.name[0].toUpperCase() : '?'}
                </div>

                {/* Name & Elo */}
                <div style={{ flex: 1 }}>
                  <h4 style={{ margin: 0, fontSize: '16px' }}>
                    {user.name} {isMe && <span style={{ color: 'var(--accent-blue)', fontSize: '12px' }}>(You)</span>}
                  </h4>
                  <p style={{ margin: '4px 0 0', fontSize: '12px', color: 'var(--accent-green)', fontWeight: 'bold' }}>
                    Elo Rating: {user.rating || 1200}
                  </p>
                </div>

                {/* Status dot or icon placeholder if needed */}
                {user.isOnline && (
                  <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--accent-green)', filter: 'drop-shadow(0 0 4px var(--accent-green))' }} />
                )}
              </div>
            );
          })}
        </div>
      )}

    </div>
  );
};

export default Leaderboard;
