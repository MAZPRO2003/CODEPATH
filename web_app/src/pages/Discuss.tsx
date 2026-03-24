import React, { useEffect, useState } from 'react';
import { getPosts, createPost, type ForumPost } from '../services/forumService';
import { MessageSquare, Plus, RefreshCw } from 'lucide-react';

const Discuss: React.FC = () => {
  const [posts, setPosts] = useState<ForumPost[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');

  useEffect(() => {
    fetchPosts();
  }, []);

  const fetchPosts = async () => {
    setIsLoading(true);
    const data = await getPosts();
    setPosts(data);
    setIsLoading(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) return;

    await createPost(title, content);
    setShowModal(false);
    setTitle('');
    setContent('');
    fetchPosts();
  };

  return (
    <div style={{ padding: '32px', height: '100%', boxSizing: 'border-box', overflowY: 'auto', color: 'white' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '28px', fontWeight: 'bold' }}>Discussion Forum</h1>
          <p style={{ margin: '4px 0 0', color: 'var(--text-secondary)' }}>Join the conversation with other developers</p>
        </div>
        <div style={{ display: 'flex', gap: '16px' }}>
          <button onClick={fetchPosts} style={{ background: 'none', border: 'none', color: 'var(--accent-blue)', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <RefreshCw size={18} /> Refresh
          </button>
          <button className="accent-button" style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px' }} onClick={() => setShowModal(true)}>
            <Plus size={16} /> Ask Question
          </button>
        </div>
      </div>

      {isLoading ? (
        <div style={{ textAlign: 'center', padding: '100px 0' }}>Loading discussions...</div>
      ) : posts.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '100px 0', color: 'var(--text-secondary)' }}>No discussions yet. Be the first to ask!</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {posts.map(post => (
            <div 
              key={post.id} 
              className="glass-card" 
              style={{
                padding: '16px 24px',
                background: 'rgba(255,255,255,0.02)',
                display: 'flex',
                alignItems: 'center',
                transition: 'transform 0.2s',
                cursor: 'pointer'
              }}
              onClick={() => alert(`Detail view for ${post.title} not implemented fully yet.`)}
              onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-2px)'}
              onMouseLeave={e => e.currentTarget.style.transform = 'translateY(0)'}
            >
              {/* Avatar Icon */}
              <div style={{
                width: '48px', height: '48px', borderRadius: '50%',
                background: 'rgba(0, 209, 255, 0.1)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: 'var(--accent-blue)', marginRight: '16px'
              }}>
                <span style={{ fontSize: '18px', fontWeight: 'bold' }}>{post.author ? post.author[0].toUpperCase() : '?'}</span>
              </div>

              {/* Thread Content */}
              <div style={{ flex: 1 }}>
                <h4 style={{ margin: 0, fontSize: '16px' }}>{post.title}</h4>
                <p style={{ margin: '4px 0 0', fontSize: '12px', color: 'var(--text-secondary)' }}>
                  Posted by {post.author} • {post.timestamp?.toDate ? post.timestamp.toDate().toLocaleDateString() : 'Just now'}
                </p>
              </div>

              {/* Reply Count */}
              <div style={{
                padding: '8px 12px', background: 'rgba(255,255,255,0.05)',
                borderRadius: '20px', display: 'flex', alignItems: 'center', gap: '6px', fontSize: '14px'
              }}>
                <MessageSquare size={14} color="var(--accent-blue)" />
                <span style={{ fontWeight: 'bold' }}>{post.replyCount || 0}</span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* New Post Modal */}
      {showModal && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh',
          backgroundColor: 'rgba(0, 0, 0, 0.7)', backdropFilter: 'blur(5px)',
          display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 100
        }}>
          <div className="glass-card" style={{ width: '500px', padding: '32px', position: 'relative' }}>
            <h2 style={{ marginTop: 0, color: 'var(--accent-blue)' }}>Ask a Question</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '24px' }}>Describe your problem clearly to get answers.</p>

            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'rgba(255,255,255,0.7)', marginBottom: '8px' }}>Title</label>
                <input 
                  type="text" 
                  className="glass-input" 
                  style={{ width: '100%', boxSizing: 'border-box' }} 
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g., How to solve reverse linked list?"
                  required 
                />
              </div>

              <div style={{ marginBottom: '32px' }}>
                <label style={{ display: 'block', fontSize: '12px', color: 'rgba(255,255,255,0.7)', marginBottom: '8px' }}>Problem Details</label>
                <textarea 
                  className="glass-input" 
                  style={{ width: '100%', boxSizing: 'border-box', height: '120px', resize: 'vertical' }} 
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder="Explain your issue..."
                  required 
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" onClick={() => setShowModal(false)} style={{ background: 'none', border: 'none', color: 'white', cursor: 'pointer' }}>Cancel</button>
                <button type="submit" className="accent-button">Post Question</button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
};

export default Discuss;
