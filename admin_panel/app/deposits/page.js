'use client';
import { useState, useEffect } from 'react';
import api from '@/lib/api';

export default function DepositsPage() {
  const [deposits, setDeposits] = useState([]);
  const [filter, setFilter] = useState('pending');
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(null);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    loadDeposits();
  }, [filter]);

  const loadDeposits = async () => {
    setLoading(true);
    try {
      const data = await api.getDeposits(filter);
      if (data.success) setDeposits(data.data.deposits);
    } catch (err) {
      console.error('Load deposits error:', err);
    } finally {
      setLoading(false);
    }
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
      <div className="page-header">
        <h2>Deposit Requests</h2>
        <p>Manage user deposit payments via UPI</p>
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
