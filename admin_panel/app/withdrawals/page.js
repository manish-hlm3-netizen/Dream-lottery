'use client';
import { useState, useEffect } from 'react';
import api from '@/lib/api';

export default function WithdrawalsPage() {
  const [withdrawals, setWithdrawals] = useState([]);
  const [filter, setFilter] = useState('pending');
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(null);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    loadWithdrawals();
  }, [filter]);

  const loadWithdrawals = async () => {
    setLoading(true);
    try {
      const data = await api.getWithdrawals(filter);
      if (data.success) setWithdrawals(data.data.withdrawals);
    } catch (err) {
      console.error('Load withdrawals error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleProcess = async (id, action) => {
    const note = action === 'reject' ? prompt('Reason for rejection (optional):') : '';
    setProcessing(id);
    try {
      const data = await api.processWithdrawal(id, action, note || '');
      if (data.success) {
        showToast(`Withdrawal ${action === 'approve' ? 'approved' : 'rejected'}`, 'success');
        loadWithdrawals();
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
      <div className="page-header">
        <h2>Withdrawal Requests</h2>
        <p>Process user withdrawal requests to UPI</p>
      </div>

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
        ) : withdrawals.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">💸</div>
            <h4>No {filter} withdrawals</h4>
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Amount</th>
                <th>UPI ID</th>
                <th>User Balance</th>
                <th>Status</th>
                <th>Date</th>
                {filter === 'pending' && <th>Actions</th>}
              </tr>
            </thead>
            <tbody>
              {withdrawals.map((w) => (
                <tr key={w._id}>
                  <td>
                    <div>{w.userId?.name || 'Unknown'}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{w.userId?.phone}</div>
                  </td>
                  <td className="amount negative">₹{w.amount?.toLocaleString()}</td>
                  <td style={{ fontFamily: 'monospace', fontSize: '13px' }}>{w.upiId}</td>
                  <td className="amount">₹{w.userId?.walletBalance?.toLocaleString()}</td>
                  <td><span className={`badge-status ${w.status}`}>{w.status}</span></td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '13px' }}>{formatDate(w.createdAt)}</td>
                  {filter === 'pending' && (
                    <td>
                      <div className="btn-group">
                        <button
                          className="btn btn-success btn-sm"
                          onClick={() => handleProcess(w._id, 'approve')}
                          disabled={processing === w._id}
                        >
                          ✓ Approve
                        </button>
                        <button
                          className="btn btn-danger btn-sm"
                          onClick={() => handleProcess(w._id, 'reject')}
                          disabled={processing === w._id}
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
