import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { createUserWithEmailAndPassword } from 'firebase/auth';
import { doc, setDoc } from 'firebase/firestore';
import { auth, db } from '../firebase';

const Signup: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      const result = await createUserWithEmailAndPassword(auth, email, password);
      const user = result.user;

      if (user) {
        // Create user profile document in Firestore
        await setDoc(doc(db, 'users', user.uid), {
          name: name,
          email: email,
          rating: 1200,
          isOnline: true,
          friends: [],
        });
      }

      navigate('/');
    } catch (err: any) {
      setError(err.message || 'Signup failed.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={{ position: 'relative', height: '100vh', width: '100vw', overflow: 'hidden' }}>
      {/* Background Glows */}
      <div style={{
        position: 'absolute', bottom: '-100px', left: '-100px', width: '300px', height: '300px',
        borderRadius: '50%', background: 'rgba(0, 255, 133, 0.1)', filter: 'blur(100px)', zIndex: 0
      }} />

      <div style={{ position: 'relative', zIndex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
        <div className="glass-card" style={{ width: 400, padding: 40 }}>
          
          <div style={{ position: 'absolute', top: 20, left: 20 }}>
            <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', color: 'white', cursor: 'pointer', display: 'flex', alignItems: 'center' }}>
              <span style={{ fontSize: 20 }}>←</span>
            </button>
          </div>

          <div style={{ textAlign: 'center', marginBottom: 40 }}>
            <div style={{
              display: 'inline-flex', padding: 16, borderRadius: '50%', background: 'rgba(0, 255, 133, 0.1)',
              border: '1px solid rgba(0, 255, 133, 0.3)', marginBottom: 16
            }}>
              <span style={{ fontSize: 32, color: 'var(--accent-green)' }}>&lt;/&gt;</span>
            </div>
            <h1 style={{ margin: 0, fontSize: 24, letterSpacing: 1.2 }}>Join CodePath</h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: 14, marginTop: 4 }}>Join the elite circle of developers</p>
          </div>

          <h2 style={{ fontSize: 20, marginBottom: 24 }}>Create Account</h2>

          {error && <div style={{ color: 'var(--accent-rose)', fontSize: 13, marginBottom: 16 }}>{error}</div>}

          <form onSubmit={handleSignup}>
            <div style={{ marginBottom: 20 }}>
              <label style={{ display: 'block', fontSize: 12, color: 'rgba(255,255,255,0.7)', marginBottom: 8 }}>Name</label>
              <input 
                type="text" 
                className="glass-input" 
                style={{ width: '100%', boxSizing: 'border-box' }} 
                value={name} 
                onChange={(e) => setName(e.target.value)} 
                required 
              />
            </div>

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

            <button type="submit" className="accent-button" style={{ width: '100%', height: 50, backgroundColor: 'var(--accent-green)', color: 'black' }} disabled={isLoading}>
              {isLoading ? 'Initializing...' : 'Initialize Profile'}
            </button>
          </form>

          <div style={{ textAlign: 'center', marginTop: 24, fontSize: 14 }}>
            <span style={{ color: 'rgba(255,255,255,0.5)' }}>Already have an account? </span>
            <Link to="/login" style={{ color: 'var(--accent-green)', textDecoration: 'none', fontWeight: 'bold' }}>Login</Link>
          </div>

        </div>
      </div>
    </div>
  );
};

export default Signup;
