import React, { useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { discoverCompanies, importCompanyProblems, type Problem } from '../services/githubService';
import { fetchProblemDetails } from '../services/problemDescriptionService';
import { fetchCustomCompanies, saveCustomProblem, fetchCustomProblemsByCompany, deleteCustomCompany } from '../services/customQuestionService';
import { db, auth } from '../firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';

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
  const [customCompanies, setCustomCompanies] = useState<string[]>([]);
  const [completedProblems, setCompletedProblems] = useState<string[]>([]);

  const handleDeleteCompany = async (company: string) => {
    if (!window.confirm(`Are you sure you want to delete "${company}" and all its custom questions?`)) return;
    try {
      await deleteCustomCompany(company);
      alert("✅ Company deleted successfully!");
      setSelectedCompany(null);
      fetchCompanies();
    } catch (e) {
      alert("Failed to delete company.");
    }
  };

  // --- Add Question Modal State ---
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [addTab, setAddTab] = useState<'slug' | 'manual'>('slug');
  const [isSaving, setIsSaving] = useState(false);
  
  // Slug inputs
  const [slugInput, setSlugInput] = useState('');
  const [slugCompany, setSlugCompany] = useState('');
  
  // Manual inputs
  const [manualTitle, setManualTitle] = useState('');
  const [manualCompany, setManualCompany] = useState('');
  const [manualDifficulty, setManualDifficulty] = useState('Medium');
  const [manualContent, setManualContent] = useState('');
  const [manualSampleInput, setManualSampleInput] = useState('');
  const [manualExampleTestcases, setManualExampleTestcases] = useState('');

  const handleAddSlug = async () => {
    if (!slugInput || !slugCompany) return alert("Please fill URL/Slug and company fields.");
    setIsSaving(true);
    try {
      let slug = slugInput.trim();
      if (slug.includes('leetcode.com/problems/')) {
        const match = slug.match(/\/problems\/([a-zA-Z0-9\-]+)/);
        if (match && match[1]) slug = match[1];
      }

      const details = await fetchProblemDetails(slug);
      const matchedQ = leetcodeQuestions.find(q => q.slug === slug);
      const exactTitle = matchedQ ? matchedQ.title : slug.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
      
      const existing = companies.find(c => c.toLowerCase() === slugCompany.trim().toLowerCase());
      const normalizedCompany = existing || slugCompany.trim();

      await saveCustomProblem({
        title: exactTitle,
        url: `https://leetcode.com/problems/${slug}/`,
        difficulty: 'Medium', 
        company: normalizedCompany,
        content: details.content,
        sampleTestCase: details.sampleTestCase,
        exampleTestcases: details.exampleTestcases
      });
      alert("✅ LeetCode question imported successfully!");
      setIsAddModalOpen(false);
      setSlugInput('');
      fetchCompanies();
    } catch (e) {
      alert("Failed to import slug. Confirm LeetCode endpoint is reachable.");
    }
    setIsSaving(false);
  };

  const handleAddManual = async () => {
    if (!manualTitle || !manualCompany || !manualContent) return alert("Fill Title, Company and Content fields.");
    setIsSaving(true);
    try {
      const existing = companies.find(c => c.toLowerCase() === manualCompany.trim().toLowerCase());
      const normalizedCompany = existing || manualCompany.trim();

      await saveCustomProblem({
        title: manualTitle,
        url: '', 
        difficulty: manualDifficulty,
        company: normalizedCompany,
        content: manualContent,
        sampleTestCase: manualSampleInput,
        exampleTestcases: manualExampleTestcases
      });
      alert("✅ Manual question saved into dashboard templates!");
      setIsAddModalOpen(false);
      setManualTitle('');
      setManualContent('');
      fetchCompanies();
    } catch (e) {
      alert("Error adding manual question files presets.");
    }
    setIsSaving(false);
  };

  const [leetcodeQuestions, setLeetcodeQuestions] = useState<{title: string, slug: string}[]>([]);

  useEffect(() => {
    const loadQuestions = async () => {
      try {
        const res = await fetch('https://leetcode.com/api/problems/algorithms/');
        const data = await res.json();
        const list = data.stat_status_pairs.map((p: any) => ({
          title: p.stat.question__title,
          slug: p.stat.question__title_slug
        }));
        setLeetcodeQuestions(list);
      } catch (e) {
        console.error("Failed to load leetcode questions", e);
      }
    };
    loadQuestions();
  }, []);

  const fetchCompletedProblems = async () => {
    if (!auth.currentUser) return;
    try {
      const q = query(collection(db, "submissions"), where("uid", "==", auth.currentUser.uid));
      const snap = await getDocs(q);
      const titles = snap.docs.map((doc: any) => doc.data().title as string);
      setCompletedProblems(titles);
    } catch (e) {
      console.error("Failed to fetch completed:", e);
    }
  };

  useEffect(() => {
    fetchCompanies();
    fetchCompletedProblems();
  }, []);

  const fetchCompanies = async () => {
    setIsLoading(true);
    const gitHubCompanies = await discoverCompanies();
    const cCompanies = await fetchCustomCompanies();
    setCustomCompanies(cCompanies);
    const merged = Array.from(new Set([...gitHubCompanies, ...cCompanies]));
    setCompanies(merged);
    setFilteredCompanies(merged);
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
    const gitHubProblems = await importCompanyProblems(company);
    const customProblems = await fetchCustomProblemsByCompany(company);
    const combined = [...gitHubProblems, ...customProblems];
    
    // Sort by difficulty: Easy -> Medium -> Hard
    const difficultyOrder: { [key: string]: number } = { 'easy': 1, 'medium': 2, 'hard': 3 };
    const sortedData = combined.sort((a, b) => {
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
        <div style={{ display: 'flex', gap: '12px' }}>
          <button onClick={() => setIsAddModalOpen(true)} className="accent-button" style={{ padding: '8px 16px', background: 'rgba(0, 209, 255, 0.1)', color: 'var(--accent-blue)', border: '1px solid rgba(0, 209, 255, 0.3)' }}>
            ➕ Add Question
          </button>
          <button onClick={fetchCompanies} className="accent-button" style={{ padding: '8px 16px', background: 'rgba(255,100,0,0.05)', color: 'rgba(255,255,255,0.8)', border: '1px solid var(--glass-border)' }}>
            Refresh
          </button>
        </div>
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
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '8px', marginBottom: '12px' }}>
              <h2 style={{ margin: 0, fontSize: '24px', textTransform: 'uppercase', color: 'var(--accent-blue)' }}>{selectedCompany}</h2>
              {customCompanies.includes(selectedCompany!) && (
                <button 
                  onClick={() => handleDeleteCompany(selectedCompany!)} 
                  style={{ background: 'rgba(255,0,0,0.1)', border: '1px solid rgba(255,0,0,0.3)', color: '#ff4d4d', padding: '6px 12px', borderRadius: '8px', cursor: 'pointer', fontSize: '12px', fontWeight: 'bold' }}
                >
                  Delete Company
                </button>
              )}
            </div>
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
                              <h5 style={{ margin: 0, fontSize: '14px', color: 'rgba(255,255,255,0.9)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                                {prob.title}
                                {completedProblems.includes(prob.title) && <span style={{ color: 'var(--accent-green)', fontSize: '14px' }}>✅</span>}
                              </h5>
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

      {/* Add Question Modal */}
      {isAddModalOpen && (
        <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', backgroundColor: 'rgba(0, 0, 0, 0.8)', backdropFilter: 'blur(8px)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 200 }}>
          <div className="glass-card" style={{ width: '500px', padding: '32px', position: 'relative', maxHeight: '90vh', overflowY: 'auto' }}>
            <button onClick={() => setIsAddModalOpen(false)} style={{ position: 'absolute', top: '16px', right: '16px', background: 'none', border: 'none', color: 'white', cursor: 'pointer', fontSize: '20px' }}>&times;</button>
            <h3 style={{ marginTop: 0 }}>Add New Question</h3>

            {/* Modal Tabs */}
            <div style={{ display: 'flex', gap: '12px', marginBottom: '20px', borderBottom: '1px solid var(--glass-border)' }}>
              <button onClick={() => setAddTab('slug')} style={{ padding: '10px', background: 'none', border: 'none', color: addTab === 'slug' ? 'var(--accent-blue)' : 'white', borderBottom: addTab === 'slug' ? '2px solid var(--accent-blue)' : 'none', cursor: 'pointer', flex: 1 }}>Via Slug</button>
              <button onClick={() => setAddTab('manual')} style={{ padding: '10px', background: 'none', border: 'none', color: addTab === 'manual' ? 'var(--accent-blue)' : 'white', borderBottom: addTab === 'manual' ? '2px solid var(--accent-blue)' : 'none', cursor: 'pointer', flex: 1 }}>Manual Form</button>
            </div>

            {addTab === 'slug' ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <div>
                  <label style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>LeetCode URL or Slug</label>
                  <input 
                    type="text" 
                    list="leetcode-slugs"
                    placeholder="e.g. https://leetcode.com/problems/two-sum/" 
                    className="glass-input" 
                    style={{ width: '100%', marginTop: '4px' }} 
                    value={slugInput} 
                    onChange={e => setSlugInput(e.target.value)} 
                  />
                  <datalist id="leetcode-slugs">
                    {leetcodeQuestions.map(q => (
                      <option key={q.slug} value={q.slug}>{q.title}</option>
                    ))}
                  </datalist>
                </div>
                <div>
                  <label style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Company Target</label>
                  <input type="text" placeholder="e.g. Google" className="glass-input" style={{ width: '100%', marginTop: '4px' }} value={slugCompany} onChange={e => setSlugCompany(e.target.value)} />
                </div>
                <button onClick={handleAddSlug} disabled={isSaving} className="accent-button" style={{ padding: '12px', marginTop: '12px' }}>
                  {isSaving ? 'Fetching & Saving...' : 'Import Question'}
                </button>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                <div>
                  <label style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Title *</label>
                  <input type="text" placeholder="Problem Title" className="glass-input" style={{ width: '100%', marginTop: '4px' }} value={manualTitle} onChange={e => setManualTitle(e.target.value)} />
                </div>
                <div style={{ display: 'flex', gap: '12px' }}>
                  <div style={{ flex: 1 }}>
                    <label style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Company *</label>
                    <input type="text" placeholder="Company Name" className="glass-input" style={{ width: '100%', marginTop: '4px', height: '45px', boxSizing: 'border-box' }} value={manualCompany} onChange={e => setManualCompany(e.target.value)} />
                  </div>
                  <div style={{ width: '120px' }}>
                    <label style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Difficulty</label>
                    <select className="glass-input" style={{ width: '100%', marginTop: '4px', height: '45px', boxSizing: 'border-box', background: '#1a1a1a', color: 'white' }} value={manualDifficulty} onChange={e => setManualDifficulty(e.target.value)}>
                      <option value="Easy">Easy</option>
                      <option value="Medium">Medium</option>
                      <option value="Hard">Hard</option>
                    </select>
                  </div>
                </div>
                <div>
                  <label style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Content (HTML Allowed) *</label>
                  <textarea placeholder="Problem Description or HTML..." className="glass-input" style={{ width: '100%', minHeight: '80px', marginTop: '4px' }} value={manualContent} onChange={e => setManualContent(e.target.value)} />
                </div>
                <div>
                  <label style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>Sample Test Case input</label>
                  <textarea placeholder="e.g. [2,7,11,15]\n9" className="glass-input" style={{ width: '100%', minHeight: '40px', marginTop: '4px' }} value={manualSampleInput} onChange={e => setManualSampleInput(e.target.value)} />
                </div>
                <div>
                  <label style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>All Example Testcases (separated by row)</label>
                  <textarea placeholder="e.g. [2,7,11,15]\n9\n[3,2,4]\n6" className="glass-input" style={{ width: '100%', minHeight: '40px', marginTop: '4px' }} value={manualExampleTestcases} onChange={e => setManualExampleTestcases(e.target.value)} />
                </div>
                <button onClick={handleAddManual} disabled={isSaving} className="accent-button" style={{ padding: '12px', marginTop: '12px' }}>
                  {isSaving ? 'Saving...' : 'Create Question'}
                </button>
              </div>
            )}
          </div>
        </div>
      )}

    </div>
  );
};

export default Home;
