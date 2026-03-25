import React, { useEffect, useState } from 'react';
import { db, auth } from '../firebase';
import { doc, setDoc } from 'firebase/firestore';

interface SolvedProblem {
  title: string;
  difficulty: string;
  solved_at: string;
}

const DailyGoals: React.FC = () => {
  const [dailyTarget, setDailyTarget] = useState(3);
  const [todaySolved, setTodaySolved] = useState(0);
  const [currentStreak, setCurrentStreak] = useState(0);
  const [totalSolved, setTotalSolved] = useState(0);
  const [recentSolved, setRecentSolved] = useState<SolvedProblem[]>([]);
  const [loading, setLoading] = useState(true);

  const loadStats = async () => {
    if (!auth.currentUser) return;
    setLoading(true);
    try {
      // Fallback: directly get by doc ID
      const { getDoc } = await import('firebase/firestore');
      const snap = await getDoc(doc(db, 'users', auth.currentUser.uid));
      const data = snap.data() || {};
      
      const solvedList: SolvedProblem[] = Array.isArray(data.solved_problems) ? data.solved_problems : [];
      const today = new Date();
      const todayCount = solvedList.filter(p => {
        try {
          const dt = new Date(p.solved_at);
          return dt.getFullYear() === today.getFullYear() && dt.getMonth() === today.getMonth() && dt.getDate() === today.getDate();
        } catch { return false; }
      }).length;

      setTodaySolved(todayCount);
      setCurrentStreak(data.current_streak || 0);
      setTotalSolved(data.total_solved || 0);
      setDailyTarget(data.daily_target || 3);
      setRecentSolved([...solvedList].reverse().slice(0, 10));
    } catch (e) {
      console.error('Failed to load stats:', e);
    }
    setLoading(false);
  };

  useEffect(() => { loadStats(); }, []);

  const updateTarget = async (n: number) => {
    if (!auth.currentUser) return;
    setDailyTarget(n);
    try {
      await setDoc(doc(db, 'users', auth.currentUser.uid), { daily_target: n }, { merge: true });
    } catch (e) {
      console.error('Failed to save target:', e);
    }
  };

  const progress = dailyTarget > 0 ? Math.min(todaySolved / dailyTarget, 1) : 0;
  const isGoalMet = todaySolved >= dailyTarget;

  const diffColor = (diff: string) => {
    if (diff?.toLowerCase() === 'easy') return 'var(--accent-green)';
    if (diff?.toLowerCase() === 'medium') return 'var(--accent-amber)';
    return 'var(--accent-rose)';
  };

  return (
    <div style={{ padding: '32px', color: 'white', overflowY: 'auto', height: '100%', boxSizing: 'border-box' }}>
      <div style={{ marginBottom: '32px' }}>
        <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>🎯 Daily Goals</h1>
        <p style={{ margin: '4px 0 0', color: 'var(--text-secondary)' }}>Track your daily practice progress.</p>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '100px 0' }}>Loading your stats...</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>

          {/* Progress Card */}
          <div style={{
            padding: '32px',
            borderRadius: '20px',
            background: isGoalMet
              ? 'linear-gradient(135deg, #00C853, #00E676)'
              : 'linear-gradient(135deg, #0D47A1, var(--accent-blue))',
            textAlign: 'center',
          }}>
            <p style={{ margin: '0 0 8px', color: 'rgba(255,255,255,0.7)', fontSize: '14px' }}>
              {isGoalMet ? '🎉 Goal Complete!' : "Today's Progress"}
            </p>
            <div style={{ fontSize: '64px', fontWeight: 'bold', lineHeight: 1 }}>{todaySolved} / {dailyTarget}</div>
            <div style={{ margin: '20px 0 8px', background: 'rgba(255,255,255,0.25)', borderRadius: '8px', height: '10px', overflow: 'hidden' }}>
              <div style={{ width: `${progress * 100}%`, height: '100%', background: 'white', borderRadius: '8px', transition: 'width 0.5s ease' }} />
            </div>
            <p style={{ margin: 0, color: 'rgba(255,255,255,0.7)', fontSize: '13px' }}>
              {isGoalMet ? 'You crushed it! 🔥' : `${dailyTarget - todaySolved} more to go`}
            </p>
          </div>

          {/* Stats Row */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
            <div className="glass-card" style={{ padding: '24px', textAlign: 'center', borderColor: 'rgba(255,145,0,0.3)' }}>
              <div style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px' }}>🔥 Streak</div>
              <div style={{ fontSize: '36px', fontWeight: 'bold', color: 'var(--accent-amber)' }}>{currentStreak}</div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>days</div>
            </div>
            <div className="glass-card" style={{ padding: '24px', textAlign: 'center', borderColor: 'rgba(0,200,83,0.3)' }}>
              <div style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '8px' }}>✅ Total Solved</div>
              <div style={{ fontSize: '36px', fontWeight: 'bold', color: 'var(--accent-green)' }}>{totalSolved}</div>
              <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>problems</div>
            </div>
          </div>

          {/* Daily Target Selector */}
          <div className="glass-card" style={{ padding: '24px' }}>
            <h3 style={{ margin: '0 0 16px', fontSize: '16px' }}>Daily Target</h3>
            <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
              {[1, 2, 3, 5, 10].map(n => (
                <button
                  key={n}
                  onClick={() => updateTarget(n)}
                  style={{
                    width: '52px', height: '52px', borderRadius: '12px', border: 'none',
                    background: dailyTarget === n ? 'var(--accent-blue)' : 'rgba(255,255,255,0.05)',
                    color: dailyTarget === n ? 'white' : 'var(--text-secondary)',
                    fontSize: '18px', fontWeight: 'bold', cursor: 'pointer',
                    transition: 'all 0.2s',
                    outline: dailyTarget === n ? '2px solid var(--accent-blue)' : 'none',
                  }}
                >
                  {n}
                </button>
              ))}
            </div>
          </div>

          {/* Recent Solved */}
          {recentSolved.length > 0 && (
            <div>
              <h3 style={{ margin: '0 0 12px', fontSize: '16px' }}>Recently Solved</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {recentSolved.map((p, i) => (
                  <div key={i} className="glass-card" style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <span style={{ color: diffColor(p.difficulty), fontSize: '16px' }}>✓</span>
                    <span style={{ flex: 1, color: 'rgba(255,255,255,0.8)', fontSize: '14px' }}>{p.title}</span>
                    <span style={{ padding: '2px 8px', background: `${diffColor(p.difficulty)}20`, borderRadius: '6px', fontSize: '11px', color: diffColor(p.difficulty), fontWeight: 'bold' }}>
                      {p.difficulty}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default DailyGoals;
