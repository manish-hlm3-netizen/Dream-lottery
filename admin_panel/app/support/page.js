'use client';
import { useState, useEffect, useRef } from 'react';
import api from '@/lib/api';
import { useAuth } from '../layout';

export default function SupportChatPage() {
  const { refreshStats } = useAuth();
  const [chatUsers, setChatUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(true);
  const [selectedUser, setSelectedUser] = useState(null);
  const [messages, setMessages] = useState([]);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [replyText, setReplyText] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState(null);
  
  const chatEndRef = useRef(null);

  async function loadChatUsers() {
    try {
      const data = await api.getChatUsers();
      if (data.success) {
        setChatUsers(data.data.chatUsers);
      }
    } catch (err) {
      console.error('Error loading chat users:', err);
    } finally {
      setLoadingUsers(false);
    }
  }

  async function loadChatHistory(userId) {
    setLoadingMessages(true);
    try {
      const data = await api.getChatHistory(userId);
      if (data.success) {
        setMessages(data.data.messages);
        setError(null);
        // Refresh sidebar unread counters
        refreshStats();
      }
    } catch (err) {
      console.error('Error loading chat history:', err);
      setError('Failed to load conversation history');
    } finally {
      setLoadingMessages(false);
    }
  }

  function scrollToBottom() {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }

  useEffect(() => {
    const timer = setTimeout(() => {
      loadChatUsers();
    }, 0);
    // Poll for new support messages every 10 seconds
    const interval = setInterval(loadChatUsers, 10000);
    return () => {
      clearTimeout(timer);
      clearInterval(interval);
    };
  }, []);

  useEffect(() => {
    if (selectedUser) {
      const timer = setTimeout(() => {
        loadChatHistory(selectedUser.user._id);
      }, 0);
      return () => clearTimeout(timer);
    }
  }, [selectedUser]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendReply = async (e) => {
    e.preventDefault();
    if (!replyText.trim() || !selectedUser || sending) return;

    const userId = selectedUser.user._id;
    const textToSend = replyText.trim();
    setReplyText('');
    setSending(true);

    try {
      const data = await api.sendChatMessage(userId, textToSend);
      if (data.success) {
        // Optimistically add message
        setMessages(prev => [...prev, data.data.message]);
        // Update user list snippets locally
        loadChatUsers();
      }
    } catch (err) {
      console.error('Send message error:', err);
      setError('Failed to send reply');
    } finally {
      setSending(false);
    }
  };

  const formatChatDate = (dateStr) => {
    const d = new Date(dateStr);
    return d.toLocaleTimeString('en-IN', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    }) + ` - ` + d.toLocaleDateString('en-IN', {
      day: 'numeric',
      month: 'short'
    });
  };

  return (
    <>
      <div className="page-header">
        <h2>💬 Support Center</h2>
        <p>Chat with users in real-time and resolve their queries.</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '320px 1fr', gap: '20px', height: 'calc(100vh - 160px)', minHeight: '500px' }}>
        
        {/* Users List Panel */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', padding: '16px', overflow: 'hidden' }}>
          <h3 style={{ marginBottom: '14px', fontSize: '16px', fontWeight: 700 }}>Active Channels</h3>
          
          {loadingUsers && chatUsers.length === 0 ? (
            <div style={{ display: 'flex', flex: 1, justifyContent: 'center', alignItems: 'center' }}>
              <div className="loading-spinner"></div>
            </div>
          ) : chatUsers.length === 0 ? (
            <div style={{ display: 'flex', flex: 1, flexDirection: 'column', justifyContent: 'center', alignItems: 'center', color: 'var(--text-muted)', fontSize: '13px' }}>
              <span style={{ fontSize: '32px', marginBottom: '8px' }}>📭</span>
              No customer care chats yet
            </div>
          ) : (
            <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {chatUsers.map((chat) => {
                const isActive = selectedUser?.user._id === chat.user._id;
                return (
                  <div
                    key={chat.user._id}
                    onClick={() => setSelectedUser(chat)}
                    style={{
                      padding: '12px',
                      borderRadius: '8px',
                      background: isActive ? 'rgba(255,255,255,0.06)' : 'rgba(255,255,255,0.02)',
                      border: isActive ? '1px solid var(--accent-primary)' : '1px solid rgba(255,255,255,0.05)',
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                      position: 'relative'
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '4px' }}>
                      <div style={{ fontWeight: 600, fontSize: '14px', color: '#fff', maxWidth: '170px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {chat.user.name}
                      </div>
                      {chat.unreadCount > 0 && (
                        <span style={{ background: 'var(--accent-success)', color: '#000', fontSize: '10px', fontWeight: 800, padding: '2px 6px', borderRadius: '10px' }}>
                          {chat.unreadCount} unread
                        </span>
                      )}
                    </div>
                    
                    <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginBottom: '8px' }}>
                      📞 {chat.user.phone}
                    </div>

                    {chat.latestMessage && (
                      <div style={{
                        fontSize: '12px',
                        color: chat.unreadCount > 0 ? '#fff' : 'var(--text-muted)',
                        fontWeight: chat.unreadCount > 0 ? 600 : 400,
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        display: '-webkit-box',
                        WebkitLineClamp: 1,
                        WebkitBoxOrient: 'vertical'
                      }}>
                        {chat.latestMessage.sender === 'admin' ? 'You: ' : ''}{chat.latestMessage.text}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Chat History Panel */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', overflow: 'hidden', padding: 0 }}>
          {selectedUser ? (
            <>
              {/* User Header */}
              <div style={{ padding: '16px 20px', borderBottom: '1px solid rgba(255,255,255,0.08)', background: 'rgba(255,255,255,0.01)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <h3 style={{ fontSize: '16px', fontWeight: 700, margin: 0, color: '#fff' }}>{selectedUser.user.name}</h3>
                  <p style={{ fontSize: '12px', color: 'var(--text-muted)', margin: '2px 0 0 0' }}>
                    Email: {selectedUser.user.email} | Phone: {selectedUser.user.phone}
                  </p>
                </div>
                <button
                  className="btn btn-outline"
                  style={{ padding: '6px 12px', fontSize: '12px' }}
                  onClick={() => loadChatHistory(selectedUser.user._id)}
                >
                  🔄 Refresh
                </button>
              </div>

              {/* Chat Messages Body */}
              <div style={{ flex: 1, padding: '20px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '14px', background: 'rgba(0,0,0,0.1)' }}>
                {loadingMessages && messages.length === 0 ? (
                  <div style={{ display: 'flex', flex: 1, justifyContent: 'center', alignItems: 'center' }}>
                    <div className="loading-spinner"></div>
                  </div>
                ) : (
                  <>
                    {messages.map((msg) => {
                      const isAdmin = msg.sender === 'admin';
                      return (
                        <div
                          key={msg._id}
                          style={{
                            alignSelf: isAdmin ? 'flex-end' : 'flex-start',
                            maxWidth: '70%',
                            display: 'flex',
                            flexDirection: 'column',
                            alignItems: isAdmin ? 'flex-end' : 'flex-start'
                          }}
                        >
                          <div
                            style={{
                              background: isAdmin
                                ? 'linear-gradient(135deg, var(--accent-primary), #6366f1)'
                                : 'rgba(255,255,255,0.06)',
                              border: isAdmin ? 'none' : '1px solid rgba(255,255,255,0.1)',
                              color: '#fff',
                              padding: '10px 14px',
                              borderRadius: isAdmin ? '16px 16px 2px 16px' : '16px 16px 16px 2px',
                              fontSize: '14px',
                              boxShadow: '0 2px 6px rgba(0,0,0,0.15)',
                              lineHeight: 1.4,
                              wordBreak: 'break-word'
                            }}
                          >
                            {msg.text}
                          </div>
                          <span style={{ fontSize: '9px', color: 'var(--text-muted)', marginTop: '4px', padding: '0 4px' }}>
                            {formatChatDate(msg.createdAt)}
                          </span>
                        </div>
                      );
                    })}
                    <div ref={chatEndRef} />
                  </>
                )}
              </div>

              {/* Chat Input Footer */}
              <form onSubmit={handleSendReply} style={{ padding: '16px 20px', borderTop: '1px solid rgba(255,255,255,0.08)', display: 'flex', gap: '12px', background: 'rgba(255,255,255,0.01)' }}>
                <input
                  type="text"
                  className="form-input"
                  placeholder="Type support reply..."
                  style={{ flex: 1, padding: '12px 16px', margin: 0, borderRadius: '24px' }}
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  disabled={sending}
                  required
                />
                <button
                  type="submit"
                  className="btn btn-primary"
                  style={{ borderRadius: '24px', padding: '0 24px', height: '42px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
                  disabled={sending || !replyText.trim()}
                >
                  {sending ? 'Sending...' : 'Send Reply 📤'}
                </button>
              </form>
            </>
          ) : (
            <div style={{ display: 'flex', flex: 1, flexDirection: 'column', justifyContent: 'center', alignItems: 'center', color: 'var(--text-muted)', padding: '40px' }}>
              <span style={{ fontSize: '64px', marginBottom: '16px' }}>💬</span>
              <h3 style={{ fontSize: '18px', fontWeight: 600, color: '#fff', marginBottom: '6px' }}>Select a conversation</h3>
              <p style={{ fontSize: '13px', margin: 0, textAlign: 'center', maxWidth: '300px' }}>
                Choose an active support channel from the left sidebar to view message history and send customer care replies.
              </p>
            </div>
          )}
        </div>

      </div>
    </>
  );
}
