import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Editor from '@monaco-editor/react';
import { fetchProblemDetails } from '../services/problemDescriptionService';
import { executeCode, type ExecutionResult } from '../services/codeExecutionService';
import { importCompanyProblems, type Problem } from '../services/githubService';
import { db, auth } from '../firebase';
import { addDoc, collection, serverTimestamp } from 'firebase/firestore';

const ProblemEditor: React.FC = () => {
  const { company, id } = useParams<{ company: string; id: string }>();
  const navigate = useNavigate();

  const [problemMeta, setProblemMeta] = useState<Problem | null>(null);
  const [description, setDescription] = useState<string>('');
  const [sampleTestCase, setSampleTestCase] = useState<string>('');
  const [testcaseCases, setTestcaseCases] = useState<string[]>([]);
  const [expectedOutputs, setExpectedOutputs] = useState<string[]>([]);
  const [selectedCaseIndex, setSelectedCaseIndex] = useState<number>(0);
  const [customInput, setCustomInput] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);

  const [code, setCode] = useState<string>('// Loading template...');
  const [language, setLanguage] = useState('dart');
  
  const [executing, setExecuting] = useState(false);
  const [output, setOutput] = useState<ExecutionResult | null>(null);
  const [activeTab, setActiveTab] = useState<'testcase' | 'result'>('testcase');

  const languageStubs: { [key: string]: string } = {
    dart: "void main() {\n  print('Hello, CodePath!');\n}",
    python: "def solve():\n    print('Hello, CodePath!')\n\nif __name__ == '__main__':\n    solve()",
    cpp: "#include <iostream>\n\nint main() {\n    std::cout << \"Hello, CodePath!\" << std::endl;\n    return 0;\n}",
    java: "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, CodePath!\");\n    }\n}"
  };

  useEffect(() => {
    loadData();
  }, [company, id]);

  const loadData = async () => {
    if (!company || !id) return;
    setIsLoading(true);

    const problemsList = await importCompanyProblems(company);
    const found = problemsList.find(p => p.id.toString() === id);
    if (found) {
      setProblemMeta(found);
      setCode(languageStubs[language] || '// Type your code here...');
      
      const slug = found.url ? found.url.split('/problems/')[1]?.split('/')[0] : id;
      console.log("PROBLEM_DEBUG: ID:", id, "URL:", found.url, "SLUG:", slug);
      if (slug) {
        const details = await fetchProblemDetails(slug);
        console.log("PROBLEM_DEBUG: Fetched Details:", details);
        setDescription(details.content);
        setSampleTestCase(details.sampleTestCase || '');
        setCustomInput(details.sampleTestCase || '');

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
      }
    } else {
      console.log("PROBLEM_DEBUG: Problem NOT FOUND in list!");
    }
    setIsLoading(false);
  };

  const handleRun = async () => {
    setExecuting(true);
    setActiveTab('result');
    const result = await executeCode(code, language, customInput);
    setOutput(result);
    setExecuting(false);
  };

  const handleSubmit = async () => {
    if (!auth.currentUser || !problemMeta) return;
    try {
      await addDoc(collection(db, "submissions"), {
        uid: auth.currentUser.uid,
        title: problemMeta.title,
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
        
        <div style={{ marginLeft: 'auto', display: 'flex', gap: '12px' }}>
          <select 
            value={language} 
            onChange={(e) => { setLanguage(e.target.value); setCode(languageStubs[e.target.value] || '// Type here'); }}
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
                  {executing ? (
                    <p style={{ color: 'var(--accent-blue)', fontSize: '13px' }}>Executing code on Judge0...</p>
                  ) : output ? (
                    <div>
                      <div style={{ display: 'flex', gap: '16px', marginBottom: '12px', fontSize: '12px' }}>
                        <span style={{ 
                          color: output.code === 0 && (!expectedOutputs[selectedCaseIndex] || output.stdout.trim() === expectedOutputs[selectedCaseIndex].trim()) ? 'var(--accent-green)' : 'var(--accent-rose)', 
                          fontWeight: 'bold' 
                        }}>
                          Status: {output.code !== 0 ? `Error (${output.code})` : 
                                   expectedOutputs[selectedCaseIndex] && output.stdout.trim() !== expectedOutputs[selectedCaseIndex].trim() ? 'Wrong Answer' : 'Accepted'}
                        </span>
                        {output.time && <span>Time: {output.time}s</span>}
                        {output.memory && <span>Memory: {output.memory} KB</span>}
                      </div>

                      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        <div>
                          <span style={{ fontSize: '11px', color: 'rgba(255,255,255,0.5)' }}>Actual Output</span>
                          <pre style={{ margin: '4px 0 0', background: 'rgba(255,255,255,0.03)', padding: '8px', borderRadius: '4px', fontSize: '13px', color: 'white' }}>
                            {output.stdout || "No standard output"}
                          </pre>
                        </div>
                        {expectedOutputs[selectedCaseIndex] && (
                          <div>
                            <span style={{ fontSize: '11px', color: 'rgba(255,255,255,0.5)' }}>Expected Output</span>
                            <pre style={{ margin: '4px 0 0', background: 'rgba(0, 200, 83, 0.05)', padding: '8px', borderRadius: '4px', fontSize: '13px', color: 'var(--accent-green)' }}>
                              {expectedOutputs[selectedCaseIndex]}
                            </pre>
                          </div>
                        )}
                        {output.stderr && (
                          <div>
                            <span style={{ fontSize: '11px', color: 'var(--accent-rose)' }}>Error Output</span>
                            <pre style={{ margin: '4px 0 0', background: 'rgba(255, 0, 92, 0.05)', padding: '8px', borderRadius: '4px', fontSize: '12px', color: 'var(--accent-rose)' }}>
                              {output.stderr}
                            </pre>
                          </div>
                        )}
                      </div>
                    </div>
                  ) : (
                    <p style={{ margin: 0, color: 'rgba(255,255,255,0.3)', fontSize: '13px' }}>Run your code to execute on the testcase.</p>
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
