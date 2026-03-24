import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { startMatchmaking } from '../services/battleService';

const BattleLobby: React.FC = () => {
  const [isSearching, setIsSearching] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    let cancel: (() => void) | null = null;
    
    if (isSearching) {
      cancel = startMatchmaking((battleId) => {
        setIsSearching(false);
        navigate(`/battle/arena/${battleId}`);
      });
    }

    return () => {
      if (cancel) cancel();
    };
  }, [isSearching, navigate]);

  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column', 
      justifyContent: 'center', alignItems: 'center', color: 'white'
    }}>
      {/* Background Glow */}
      <div style={{
        position: 'absolute', top: '-100px', right: '-100px', width: '300px', height: '300px',
        borderRadius: '50%', background: 'rgba(255, 0, 92, 0.1)', filter: 'blur(100px)', zIndex: 0
      }} />

      <div style={{ zIndex: 1, textAlign: 'center', maxWidth: '500px' }}>
        <div style={{
          display: 'inline-flex', padding: '24px', borderRadius: '50%', 
          background: 'rgba(255, 0, 92, 0.1)', border: '2px solid rgba(255, 0, 92, 0.3)', marginBottom: '32px'
        }}>
          <span style={{ fontSize: '48px', color: 'var(--accent-rose)' }}>⚡</span>
        </div>

        <h1 style={{ fontSize: '40px', fontWeight: 'bold', margin: '0 0 8px' }}>1v1 Battle Arena</h1>
        <p style={{ color: 'var(--text-secondary)', fontSize: '16px', marginBottom: '48px' }}>Challenge other developers in real-time speed coding</p>

        {isSearching ? (
          <div>
            <div style={{ width: '40px', height: '40px', border: '4px solid rgba(255,0,92,0.3)', borderTopColor: 'var(--accent-rose)', borderRadius: '50%', animation: 'spin 1s linear infinite', margin: '0 auto 24px' }} />
            <style>{`@keyframes spin { 100% { transform: rotate(360deg); } }`}</style>
            <p style={{ color: 'var(--accent-rose)', fontWeight: 'bold', letterSpacing: '2px', fontSize: '14px' }}>FINDING AN OPPONENT...</p>
            <button onClick={() => setIsSearching(false)} style={{ background: 'none', border: 'none', color: 'var(--accent-rose)', cursor: 'pointer', marginTop: '16px', fontSize: '12px' }}>
              CANCEL SEARCH
            </button>
          </div>
        ) : (
          <div className="glass-card" style={{ padding: '32px', width: '100%', boxSizing: 'border-box' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '24px' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Difficulty</span>
              <span style={{ color: 'white', fontWeight: 'bold' }}>Easy (Default)</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '40px' }}>
              <span style={{ color: 'var(--text-secondary)' }}>Opponent</span>
              <span style={{ color: 'white', fontWeight: 'bold' }}>Random Match</span>
            </div>
            
            <button className="accent-button" style={{ width: '100%', backgroundColor: 'var(--accent-rose)', color: 'white', height: '50px', fontSize: '16px' }} onClick={() => setIsSearching(true)}>
              START MATCHMAKING
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default BattleLobby;
