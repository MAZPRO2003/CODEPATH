import React, { useEffect, useState, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Editor from '@monaco-editor/react';
import { subscribeToBattle, updateProgress } from '../services/battleService';
import { subscribeToBattleChat, sendBattleMessage, type ChatMessage } from '../services/battleChatService';
import { auth } from '../firebase';

const BattleArena: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [battleData, setBattleData] = useState<any>(null);
  const [secondsLeft, setSecondsLeft] = useState(600); // 10 minutes
  const [code, setCode] = useState('// Solve the challenge here');
  
  // Chat States
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  
  // Voice States
  const [isVoiceConnected, setIsVoiceConnected] = useState(false);
  const [isJoiningVoice, setIsJoiningVoice] = useState(false);
  const peerRef = useRef<RTCPeerConnection | null>(null);
  const localStreamRef = useRef<MediaStream | null>(null);
  const remoteAudioRef = useRef<HTMLAudioElement | null>(null);

  const uid = auth.currentUser?.uid;

  useEffect(() => {
    if (!id) return;
    
    // 1. Subscribe to Live Firestore updates for the battle
    const unsubscribe = subscribeToBattle(id, (data) => {
      setBattleData(data);
    });

    // 2. Subscribe to Chat
    const unsubscribeChat = subscribeToBattleChat(id, (msgs) => {
      setMessages(msgs);
    });

    // 3. Timer Loop countdown
    const timer = setInterval(() => {
      setSecondsLeft(prev => (prev > 0 ? prev - 1 : 0));
    }, 1000);

    return () => {
      unsubscribe();
      unsubscribeChat();
      clearInterval(timer);
      if (localStreamRef.current) {
        localStreamRef.current.getTracks().forEach(track => track.stop());
      }
      if (peerRef.current) {
        peerRef.current.close();
      }
    };
  }, [id]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const handleProgressIncrease = () => {
    if (!id) return;
    const currentProgress = uid === battleData?.player1_id ? battleData?.player1_progress : battleData?.player2_progress;
    const nextProgress = Math.min((currentProgress || 0) + 0.25, 1.0);
    updateProgress(id, nextProgress);
  };

  const myProgress = uid === battleData?.player1_id ? battleData?.player1_progress : battleData?.player2_progress;
  const opponentProgress = uid === battleData?.player1_id ? battleData?.player2_progress : battleData?.player1_progress;

  const handleSendMessage = async () => {
    if (!id || !newMessage.trim() || !uid) return;
    const senderName = uid === battleData?.player1_id ? 'Player 1' : 'Player 2';
    await sendBattleMessage(id, newMessage, uid, senderName);
    setNewMessage('');
  };

  const isGameOver = (myProgress || 0) >= 1 || (opponentProgress || 0) >= 1 || secondsLeft === 0;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', width: '100vw', background: 'var(--background)', position: 'relative' }}>
      {/* Header */}
      <div style={{ padding: '16px 24px', background: 'var(--sidebar-background)', display: 'flex', alignItems: 'center', borderBottom: '1px solid var(--glass-border)' }}>
        <span style={{ color: 'var(--accent-rose)', marginRight: '12px' }}>⚡</span>
        <h3 style={{ margin: 0, fontSize: '14px', letterSpacing: '2px', fontWeight: 'bold' }}>CODE ARENA 1v1</h3>
        <div style={{ marginLeft: 'auto', padding: '8px 16px', background: 'rgba(255,255,255,0.05)', borderRadius: '8px', color: 'var(--accent-blue)', fontFamily: 'monospace' }}>
          TIME REMAINING: {formatTime(secondsLeft)}
        </div>
      </div>

      {/* Progress Banner */}
      <div style={{ height: '60px', padding: '0 24px', display: 'flex', alignItems: 'center', gap: '40px', borderBottom: '1px solid var(--glass-border)' }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: '10px', color: 'rgba(0, 209, 255, 0.7)', fontWeight: 'bold' }}>YOU</div>
          <div style={{ height: '6px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden', marginTop: '4px' }}>
            <div style={{ width: `${(myProgress || 0) * 100}%`, height: '100%', backgroundColor: 'var(--accent-blue)', transition: 'width 0.3s' }} />
          </div>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: '10px', color: 'rgba(255, 0, 92, 0.7)', fontWeight: 'bold', textAlign: 'right' }}>OPPONENT</div>
          <div style={{ height: '6px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', overflow: 'hidden', marginTop: '4px' }}>
            <div style={{ width: `${(opponentProgress || 0) * 100}%`, height: '100%', backgroundColor: 'var(--accent-rose)', transition: 'width 0.3s' }} />
          </div>
        </div>
      </div>

      {/* Main Split */}
      <div style={{ flex: 1, display: 'flex' }}>
        {/* Left: Problem Statement placeholder for brief info */}
        <div style={{ width: '300px', borderRight: '1px solid var(--glass-border)', padding: '24px' }}>
          <h3>Challenge</h3>
          <p style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>Solve all hidden test cases. First to 100% progress wins the battle.</p>
          <button className="accent-button" style={{ marginTop: '20px', width: '100%' }} onClick={handleProgressIncrease}>Increase Progress (Test)</button>
        </div>

        {/* Center: Editor */}
        <div style={{ flex: 1, background: '#1e1e1e' }}>
          <Editor
            height="100%"
            language="dart"
            theme="vs-dark"
            value={code}
            onChange={(e) => setCode(e || '')}
            options={{ minimap: { enabled: false } }}
          />
        </div>
      </div>

      {/* Post-Battle Communication Overlay */}
      {isGameOver && (
        <div style={{
          position: 'absolute', top: 0, left: 0, width: '100%', height: '100%',
          backgroundColor: 'rgba(0,0,0,0.85)', backdropFilter: 'blur(8px)',
          display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000
        }}>
          <div className="glass-card" style={{ width: '500px', padding: '32px', display: 'flex', flexDirection: 'column' }}>
            <h2 style={{ 
              marginTop: 0, 
              color: (myProgress || 0) >= 1 ? 'var(--accent-green)' : 'var(--accent-rose)', 
              textAlign: 'center', 
              fontSize: '24px' 
            }}>
              {(myProgress || 0) >= 1 ? '🎉 VICTORY!' : '💔 DEFEAT'}
            </h2>
            <p style={{ color: 'var(--text-secondary)', textAlign: 'center', fontSize: '13px', marginBottom: '24px' }}>
              Discussion Arena with Opponent
            </p>

            {/* Voice Chat Placeholder */}
            <div style={{ display: 'flex', gap: '8px', marginBottom: '16px' }}>
              <button 
                onClick={() => { setIsJoiningVoice(!isJoiningVoice); setIsVoiceConnected(!isJoiningVoice); }}
                className="accent-button" 
                style={{ 
                  flex: 1, 
                  background: isVoiceConnected ? 'rgba(0, 200, 83, 0.1)' : 'rgba(255,255,255,0.03)',
                  color: isVoiceConnected ? 'var(--accent-green)' : 'white'
                }}
              >
                {isVoiceConnected ? '🎤 Voice Connected' : isJoiningVoice ? 'Joining...' : '🎤 Join Voice Chat'}
              </button>
            </div>

            {/* Text Chat Box */}
            <div style={{ 
              flex: 1, 
              height: '300px', 
              background: 'rgba(255,255,255,0.02)', 
              borderRadius: '12px', 
              padding: '16px', 
              overflowY: 'auto', 
              display: 'flex', 
              flexDirection: 'column', 
              gap: '12px',
              border: '1px solid rgba(255,255,255,0.05)'
            }}>
              {messages.length === 0 ? (
                <div style={{ margin: 'auto', color: 'rgba(255,255,255,0.3)', fontSize: '13px' }}>Start explaining your solution...</div>
              ) : (
                messages.map(m => (
                  <div key={m.id} style={{ alignSelf: m.senderId === uid ? 'flex-end' : 'flex-start', maxWidth: '80%' }}>
                    <div style={{ fontSize: '10px', color: 'rgba(255,255,255,0.4)', marginBottom: '2px' }}>{m.senderName}</div>
                    <div style={{ 
                      background: m.senderId === uid ? 'var(--accent-blue)' : 'rgba(255,255,255,0.05)', 
                      padding: '8px 12px', 
                      borderRadius: '8px', 
                      color: 'white', 
                      fontSize: '13px' 
                    }}>
                      {m.text}
                    </div>
                  </div>
                ))
              )}
            </div>

            <div style={{ display: 'flex', gap: '8px', marginTop: '16px' }}>
              <input 
                type="text" 
                className="glass-input" 
                placeholder="Type a message..." 
                style={{ flex: 1, padding: '10px' }} 
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
              />
              <button className="accent-button" style={{ padding: '0 16px' }} onClick={handleSendMessage}>Send</button>
            </div>

            <button 
              onClick={() => navigate('/home')} 
              style={{ marginTop: '24px', background: 'none', border: '1px solid rgba(255,255,255,0.1)', color: 'white', padding: '10px', borderRadius: '8px', cursor: 'pointer', fontSize: '13px' }}
            >
              Exit Arena
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default BattleArena;
