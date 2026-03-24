import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { signInWithEmailAndPassword, signInAnonymously } from 'firebase/auth';
import { auth } from '../firebase';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      await signInWithEmailAndPassword(auth, email, password);
      navigate('/');
    } catch (err: any) {
      setError(err.message || 'Login failed. Check your credentials.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleGuestLogin = async () => {
    try {
      await signInAnonymously(auth);
      navigate('/');
    } catch (err: any) {
      setError('Guest login failed.');
    }
  };

  return (
    <div style={{ position: 'relative', height: '100vh', width: '100vw', overflow: 'hidden' }}>
      {/* Background Glows */}
      <div style={{
        position: 'absolute', top: '-100px', right: '-100px', width: '300px', height: '300px',
        borderRadius: '50%', background: 'rgba(0, 209, 255, 0.15)', filter: 'blur(100px)', zIndex: 0
      }} />

      <div style={{ position: 'relative', zIndex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
        <div className="glass-card" style={{ width: 400, padding: 40 }}>
          
          <div style={{ textAlign: 'center', marginBottom: 40 }}>
            <div style={{
              display: 'inline-flex', padding: 16, borderRadius: '50%', background: 'rgba(0, 209, 255, 0.1)',
              border: '1px solid rgba(0, 209, 255, 0.3)', marginBottom: 16
            }}>
              <span style={{ fontSize: 32, color: 'var(--accent-blue)' }}>&lt;/&gt;</span>
            </div>
            <h1 style={{ margin: 0, fontSize: 24, letterSpacing: 1.2 }}>CodePath</h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: 14, marginTop: 4 }}>Elevate Your Logic</p>
          </div>

          <h2 style={{ fontSize: 20, marginBottom: 24 }}>Login</h2>

          {error && <div style={{ color: 'var(--accent-rose)', fontSize: 13, marginBottom: 16 }}>{error}</div>}

          <form onSubmit={handleLogin}>
            <div style={{ marginBottom: 20 }}>
              <label style={{ display: 'block', fontSize: 12, color: 'rgba(255,255,255,0.7)', marginBottom: 8 }}>Email Address</label>
              <input 
                type="email" 
                className="glass-input" 
                style={{ width: '100%', boxSizing: 'border-box' }} 
                value={email} 
                onChange={(e) => setEmail(e.target.value)} 
                required 
              />
            </div>

            <div style={{ marginBottom: 40 }}>
              <label style={{ display: 'block', fontSize: 12, color: 'rgba(255,255,255,0.7)', marginBottom: 8 }}>Password</label>
              <input 
                type="password" 
                className="glass-input" 
                style={{ width: '100%', boxSizing: 'border-box' }} 
                value={password} 
                onChange={(e) => setPassword(e.target.value)} 
                required 
              />
            </div>

            <button type="submit" className="accent-button" style={{ width: '100%', height: 50 }} disabled={isLoading}>
              {isLoading ? 'Entering...' : 'Enter Workspace'}
            </button>
          </form>

          <div style={{ textAlign: 'center', marginTop: 16 }}>
            <button onClick={handleGuestLogin} style={{ background: 'none', border: 'none', color: 'rgba(255,255,255,0.5)', cursor: 'pointer', fontSize: 13 }}>
              Continue as Guest
            </button>
          </div>

          <div style={{ textAlign: 'center', marginTop: 24, fontSize: 14 }}>
            <span style={{ color: 'rgba(255,255,255,0.5)' }}>New here? </span>
            <Link to="/signup" style={{ color: 'var(--accent-blue)', textDecoration: 'none', fontWeight: 'bold' }}>Create account</Link>
          </div>

        </div>
      </div>
    </div>
  );
};

export default Login;
