import React, { useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { discoverCompanies, importCompanyProblems, type Problem } from '../services/githubService';
import { fetchProblemDetails } from '../services/problemDescriptionService';

const LazyTopic: React.FC<{ problem: Problem }> = ({ problem }) => {
  const [topics, setTopics] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const fetched = useRef(false);

  const loadTopics = async () => {
    if (fetched.current || loading) return;
    setLoading(true);
    try {
      const slug = problem.url.split('/problems/')[1]?.split('/')[0] || '';
      if (slug) {
        const details = await fetchProblemDetails(slug);
        const tags = details.topicTags || [];
        setTopics(tags);
      }
    } catch (e) {
      console.error(e);
    }
    setLoading(false);
    fetched.current = true;
  };

  return (
    <div 
      style={{ display: 'flex', gap: '4px', marginTop: '4px', flexWrap: 'wrap' }}
      onMouseEnter={loadTopics}
    >
      {topics.length === 0 ? (
        <span style={{ fontSize: '10px', color: 'rgba(255,255,255,0.3)', cursor: 'pointer' }} onClick={(e) => { e.stopPropagation(); loadTopics(); }}>
          {loading ? 'Loading tags...' : 'Hover to view tags'}
        </span>
      ) : (
        topics.map(t => (
          <span key={t} style={{ fontSize: '10px', padding: '2px 6px', background: 'rgba(0, 209, 255, 0.1)', border: '1px solid rgba(0, 209, 255, 0.2)', borderRadius: '10px', color: 'var(--accent-blue)' }}>
            {t}
          </span>
        ))
      )}
    </div>
  );
};

const Home: React.FC = () => {
  const navigate = useNavigate();
  const [companies, setCompanies] = useState<string[]>([]);
  const [filteredCompanies, setFilteredCompanies] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCompany, setSelectedCompany] = useState<string | null>(null);
  const [problems, setProblems] = useState<Problem[]>([]);
  const [loadingProblems, setLoadingProblems] = useState(false);

  useEffect(() => {
    fetchCompanies();
  }, []);

  const fetchCompanies = async () => {
    setIsLoading(true);
    const data = await discoverCompanies();
    setCompanies(data);
    setFilteredCompanies(data);
    setIsLoading(false);
  };

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setSearchQuery(val);
    if (!val.trim()) {
      setFilteredCompanies(companies);
    } else {
      setFilteredCompanies(companies.filter(c => c.toLowerCase().includes(val.toLowerCase())));
    }
  };

  const handleCompanyClick = async (company: string) => {
    setSelectedCompany(company);
    setLoadingProblems(true);
    const data = await importCompanyProblems(company);
    
    // Sort by difficulty: Easy -> Medium -> Hard
    const difficultyOrder: { [key: string]: number } = { 'easy': 1, 'medium': 2, 'hard': 3 };
    const sortedData = [...data].sort((a, b) => {
      const diffA = difficultyOrder[a.difficulty.toLowerCase()] || 4;
      const diffB = difficultyOrder[b.difficulty.toLowerCase()] || 4;
      return diffA - diffB;
    });

    setProblems(sortedData);
    setLoadingProblems(false);
  };

  const groupCompanies = () => {
    const map: { [key: string]: string[] } = {};
    filteredCompanies.forEach(c => {
      if (!c) return;
      const firstLetter = c[0].toUpperCase();
      const key = /^[A-Z]$/.test(firstLetter) ? firstLetter : '#';
      if (!map[key]) map[key] = [];
      map[key].push(c);
    });
    // Sort items within groups
    Object.keys(map).forEach(key => {
      map[key].sort((a, b) => a.localeCompare(b));
    });
    return map;
  };

  const grouped = groupCompanies();
  const sortedKeys = Object.keys(grouped).sort();

  return (
    <div style={{ padding: '32px', color: 'white', position: 'relative', minHeight: '100%' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>Coding Challenge Dashboard</h1>
          <p style={{ margin: '4px 0 0', color: 'var(--text-secondary)' }}>Select a company below to load and practice their interview questions.</p>
        </div>
        <button onClick={fetchCompanies} className="accent-button" style={{ padding: '8px 16px', background: 'rgba(0, 209, 255, 0.1)', color: 'var(--accent-blue)', border: '1px solid rgba(0, 209, 255, 0.3)' }}>
          Refresh
        </button>
      </div>

      {/* Search Input */}
      <div style={{ marginBottom: '32px' }}>
        <input 
          type="text" 
          placeholder="Search companies..." 
          className="glass-input" 
          style={{ width: '100%', boxSizing: 'border-box' }} 
          value={searchQuery}
          onChange={handleSearch}
        />
      </div>

      {/* Companies List */}
      {isLoading ? (
        <div style={{ textAlign: 'center', padding: '100px 0' }}>Loading Companies...</div>
      ) : sortedKeys.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '100px 0', color: 'var(--text-secondary)' }}>No companies found.</div>
      ) : (
        <div>
          {sortedKeys.map(letter => (
            <div key={letter} style={{ marginBottom: '32px' }}>
              {/* Letter Header */}
              <div style={{ display: 'flex', alignItems: 'center', marginBottom: '16px' }}>
                <div style={{
                  width: '40px', height: '40px', borderRadius: '50%', background: 'rgba(255, 0, 92, 0.1)',
                  border: '1px solid rgba(255, 0, 92, 0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: 'var(--accent-rose)', fontWeight: 'bold', fontSize: '18px'
                }}>
                  {letter}
                </div>
                <div style={{ flex: 1, height: '1px', background: 'var(--glass-border)', marginLeft: '16px' }} />
              </div>

              {/* Company Grid */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: '12px' }}>
                {grouped[letter].map(company => (
                  <button 
                    key={company}
                    onClick={() => handleCompanyClick(company)}
                    style={{
                      background: 'var(--sidebar-background)', border: '1px solid var(--glass-border)',
                      borderRadius: '20px', padding: '8px 12px', color: 'rgba(255,255,255,0.7)',
                      fontSize: '11px', fontWeight: 'bold', textTransform: 'uppercase', cursor: 'pointer',
                      textAlign: 'center', textOverflow: 'ellipsis', whiteSpace: 'nowrap', overflow: 'hidden',
                      transition: 'all 0.2s'
                    }}
                    onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--accent-blue)'; e.currentTarget.style.color = 'var(--accent-blue)' }}
                    onMouseLeave={e => { e.currentTarget.style.borderColor = 'var(--glass-border)'; e.currentTarget.style.color = 'rgba(255,255,255,0.7)' }}
                  >
                    {company}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal / Dialog for Company Problems */}
      {selectedCompany && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh',
          backgroundColor: 'rgba(0, 0, 0, 0.7)', backdropFilter: 'blur(5px)',
          display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 100
        }}>
          <div className="glass-card" style={{ width: '600px', maxHeight: '80vh', overflowY: 'auto', padding: '32px', position: 'relative' }}>
            <button onClick={() => setSelectedCompany(null)} style={{ position: 'absolute', top: '16px', right: '16px', background: 'none', border: 'none', color: 'white', cursor: 'pointer', fontSize: '20px' }}>
              &times;
            </button>
            <h2 style={{ marginTop: 0, fontSize: '24px', textTransform: 'uppercase', color: 'var(--accent-blue)' }}>{selectedCompany}</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '14px' }}>Practice optimal solutions to ace your interviews.</p>
            <hr style={{ borderColor: 'var(--glass-border)', margin: '16px 0' }} />

            {loadingProblems ? (
              <div style={{ textAlign: 'center', padding: '40px 0' }}>Loading questions...</div>
            ) : problems.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 0' }}>No questions found for this company.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {['Easy', 'Medium', 'Hard', 'Other'].map(diff => {
                  const filtered = problems.filter(p => {
                    const d = p.difficulty.toLowerCase();
                    if (diff === 'Other') {
                      return !['easy', 'medium', 'hard'].includes(d);
                    }
                    return d === diff.toLowerCase();
                  });
                  if (filtered.length === 0) return null;
                  return (
                    <div key={diff}>
                      <h4 style={{ margin: '8px 0', color: diff === 'Easy' ? 'var(--accent-green)' : diff === 'Medium' ? 'var(--accent-amber)' : diff === 'Hard' ? 'var(--accent-rose)' : 'var(--accent-blue)', fontSize: '13px', textTransform: 'uppercase', letterSpacing: '1px' }}>
                        {diff} ({filtered.length})
                      </h4>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        {filtered.map(prob => (
                          <div 
                            key={prob.id} 
                            className="glass-card" 
                            style={{ 
                              padding: '12px 16px', 
                              background: 'rgba(255,255,255,0.01)', 
                              display: 'flex', 
                              justifyContent: 'space-between', 
                              alignItems: 'center',
                              cursor: 'pointer',
                              border: '1px solid rgba(255,255,255,0.03)'
                            }}
                            onClick={() => {
                              setSelectedCompany(null);
                              navigate(`/problem/${selectedCompany}/${prob.id}`);
                            }}
                          >
                            <div style={{ flex: 1 }}>
                              <h5 style={{ margin: 0, fontSize: '14px', color: 'rgba(255,255,255,0.9)' }}>{prob.title}</h5>
                              <LazyTopic problem={prob} />
                            </div>
                            <div style={{ 
                              padding: '4px 8px', 
                              background: diff === 'Easy' ? 'rgba(0, 200, 83, 0.1)' : diff === 'Medium' ? 'rgba(255, 145, 0, 0.1)' : diff === 'Hard' ? 'rgba(255, 23, 68, 0.1)' : 'rgba(0, 209, 255, 0.1)',
                              borderRadius: '4px',
                              fontSize: '11px',
                              color: diff === 'Easy' ? 'var(--accent-green)' : diff === 'Medium' ? 'var(--accent-amber)' : diff === 'Hard' ? 'var(--accent-rose)' : 'var(--accent-blue)',
                              fontWeight: 'bold'
                            }}>
                              {prob.difficulty}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      )}

    </div>
  );
};

export default Home;
