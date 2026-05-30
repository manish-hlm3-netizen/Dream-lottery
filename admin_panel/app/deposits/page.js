'use client';
import { useState, useEffect } from 'react';
import api from '@/lib/api';

export default function DepositsPage() {
  const [deposits, setDeposits] = useState([]);
  const [filter, setFilter] = useState('pending');
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(null);
  const [toast, setToast] = useState(null);

  // UPI settings state
  const [upiId, setUpiId] = useState('');
  const [qrCodeUrl, setQrCodeUrl] = useState('');
  const [updatingSettings, setUpdatingSettings] = useState(false);
  const [showSettings, setShowSettings] = useState(false);

  async function loadUPISettings() {
    try {
      const res = await api.getUPISettings();
      if (res.success) {
        setUpiId(res.data.upiId);
        setQrCodeUrl(res.data.qrCodeUrl || '');
      }
    } catch (err) {
      console.error('Load UPI Settings error:', err);
    }
  }

  async function loadDeposits() {
    setLoading(true);
    try {
      const data = await api.getDeposits(filter);
      if (data.success) setDeposits(data.data.deposits);
    } catch (err) {
      console.error('Load deposits error:', err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    const timer = setTimeout(() => {
      loadDeposits();
      loadUPISettings();
    }, 0);
    return () => clearTimeout(timer);
  }, [filter]);

  const handleSettingsSubmit = async (e) => {
    e.preventDefault();
    setUpdatingSettings(true);
    try {
      const res = await api.updateUPISettings({ upiId, qrCodeUrl });
      if (res.success) {
        showToast('UPI Payment settings updated successfully!', 'success');
        setShowSettings(false);
      }
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      setUpdatingSettings(false);
    }
  };

  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    if (file.size > 1024 * 1024) {
      showToast('Image must be under 1MB in size', 'error');
      return;
    }

    const reader = new FileReader();
    reader.onloadend = () => {
      setQrCodeUrl(reader.result);
    };
    reader.readAsDataURL(file);
  };

  const handleProcess = async (depositId, action) => {
    const note = action === 'reject' ? prompt('Reason for rejection (optional):') : '';
    setProcessing(depositId);
    try {
      const data = await api.processDeposit(depositId, action, note || '');
      if (data.success) {
        showToast(`Deposit ${action === 'approve' ? 'approved' : 'rejected'} successfully`, 'success');
        loadDeposits();
      }
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      setProcessing(null);
    }
  };

  const showToast = (message, type) => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  };

  return (
    <>
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2>Deposit Requests</h2>
          <p>Manage user deposit payments via UPI</p>
        </div>
        <button 
          className="btn btn-outline"
          onClick={() => setShowSettings(!showSettings)}
          style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
        >
          ⚙️ Configure QR & UPI ID
        </button>
      </div>

      {/* UPI Payment Configuration Card */}
      {showSettings && (
        <div className="card" style={{ padding: '24px', marginBottom: '24px', background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.08)' }}>
          <h3 style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>💳 UPI Deposit Settings</h3>
          <form onSubmit={handleSettingsSubmit} style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
            <div>
              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Active UPI ID</label>
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
                  placeholder="e.g. business@upi"
                  value={upiId}
                  onChange={(e) => setUpiId(e.target.value)}
                  required
                />
              </div>

              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Upload QR Code Image (UPI)</label>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleImageUpload}
                  style={{
                    width: '100%',
                    padding: '8px',
                    background: 'rgba(255,255,255,0.02)',
                    border: '1px dashed rgba(255,255,255,0.2)',
                    borderRadius: '6px',
                    color: '#ccc',
                    cursor: 'pointer'
                  }}
                />
                <small style={{ color: 'var(--text-muted)', display: 'block', marginTop: '4px' }}>
                  Recommended: Select square QR code image. Max 1MB.
                </small>
              </div>

              <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
                <button type="submit" className="btn btn-primary" disabled={updatingSettings}>
                  {updatingSettings ? 'Saving...' : '💾 Save Settings'}
                </button>
                <button type="button" className="btn btn-outline" onClick={() => setShowSettings(false)}>
                  Cancel
                </button>
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', borderLeft: '1px solid rgba(255,255,255,0.05)', paddingLeft: '24px' }}>
              <span style={{ color: 'var(--text-muted)', fontSize: '13px', marginBottom: '12px' }}>Live QR Code Preview:</span>
              {qrCodeUrl ? (
                <div style={{ padding: '12px', background: '#fff', borderRadius: '12px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                  <img src={qrCodeUrl} alt="QR Code Preview" style={{ width: '150px', height: '150px', objectFit: 'contain' }} />
                </div>
              ) : (
                <div style={{ width: '150px', height: '150px', borderRadius: '12px', border: '2px dashed rgba(255,255,255,0.1)', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', color: 'var(--text-muted)' }}>
                  <span style={{ fontSize: '24px' }}>📸</span>
                  <span style={{ fontSize: '11px', marginTop: '4px' }}>No QR Uploaded</span>
                </div>
              )}
            </div>
          </form>
        </div>
      )}

      <div className="filter-bar">
        <div className="filter-tabs">
          {['pending', 'approved', 'rejected', 'all'].map((f) => (
            <button
              key={f}
              className={`filter-tab ${filter === f ? 'active' : ''}`}
              onClick={() => setFilter(f)}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="card">
        {loading ? (
          <div className="loading"><div className="loading-spinner"></div>Loading...</div>
        ) : deposits.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">💰</div>
            <h4>No {filter} deposits</h4>
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Amount</th>
                <th>UPI Txn ID</th>
                <th>Status</th>
                <th>Date</th>
                {filter === 'pending' && <th>Actions</th>}
              </tr>
            </thead>
            <tbody>
              {deposits.map((dep) => (
                <tr key={dep._id}>
                  <td>
                    <div>{dep.userId?.name || 'Unknown'}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{dep.userId?.email}</div>
                  </td>
                  <td className="amount">₹{dep.amount?.toLocaleString()}</td>
                  <td style={{ fontFamily: 'monospace', fontSize: '13px' }}>{dep.upiTransactionId}</td>
                  <td><span className={`badge-status ${dep.status}`}>{dep.status}</span></td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '13px' }}>{formatDate(dep.createdAt)}</td>
                  {filter === 'pending' && (
                    <td>
                      <div className="btn-group">
                        <button
                          className="btn btn-success btn-sm"
                          onClick={() => handleProcess(dep._id, 'approve')}
                          disabled={processing === dep._id}
                        >
                          ✓ Approve
                        </button>
                        <button
                          className="btn btn-danger btn-sm"
                          onClick={() => handleProcess(dep._id, 'reject')}
                          disabled={processing === dep._id}
                        >
                          ✕ Reject
                        </button>
                      </div>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {toast && <div className={`toast ${toast.type}`}>{toast.message}</div>}
    </>
  );
}
