'use client';
import { useState, useEffect } from 'react';
import api from '@/lib/api';

export default function AnnouncementsPage() {
  const [announcements, setAnnouncements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState(null);

  // Form inputs
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    loadAnnouncements();
  }, []);

  const loadAnnouncements = async () => {
    setLoading(true);
    try {
      const data = await api.getAnnouncements();
      if (data.success) {
        setAnnouncements(data.data || []);
      }
    } catch (err) {
      console.error('Load announcements error:', err);
      showToast(err.message || 'Failed to load announcements', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) {
      showToast('Title and Content are required', 'error');
      return;
    }

    setIsSubmitting(true);
    try {
      const data = await api.createAnnouncement({ title, content });
      if (data.success) {
        showToast(data.message || 'Announcement created successfully', 'success');
        setTitle('');
        setContent('');
        loadAnnouncements();
      }
    } catch (err) {
      showToast(err.message || 'Failed to create announcement', 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (id) => {
    if (!confirm('Are you sure you want to delete this announcement?')) return;

    try {
      const data = await api.deleteAnnouncement(id);
      if (data.success) {
        showToast(data.message || 'Announcement deleted successfully', 'success');
        loadAnnouncements();
      }
    } catch (err) {
      showToast(err.message || 'Failed to delete announcement', 'error');
    }
  };

  const showToast = (message, type) => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <>
      <div className="page-header">
        <h2>Announcements</h2>
        <p>Post and manage announcements displayed in the mobile app profile section</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '24px', alignItems: 'start' }}>
        {/* Create Announcement Form */}
        <div className="card" style={{ padding: '24px' }}>
          <h3 style={{ marginBottom: '16px' }}>New Announcement</h3>
          <form onSubmit={handleCreate}>
            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Title</label>
              <input
                type="text"
                className="form-control"
                style={{
                  width: '100%',
                  padding: '10px',
                  background: 'rgba(255,255,255,0.05)',
                  border: '1px solid rgba(255,255,255,0.1)',
                  borderRadius: '6px',
                  color: '#fff',
                }}
                placeholder="e.g. Server Maintenance or Bonus Offers"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
              />
            </div>
            <div className="form-group" style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Content</label>
              <textarea
                className="form-control"
                style={{
                  width: '100%',
                  height: '150px',
                  padding: '10px',
                  background: 'rgba(255,255,255,0.05)',
                  border: '1px solid rgba(255,255,255,0.1)',
                  borderRadius: '6px',
                  color: '#fff',
                  resize: 'none',
                }}
                placeholder="Write announcement text here..."
                value={content}
                onChange={(e) => setContent(e.target.value)}
                required
              />
            </div>
            <button
              type="submit"
              className="btn btn-primary"
              style={{ width: '100%', padding: '12px' }}
              disabled={isSubmitting}
            >
              {isSubmitting ? 'Posting...' : '📢 Post Announcement'}
            </button>
          </form>
        </div>

        {/* Announcements List */}
        <div className="card" style={{ padding: '24px' }}>
          <h3 style={{ marginBottom: '16px' }}>Active Announcements</h3>
          {loading ? (
            <div className="loading">
              <div className="loading-spinner"></div>Loading...
            </div>
          ) : announcements.length === 0 ? (
            <div className="empty-state" style={{ padding: '40px 0' }}>
              <div className="empty-icon" style={{ fontSize: '48px', marginBottom: '12px' }}>📢</div>
              <h4>No announcements found</h4>
              <p style={{ color: 'var(--text-muted)' }}>Create your first announcement using the form on the left</p>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {announcements.map((ann) => (
                <div
                  key={ann._id}
                  style={{
                    padding: '16px',
                    borderRadius: '8px',
                    background: 'rgba(255,255,255,0.02)',
                    border: '1px solid rgba(255,255,255,0.05)',
                    position: 'relative',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '8px' }}>
                    <h4 style={{ margin: 0, fontWeight: 600, color: '#fff' }}>{ann.title}</h4>
                    <button
                      className="btn btn-sm btn-danger"
                      style={{ padding: '4px 8px', fontSize: '12px' }}
                      onClick={() => handleDelete(ann._id)}
                    >
                      🗑️ Delete
                    </button>
                  </div>
                  <p style={{ color: '#ccc', margin: '0 0 12px 0', whiteSpace: 'pre-wrap', fontSize: '14px', lineHeight: '1.5' }}>
                    {ann.content}
                  </p>
                  <div style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'flex', gap: '8px' }}>
                    <span>Posted on: {formatDate(ann.createdAt)}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {toast && <div className={`toast ${toast.type}`}>{toast.message}</div>}
    </>
  );
}
