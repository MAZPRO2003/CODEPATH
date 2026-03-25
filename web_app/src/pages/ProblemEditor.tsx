import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Editor from '@monaco-editor/react';
import { fetchProblemDetails } from '../services/problemDescriptionService';
import { executeCode, type ExecutionResult } from '../services/codeExecutionService';
import { importCompanyProblems, type Problem } from '../services/githubService';
import { fetchCustomProblemsByCompany } from '../services/customQuestionService';
import { db, auth } from '../firebase';
import { addDoc, collection, serverTimestamp, doc, setDoc, deleteDoc, getDoc, query, where, getDocs, orderBy, limit } from 'firebase/firestore';
import { Bookmark as BookmarkIcon } from 'lucide-react';

const ProblemEditor: React.FC = () => {
  const { company, id } = useParams<{ company: string; id: string }>();
  const navigate = useNavigate();

  const [problemMeta, setProblemMeta] = useState<Problem | null>(null);
  const [description, setDescription] = useState<string>('');
  const [testcaseCases, setTestcaseCases] = useState<string[]>([]);
  const [expectedOutputs, setExpectedOutputs] = useState<string[]>([]);
  const [selectedCaseIndex, setSelectedCaseIndex] = useState<number>(0);
  const [customInput, setCustomInput] = useState<string>('');
  const [ranCaseIndex, setRanCaseIndex] = useState<number>(0);
  const [isLoading, setIsLoading] = useState(true);

  const [code, setCode] = useState<string>('// Loading template...');
  const [language, setLanguage] = useState('python');
  const [codeSnippets, setCodeSnippets] = useState<any[]>([]);
  const [isBookmarked, setIsBookmarked] = useState(false);
  
  const [executing, setExecuting] = useState(false);
  const [outputs, setOutputs] = useState<(ExecutionResult | null)[]>([]);
  const [activeTab, setActiveTab] = useState<'testcase' | 'result'>('testcase');

  const languageStubs: { [key: string]: string } = {
    dart: "class Solution {\n  dynamic solve() {\n    // Write your code here\n  }\n}",
    python: "class Solution:\n    def solve(self):\n        pass",
    cpp: "class Solution {\npublic:\n    void solve() {\n        \n    }\n};",
    java: "class Solution {\n    public void solve() {\n        \n    }\n}"
  };

  useEffect(() => {
    loadData();
    checkBookmark();
  }, [company, id]);

  const checkBookmark = async () => {
    if (!auth.currentUser || !company || !id) return;
    const bookmarkId = `${auth.currentUser.uid}_${id}`;
    const docRef = doc(db, 'bookmarks', bookmarkId);
    const snap = await getDoc(docRef);
    setIsBookmarked(snap.exists());
  };

  const loadData = async () => {
    if (!company || !id) return;
    setIsLoading(true);

    const mCompany = company || 'leetcode';
    const problemsList = await importCompanyProblems(mCompany);
    const idSlug = id.toLowerCase().replace(/[^a-z0-9\\s-]/g, '').trim().replace(/\\s+/g, '-');
    
    let found: any = problemsList.find(p => 
      p.id.toString() === id || 
      (p.url && (p.url.includes(`/${id}`) || p.url.includes(`/${id}/`))) ||
      (p.title && p.title.toLowerCase().replace(/[^a-z0-9\s-]/g, '').trim().replace(/\s+/g, '-') === idSlug)
    );
    let details: any = null;

    if (!found) {
      const customList = await fetchCustomProblemsByCompany(company);
      found = customList.find(p => 
        p.id === id || 
        (p.title && p.title.toLowerCase().replace(/[^a-z0-9\s-]/g, '').trim().replace(/\s+/g, '-') === idSlug)
      );
      if (found) {
        details = {
          content: found.content || '',
          sampleTestCase: found.sampleTestCase || '',
          exampleTestcases: found.exampleTestcases || ''
        };
      }
    }

    if (found) {
      setProblemMeta(found);
      setCode(languageStubs[language] || '// Type your code here...');
      
      const slug = found.url ? found.url.split('/problems/')[1]?.split('/')[0] : id;
      if ((!details || !details.content || !details.codeSnippets || details.codeSnippets.length === 0) && slug) {
        const liveDetails = await fetchProblemDetails(slug);
        if (liveDetails && liveDetails.content) {
          details = liveDetails;
        }
      }

      if (details) {
        setDescription(details.content);
        setCustomInput(details.sampleTestCase || '');

        const snippets = details.codeSnippets || [];
        setCodeSnippets(snippets);
        const getSnippetInner = (lang: string) => {
          const map: { [key: string]: string[] } = { python: ['python3', 'python'] };
          const search = map[lang] || [lang];
          const match = snippets.find((s: any) => search.includes(s.langSlug.toLowerCase()));
          return match ? match.code : (languageStubs[lang] || '// Type here...');
        };
        setCode(getSnippetInner(language));

        const sampleLinesCount = (details.sampleTestCase || '').split('\n').filter(Boolean).length || 1;
        const allLines = (details.exampleTestcases || '').split('\n').filter(Boolean);
        
        const cases: string[] = [];
        for (let i = 0; i < allLines.length; i += sampleLinesCount) {
          cases.push(allLines.slice(i, i + sampleLinesCount).join('\n'));
        }

        if (cases.length === 0 && details.sampleTestCase) {
          cases.push(details.sampleTestCase);
        }

        setTestcaseCases(cases);
        setSelectedCaseIndex(0);
        if (cases[0]) setCustomInput(cases[0]);

        // Extract Expected Output from HTML
        const extractOutputs = (html: string): string[] => {
          const outputs: string[] = [];
          const tempDiv = document.createElement('div');
          tempDiv.innerHTML = html;
          const text = tempDiv.innerText;
          const regex = /Output:\s*([^\n]+)/gi;
          let match;
          while ((match = regex.exec(text)) !== null) {
            outputs.push(match[1].trim());
          }
          return outputs;
        };

        const expected = extractOutputs(details.content);
        setExpectedOutputs(expected);
        console.log("PROBLEM_DEBUG: Extracted Expected Outputs:", expected);
        
        // Fetch latest past submission
        if (auth.currentUser) {
          try {
            const q = query(
              collection(db, "submissions"),
              where("uid", "==", auth.currentUser.uid),
              where("title", "==", found.title),
              orderBy("timestamp", "desc"),
              limit(1)
            );
            const snap = await getDocs(q);
            if (!snap.empty) {
              const latest = snap.docs[0].data();
              if (latest.language) setLanguage(latest.language);
              if (latest.code) setCode(latest.code);
            }
          } catch (e) {
            console.error("Failed to load historical submission:", e);
          }
        }
      }
    } else {
      console.log("PROBLEM_DEBUG: Problem NOT FOUND in list!");
    }
    setIsLoading(false);
  };

  const getCodeSnippet = (lang: string) => {
    const map: { [key: string]: string[] } = { python: ['python3', 'python'] };
    const search = map[lang] || [lang];
    const match = codeSnippets.find((s: any) => search.includes(s.langSlug.toLowerCase()));
    return match ? match.code : (languageStubs[lang] || '// Type here...');
  };

  const handleRun = async () => {
    setExecuting(true);
    setActiveTab('result');
    
    const casesToRun = testcaseCases.length > 0 ? testcaseCases : [customInput];
    const newOutputs: (ExecutionResult | null)[] = new Array(casesToRun.length).fill(null);
    setOutputs(newOutputs);
    
    // Run sequentially to avoid rate limiting
    for (let i = 0; i < casesToRun.length; i++) {
      setRanCaseIndex(i); // Update UI to show current running case
      const result = await executeCode(code, language, casesToRun[i]);
      newOutputs[i] = result;
      setOutputs([...newOutputs]);
    }
    
    setExecuting(false);
  };

  const handleSubmit = async () => {
    if (!auth.currentUser || !problemMeta) return;
    try {
      await addDoc(collection(db, "submissions"), {
        uid: auth.currentUser.uid,
        title: problemMeta.title,
        company: company || 'leetcode',
        language: language,
        code: code,
        timestamp: serverTimestamp(),
      });
      alert("✅ Solution stored in Vault successfully!");
    } catch (e) {
      console.error("Save failed:", e);
      alert("❌ Failed to save submission.");
    }
  };

  const toggleBookmark = async () => {
    if (!auth.currentUser || !company || !id || !problemMeta) return;
    const bookmarkId = `${auth.currentUser.uid}_${id}`;
    const docRef = doc(db, 'bookmarks', bookmarkId);
    
    try {
      if (isBookmarked) {
        await deleteDoc(docRef);
        setIsBookmarked(false);
      } else {
        await setDoc(docRef, {
          uid: auth.currentUser.uid,
          title: problemMeta.title,
          difficulty: problemMeta.difficulty,
          company: company,
          url: problemMeta.url || `/problem/${company}/${id}`,
          content: description
        });
        setIsBookmarked(true);
      }
    } catch (e) {
      console.error('Bookmark toggle failed:', e);
    }
  };

  if (isLoading) return <div style={{ padding: '40px', textAlign: 'center' }}>Loading Workspace Environments...</div>;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', width: '100vw', background: 'var(--background)' }}>
      {/* Header bar */}
      <div style={{ padding: '12px 24px', background: 'var(--sidebar-background)', display: 'flex', alignItems: 'center', borderBottom: '1px solid var(--glass-border)' }}>
        <button onClick={() => navigate(-1)} style={{ background: 'none', border: 'none', color: 'white', cursor: 'pointer', marginRight: '16px', fontSize: '18px' }}>←</button>
        <div>
          <h3 style={{ margin: 0, fontSize: '16px' }}>{problemMeta?.title || 'Problem Workspace'}</h3>
          <span style={{ fontSize: '11px', color: 'var(--accent-green)' }}>{problemMeta?.difficulty || 'Medium'}</span>
        </div>
        
        <div style={{ marginLeft: 'auto', display: 'flex', gap: '12px', alignItems: 'center' }}>
          <button 
            onClick={toggleBookmark}
            style={{ 
              background: 'none', border: 'none', cursor: 'pointer', 
              color: isBookmarked ? 'var(--accent-blue)' : 'var(--text-secondary)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: '8px' 
            }}
            title={isBookmarked ? "Remove Bookmark" : "Add Bookmark"}
          >
            <BookmarkIcon size={20} fill={isBookmarked ? 'var(--accent-blue)' : 'none'} />
          </button>
          <select 
            value={language} 
            onChange={(e) => { 
              const lang = e.target.value;
              setLanguage(lang); 
              setCode(getCodeSnippet(lang)); 
            }}
            style={{ padding: '6px 12px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--glass-border)', color: 'white', borderRadius: '8px', cursor: 'pointer', outline: 'none' }}
          >
            <option value="dart" style={{ background: '#1a1a1a', color: 'white' }}>Dart</option>
            <option value="python" style={{ background: '#1a1a1a', color: 'white' }}>Python</option>
            <option value="cpp" style={{ background: '#1a1a1a', color: 'white' }}>C++</option>
            <option value="java" style={{ background: '#1a1a1a', color: 'white' }}>Java</option>
          </select>
          <button className="accent-button" style={{ padding: '6px 16px', fontSize: '13px', background: 'rgba(255,255,255,0.05)', border: '1px solid var(--glass-border)', color: 'white' }} onClick={handleRun} disabled={executing}>
            {executing ? 'Running...' : 'Run Code'}
          </button>
          <button className="accent-button" style={{ padding: '6px 16px', fontSize: '13px', background: 'rgba(0, 209, 255, 0.1)', color: 'var(--accent-blue)', border: '1px solid rgba(0, 209, 255, 0.3)' }} onClick={handleSubmit}>
            Submit
          </button>
        </div>
      </div>

      {/* Main Workspace split */}
      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>
        
        {/* Left: Description */}
        <div style={{ flex: 1, padding: '24px', overflowY: 'auto', borderRight: '1px solid var(--glass-border)', boxSizing: 'border-box' }}>
          <h3 style={{ marginTop: 0 }}>Description</h3>
          <div 
            dangerouslySetInnerHTML={{ __html: description || '<p>Full description setup requires CORS bypass on some modules. Loading visual headers only.</p>' }}
            style={{ color: 'rgba(255,255,255,0.8)', fontSize: '14px', lineHeight: '1.6' }}
          />
        </div>

        {/* Right: Editor and Console */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          <div style={{ flex: 1, background: '#1e1e1e' }}>
            <Editor
              height="100%"
              language={language.toLowerCase() === 'cpp' ? 'cpp' : language.toLowerCase()}
              theme="vs-dark"
              value={code}
              onChange={(value) => setCode(value || '')}
              options={{ minimap: { enabled: false }, fontSize: 14 }}
            />
          </div>
          
          {/* Tabbed Console / Testcases Area */}
          <div style={{ height: '220px', background: '#141414', borderTop: '1px solid var(--glass-border)', display: 'flex', flexDirection: 'column' }}>
            {/* Tab Headers */}
            <div style={{ display: 'flex', background: 'rgba(255,255,255,0.02)', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
              <button 
                onClick={() => setActiveTab('testcase')}
                style={{
                  padding: '8px 16px', background: 'none', border: 'none', color: activeTab === 'testcase' ? 'var(--accent-blue)' : 'rgba(255,255,255,0.5)',
                  borderBottom: activeTab === 'testcase' ? '2px solid var(--accent-blue)' : 'none', cursor: 'pointer', fontSize: '12px', fontWeight: 'bold'
                }}
              >
                Testcase
              </button>
              <button 
                onClick={() => setActiveTab('result')}
                style={{
                  padding: '8px 16px', background: 'none', border: 'none', color: activeTab === 'result' ? 'var(--accent-green)' : 'rgba(255,255,255,0.5)',
                  borderBottom: activeTab === 'result' ? '2px solid var(--accent-green)' : 'none', cursor: 'pointer', fontSize: '12px', fontWeight: 'bold'
                }}
              >
                Result
              </button>
            </div>

            {/* Tab Body */}
            <div style={{ flex: 1, padding: '16px', overflowY: 'auto' }}>
              {activeTab === 'testcase' && (
                <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                  {testcaseCases.length > 0 && (
                    <div style={{ display: 'flex', gap: '8px', marginBottom: '8px' }}>
                      {testcaseCases.map((_, idx) => (
                        <button 
                          key={idx}
                          onClick={() => { setSelectedCaseIndex(idx); setCustomInput(testcaseCases[idx]); }}
                          style={{
                            padding: '4px 10px', background: selectedCaseIndex === idx ? 'rgba(0, 209, 255, 0.15)' : 'rgba(255,255,255,0.03)',
                            border: '1px solid', borderColor: selectedCaseIndex === idx ? 'var(--accent-blue)' : 'rgba(255,255,255,0.05)',
                            color: selectedCaseIndex === idx ? 'var(--accent-blue)' : 'rgba(255,255,255,0.7)',
                            borderRadius: '6px', fontSize: '11px', cursor: 'pointer', fontWeight: 'bold'
                          }}
                        >
                          Case {idx + 1}
                        </button>
                      ))}
                    </div>
                  )}
                  <label style={{ fontSize: '11px', color: 'rgba(255,255,255,0.5)', marginBottom: '4px' }}>Custom Testcase (Stdin)</label>
                  <textarea 
                    value={customInput}
                    onChange={(e) => setCustomInput(e.target.value)}
                    style={{
                      flex: 1, background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.05)',
                      color: 'white', fontFamily: 'monospace', padding: '8px', borderRadius: '4px', resize: 'none', outline: 'none'
                    }}
                    placeholder="Enter test cases here..."
                  />
                </div>
              )}

              {activeTab === 'result' && (
                <div>
                  {outputs.length > 0 ? (
                    <div>
                      {/* Overall Status Banner */}
                      <div style={{ marginBottom: '20px' }}>
                        {executing ? (
                           <span style={{ color: 'var(--accent-blue)', fontSize: '20px', fontWeight: 'bold' }}>Executing...</span>
                        ) : (
                           (() => {
                             const passed = outputs.filter((o, i) => o && o.code === 0 && (!expectedOutputs[i] || o.stdout.trim() === expectedOutputs[i].trim())).length;
                             const allPassed = passed === outputs.length;
                             return (
                               <span style={{ color: allPassed ? '#2cbb5d' : '#ef4743', fontWeight: 'bold', fontSize: '20px' }}>
                                 {allPassed ? 'Accepted' : 'Wrong Answer'}
                               </span>
                             )
                           })()
                        )}
                        {!executing && outputs.every(o => o) && (
                          <div style={{ fontSize: '13px', color: 'rgba(255,255,255,0.7)', marginTop: '8px', fontWeight: '500' }}>
                            {outputs.filter((o, i) => o && o.code === 0 && (!expectedOutputs[i] || o.stdout.trim() === expectedOutputs[i].trim())).length} / {outputs.length} testcases passed
                          </div>
                        )}
                      </div>

                      {/* Case Selectors */}
                      <div style={{ display: 'flex', gap: '8px', marginBottom: '16px' }}>
                        {outputs.map((_, idx) => {
                          const o = outputs[idx];
                          const passed = o && o.code === 0 && (!expectedOutputs[idx] || o.stdout.trim() === expectedOutputs[idx].trim());
                          return (
                            <button 
                              key={idx}
                              onClick={() => setRanCaseIndex(idx)}
                              style={{
                                padding: '6px 12px', background: ranCaseIndex === idx ? 'rgba(255,255,255,0.1)' : 'transparent',
                                border: 'none', borderRadius: '6px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px'
                              }}
                            >
                              <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: !o ? 'gray' : passed ? '#2cbb5d' : '#ef4743' }} />
                              <span style={{ color: ranCaseIndex === idx ? 'white' : 'rgba(255,255,255,0.5)', fontSize: '12px', fontWeight: '600' }}>Case {idx + 1}</span>
                            </button>
                          );
                        })}
                      </div>

                      {/* Case Details */}
                      {outputs[ranCaseIndex] ? (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                          <div>
                            <div style={{ fontSize: '12px', color: 'rgba(255,255,255,0.6)', fontWeight: '500', marginBottom: '8px' }}>Input</div>
                            <div style={{ background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.05)' }}>
                               <pre style={{ margin: 0, fontSize: '13px', color: 'white', fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}>
                                 {testcaseCases.length > 0 ? testcaseCases[ranCaseIndex] : customInput}
                               </pre>
                            </div>
                          </div>

                          <div>
                            <div style={{ fontSize: '12px', color: 'rgba(255,255,255,0.6)', fontWeight: '500', marginBottom: '8px' }}>Output</div>
                            <div style={{ background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.05)' }}>
                               <pre style={{ margin: 0, fontSize: '13px', color: outputs[ranCaseIndex]!.code !== 0 ? '#ef4743' : 'white', fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}>
                                 {outputs[ranCaseIndex]!.stdout || " "}
                               </pre>
                            </div>
                          </div>
                          
                          {expectedOutputs[ranCaseIndex] && (
                            <div>
                              <div style={{ fontSize: '12px', color: 'rgba(255,255,255,0.6)', fontWeight: '500', marginBottom: '8px' }}>Expected</div>
                              <div style={{ background: 'rgba(255,255,255,0.05)', padding: '12px', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.05)' }}>
                                 <pre style={{ margin: 0, fontSize: '13px', color: 'white', fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}>
                                   {expectedOutputs[ranCaseIndex]}
                                 </pre>
                              </div>
                            </div>
                          )}

                          {outputs[ranCaseIndex]!.stderr && (
                            <div>
                              <div style={{ fontSize: '12px', color: '#ef4743', fontWeight: '500', marginBottom: '8px' }}>Error Details</div>
                              <div style={{ background: 'rgba(239,71,67,0.1)', padding: '12px', borderRadius: '8px', border: '1px solid rgba(239,71,67,0.2)' }}>
                                 <pre style={{ margin: 0, fontSize: '13px', color: '#ef4743', fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}>
                                   {outputs[ranCaseIndex]!.stderr}
                                 </pre>
                              </div>
                            </div>
                          )}
                        </div>
                      ) : (
                        <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: '13px' }}>Executing case {ranCaseIndex + 1}...</div>
                      )}
                    </div>
                  ) : (
                    <p style={{ margin: 0, color: 'rgba(255,255,255,0.3)', fontSize: '13px' }}>Run your code to execute on all testcases.</p>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>

      </div>
    </div>
  );
};

export default ProblemEditor;
