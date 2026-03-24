import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';

interface RoadmapStep {
  id: string;
  title: string;
  description: string;
  problemSlugs: string[];
}

interface Roadmap {
  id: string;
  title: string;
  description: string;
  companyName: string;
  imageUrl: string;
  steps: RoadmapStep[];
}

const roadmapsData: Roadmap[] = [
  {
    id: 'google-30',
    title: 'Google 30-Day Blitz',
    description: 'Comprehensive preparation for Google software engineering roles.',
    companyName: 'Google',
    imageUrl: 'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png',
    steps: [
      { id: 'g1', title: 'Data Structures 101', description: 'Arrays and Strings masterclass.', problemSlugs: ['two-sum', 'valid-palindrome', 'longest-substring-without-repeating-characters'] },
      { id: 'g2', title: 'Trees & Graphs', description: 'Recursive patterns and traversals.', problemSlugs: ['maximum-depth-of-binary-tree', 'validate-binary-search-tree'] },
      { id: 'g3', title: 'Dynamic Programming', description: 'Optimization and memos.', problemSlugs: ['climbing-stairs', 'coin-change'] },
    ]
  },
  {
    id: 'meta-prep',
    title: 'Meta Product Track',
    description: 'Focus on social graph problems and complex data transformations.',
    companyName: 'Meta',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Meta_Platforms_Inc._logo.svg/200px-Meta_Platforms_Inc._logo.svg.png',
    steps: [
      { id: 'm1', title: 'Graph Algorithms', description: 'BFS/DFS for social networks.', problemSlugs: ['number-of-islands', 'clone-graph'] },
      { id: 'm2', title: 'String Manipulation', description: 'Parsing and matching.', problemSlugs: ['string-to-integer-atoi', 'regular-expression-matching'] },
    ]
  },
  {
    id: 'amazon-sde',
    title: 'Amazon SDE Essentials',
    description: 'Focus on scalability, OOP, and popular SDE interview questions.',
    companyName: 'Amazon',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Amazon_logo.svg/200px-Amazon_logo.svg.png',
    steps: [
      { id: 'a1', title: 'Greedy Algorithms', description: 'Local optimization for global solutions.', problemSlugs: ['jump-game', 'gas-station'] },
      { id: 'a2', title: 'System Design Patterns', description: 'Coding for large scale systems.', problemSlugs: ['lru-cache', 'design-twitter'] },
    ]
  }
];

const Roadmaps: React.FC = () => {
  const navigate = useNavigate();
  const [expandedId, setExpandedId] = useState<string | null>(null);

  return (
    <div style={{ padding: '32px', color: 'white', overflowY: 'auto', height: '100%', boxSizing: 'border-box' }}>
      <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>Interview Roadmaps</h1>
      <p style={{ margin: '4px 0 32px', color: 'var(--text-secondary)' }}>Master data structures and algorithms following premium company guides.</p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
        {roadmapsData.map(roadmap => (
          <div key={roadmap.id} className="glass-card" style={{ padding: '0', overflow: 'hidden' }}>
            <div 
              style={{ padding: '24px', display: 'flex', alignItems: 'center', cursor: 'pointer', background: 'rgba(255,255,255,0.01)' }}
              onClick={() => setExpandedId(expandedId === roadmap.id ? null : roadmap.id)}
            >
              <div style={{ width: '60px', height: '60px', padding: '10px', background: 'rgba(255,255,255,0.03)', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <img src={roadmap.imageUrl} alt={roadmap.companyName} style={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'contain' }} />
              </div>
              <div style={{ marginLeft: '20px', flex: 1 }}>
                <span style={{ fontSize: '10px', color: 'var(--accent-blue)', fontWeight: 'bold', textTransform: 'uppercase', letterSpacing: '1px' }}>{roadmap.companyName}</span>
                <h3 style={{ margin: '2px 0', fontSize: '18px' }}>{roadmap.title}</h3>
                <p style={{ margin: 0, fontSize: '13px', color: 'var(--text-secondary)' }}>{roadmap.description}</p>
              </div>
              <div style={{ color: 'rgba(255,255,255,0.3)', transform: expandedId === roadmap.id ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }}>
                ▼
              </div>
            </div>

            {expandedId === roadmap.id && (
              <div style={{ padding: '20px', background: 'rgba(0,0,0,0.2)', borderTop: '1px solid var(--glass-border)' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                  {roadmap.steps.map((step, idx) => (
                    <div key={step.id} style={{ padding: '16px', background: 'rgba(255,255,255,0.02)', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.03)' }}>
                      <div style={{ display: 'flex', alignItems: 'center', marginBottom: '8px' }}>
                        <div style={{ width: '24px', height: '24px', borderRadius: '50%', background: 'rgba(0, 209, 255, 0.1)', color: 'var(--accent-blue)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 'bold' }}>
                          {idx + 1}
                        </div>
                        <h4 style={{ margin: '0 0 0 12px', fontSize: '15px' }}>{step.title}</h4>
                      </div>
                      <p style={{ margin: '0 0 12px 36px', fontSize: '13px', color: 'var(--text-secondary)' }}>{step.description}</p>
                      
                      <div style={{ marginLeft: '36px', display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                        {step.problemSlugs.map(slug => (
                          <button 
                            key={slug}
                            className="glass-button"
                            style={{ padding: '4px 10px', fontSize: '11px', color: 'rgba(255,255,255,0.7)', borderRadius: '16px' }}
                            onClick={() => navigate(`/problem/${roadmap.companyName.toLowerCase()}/${slug}`)}
                          >
                            {slug.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ')}
                          </button>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default Roadmaps;
