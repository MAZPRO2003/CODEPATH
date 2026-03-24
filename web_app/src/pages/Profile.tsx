import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { doc, onSnapshot } from "firebase/firestore";
import { auth, db } from "../firebase";
import { LogOut, Star, Code, Award, Zap } from 'lucide-react';

const Profile: React.FC = () => {
  const [userData, setUserData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const uid = auth.currentUser?.uid;
    if (!uid) return;

    const unsubscribe = onSnapshot(doc(db, 'users', uid), (snapshot) => {
      if (snapshot.exists()) {
        setUserData(snapshot.data());
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleLogout = async () => {
    await auth.signOut();
    navigate('/login');
  };

  if (loading) return <div style={{ padding: '40px', textAlign: 'center' }}>Synchronizing Profile data...</div>;

  const easy = userData?.easySolved || 0;
  const medium = userData?.mediumSolved || 0;
  const hard = userData?.hardSolved || 0;
  const total = easy + medium + hard || 1; // avoid divide by zero

  return (
    <div style={{ padding: '32px', height: '100%', boxSizing: 'border-box', overflowY: 'auto', color: 'white' }}>
      
      {/* AppBar style header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 'bold' }}>Developer Profile</h1>
        <button onClick={handleLogout} style={{ background: 'none', border: 'none', color: 'var(--accent-rose)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', fontSize: '14px' }}>
          <LogOut size={16} /> Logout
        </button>
      </div>

      {/* Main card */}
      <div className="glass-card" style={{ padding: '32px', display: 'flex', alignItems: 'center', gap: '24px', marginBottom: '32px' }}>
        <div style={{ width: '80px', height: '80px', borderRadius: '50%', background: 'rgba(0, 209, 255, 0.1)', border: '2px solid var(--accent-blue)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ fontSize: '32px', fontWeight: 'bold', color: 'var(--accent-blue)' }}>{userData?.name ? userData?.name[0].toUpperCase() : '?'}</span>
        </div>
        <div>
          <h2 style={{ margin: 0, fontSize: '28px' }}>{userData?.name || 'Unknown User'}</h2>
          <p style={{ margin: '4px 0 0', color: 'var(--accent-blue)', fontSize: '15px' }}>
            Rating: {userData?.rating || 1200} • {easy+medium+hard} Problems Solved • 🔥 {userData?.currentStreak || 0} Day Streak
          </p>
        </div>
      </div>

      {/* Grid splits */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '32px' }}>
        
        {/* Left: Skills Graph (SVG Pie) */}
        <div className="glass-card" style={{ padding: '24px', textAlign: 'center' }}>
          <h3 style={{ marginTop: 0, marginBottom: '24px' }}>Skill Distribution</h3>
          <div style={{ height: '200px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            {/* Simple Conic Gradient with transparent center to mock PieChart Section */}
            <div style={{
              width: '180px', height: '180px', borderRadius: '50%',
              background: `conic-gradient(
                var(--accent-green) 0% ${(easy / total) * 100}%,
                var(--accent-amber) ${(easy / total) * 100}% ${((easy+medium) / total) * 100}%,
                var(--accent-rose) ${((easy+medium) / total) * 100}% 100%
              )`,
              mask: 'radial-gradient(transparent 55%, black 56%)',
              WebkitMask: 'radial-gradient(transparent 55%, black 56%)'
            }} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: '16px', marginTop: '24px', fontSize: '12px' }}>
            <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: 'var(--accent-green)' }} /> Easy ({easy})
            </span>
            <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: 'var(--accent-amber)' }} /> Med ({medium})
            </span>
            <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: 'var(--accent-rose)' }} /> Hard ({hard})
            </span>
          </div>
        </div>

        {/* Right: Achievements and Log */}
        <div className="glass-card" style={{ padding: '24px' }}>
          <h3 style={{ marginTop: 0, marginBottom: '16px' }}><Award size={18} style={{ verticalAlign: 'text-bottom', marginRight: '8px' }} /> Achievements</h3>
          {(!userData?.achievements || userData.achievements.length === 0) ? (
            <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>Solve problems to unlock achievements!</p>
          ) : (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: '24px' }}>
              {userData.achievements.map((a: string, i: number) => (
                <div key={i} style={{ padding: '6px 12px', background: 'rgba(255, 184, 0, 0.1)', color: 'var(--accent-amber)', borderRadius: '16px', fontSize: '12px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Star size={14} /> {a}
                </div>
              ))}
            </div>
          )}

          <h3 style={{ marginTop: '24px', marginBottom: '16px' }}><Zap size={18} style={{ verticalAlign: 'text-bottom', marginRight: '8px' }} /> Transmission Log</h3>
          {(!userData?.activityLog || userData.activityLog.length === 0) ? (
            <p style={{ color: 'rgba(255,255,255,0.3)', fontSize: '13px' }}>No transmissions recorded.</p>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {userData.activityLog.map((log: string, i: number) => (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: 'rgba(255,255,255,0.7)' }}>
                  <Code size={14} color="var(--accent-blue)" /> {log}
                </div>
              ))}
            </div>
          )}
        </div>

      </div>
    </div>
  );
};

export default Profile;
