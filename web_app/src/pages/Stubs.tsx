import React from 'react';

export const Chats: React.FC = () => (
  <div style={{ padding: '32px', color: 'white' }}>
    <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>Global Communications</h1>
    <p style={{ margin: '4px 0 32px', color: 'var(--text-secondary)' }}>Chat with matched peers and discussion solvers.</p>
    <div className="glass-card" style={{ padding: '40px', textAlign: 'center' }}>
      <p style={{ color: 'rgba(255,255,255,0.4)' }}>Real-time socket streams are initiating securely. Chat is currently in idle standby.</p>
    </div>
  </div>
);

export const Settings: React.FC = () => (
  <div style={{ padding: '32px', color: 'white' }}>
    <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>Settings & Config</h1>
    <p style={{ margin: '4px 0 32px', color: 'var(--text-secondary)' }}>Manage account details, visual nodes and preferences.</p>
    <div className="glass-card" style={{ padding: '40px', textAlign: 'center' }}>
      <p style={{ color: 'rgba(255,255,255,0.4)' }}>Settings configuration nodes are currently synced to cloud profiles defaults.</p>
    </div>
  </div>
);
