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
  const [titleHi, setTitleHi] = useState('');
  const [contentHi, setContentHi] = useState('');
  const [editingId, setEditingId] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  function showToast(message, type) {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  }

  async function loadAnnouncements() {
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
  }

  useEffect(() => {
    const timer = setTimeout(() => {
      loadAnnouncements();
    }, 0);
    return () => clearTimeout(timer);
  }, []);

  const resetForm = () => {
    setTitle('');
    setContent('');
    setTitleHi('');
    setContentHi('');
    setEditingId(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) {
      showToast('Title and Content are required', 'error');
      return;
    }

    setIsSubmitting(true);
    try {
      const payload = { title, content, titleHi, contentHi };
      if (editingId) {
        const data = await api.updateAnnouncement(editingId, payload);
        if (data.success) {
          showToast(data.message || 'Announcement updated successfully', 'success');
          resetForm();
          loadAnnouncements();
        }
      } else {
        const data = await api.createAnnouncement(payload);
        if (data.success) {
          showToast(data.message || 'Announcement created successfully', 'success');
          resetForm();
          loadAnnouncements();
        }
      }
    } catch (err) {
      showToast(err.message || `Failed to ${editingId ? 'update' : 'create'} announcement`, 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const startEdit = (ann) => {
    setEditingId(ann._id);
    setTitle(ann.title || '');
    setContent(ann.content || '');
    setTitleHi(ann.titleHi || '');
    setContentHi(ann.contentHi || '');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDelete = async (id) => {
    if (!confirm('Are you sure you want to delete this announcement?')) return;

    try {
      const data = await api.deleteAnnouncement(id);
      if (data.success) {
        showToast(data.message || 'Announcement deleted successfully', 'success');
        if (editingId === id) resetForm();
        loadAnnouncements();
      }
    } catch (err) {
      showToast(err.message || 'Failed to delete announcement', 'error');
    }
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
        {/* Create / Edit Announcement Form */}
        <div className="card" style={{ padding: '24px' }}>
          <h3 style={{ marginBottom: '16px', color: editingId ? '#3b82f6' : '#fff' }}>
            {editingId ? '✏️ Edit Announcement' : '📢 New Announcement'}
          </h3>
          <form onSubmit={handleSubmit}>
            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Title (English)</label>
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

            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500, color: '#f3a83b' }}>Title (Hindi - Optional)</label>
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
                placeholder="e.g. सर्वर रखरखाव या बोनस ऑफर"
                value={titleHi}
                onChange={(e) => setTitleHi(e.target.value)}
              />
            </div>

            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Content (English)</label>
              <textarea
                className="form-control"
                style={{
                  width: '100%',
                  height: '100px',
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

            <div className="form-group" style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500, color: '#f3a83b' }}>Content (Hindi - Optional)</label>
              <textarea
                className="form-control"
                style={{
                  width: '100%',
                  height: '80px',
                  padding: '10px',
                  background: 'rgba(255,255,255,0.05)',
                  border: '1px solid rgba(255,255,255,0.1)',
                  borderRadius: '6px',
                  color: '#fff',
                  resize: 'none',
                }}
                placeholder="घोषणा पाठ यहाँ लिखें..."
                value={contentHi}
                onChange={(e) => setContentHi(e.target.value)}
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <button
                type="submit"
                className="btn btn-primary"
                style={{
                  width: '100%',
                  padding: '12px',
                  background: editingId ? '#3b82f6' : 'var(--primary-color)',
                  borderColor: editingId ? '#3b82f6' : 'var(--primary-color)',
                }}
                disabled={isSubmitting}
              >
                {isSubmitting
                  ? (editingId ? 'Saving Changes...' : 'Posting...')
                  : (editingId ? '💾 Save Changes' : '📢 Post Announcement')}
              </button>

              {editingId && (
                <button
                  type="button"
                  className="btn"
                  style={{
                    width: '100%',
                    padding: '12px',
                    background: 'rgba(255,255,255,0.1)',
                    border: 'none',
                    borderRadius: '6px',
                    color: '#fff',
                    cursor: 'pointer',
                  }}
                  onClick={resetForm}
                >
                  Cancel Edit
                </button>
              )}
            </div>
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
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                      <h4 style={{ margin: 0, fontWeight: 600, color: '#fff', fontSize: '16px' }}>{ann.title}</h4>
                      {ann.titleHi && (
                        <span style={{ fontSize: '13px', color: '#f3a83b', fontWeight: 500 }}>🇮🇳 {ann.titleHi}</span>
                      )}
                    </div>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button
                        className="btn btn-sm btn-primary"
                        style={{
                          padding: '6px 10px',
                          fontSize: '12px',
                          background: 'rgba(59, 130, 246, 0.2)',
                          color: '#60a5fa',
                          border: '1px solid rgba(59, 130, 246, 0.4)',
                          borderRadius: '4px',
                          cursor: 'pointer',
                        }}
                        onClick={() => startEdit(ann)}
                      >
                        ✏️ Edit
                      </button>
                      <button
                        className="btn btn-sm btn-danger"
                        style={{
                          padding: '6px 10px',
                          fontSize: '12px',
                          borderRadius: '4px',
                          cursor: 'pointer',
                        }}
                        onClick={() => handleDelete(ann._id)}
                      >
                        🗑️ Delete
                      </button>
                    </div>
                  </div>
                  <p style={{ color: '#ccc', margin: '0 0 12px 0', whiteSpace: 'pre-wrap', fontSize: '14px', lineHeight: '1.5' }}>
                    {ann.content}
                  </p>
                  {ann.contentHi && (
                    <p style={{
                      color: '#aaa',
                      margin: '0 0 12px 0',
                      whiteSpace: 'pre-wrap',
                      fontSize: '13px',
                      lineHeight: '1.5',
                      fontStyle: 'italic',
                      borderLeft: '2px solid #f3a83b',
                      paddingLeft: '10px',
                    }}>
                      {ann.contentHi}
                    </p>
                  )}
                  <div style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'flex', gap: '8px' }}>
                    <span>Posted on: {formatDate(ann.createdAt)}</span>
                    {ann.updatedAt !== ann.createdAt && (
                      <span style={{ color: '#60a5fa' }}>• Edited on: {formatDate(ann.updatedAt)}</span>
                    )}
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
