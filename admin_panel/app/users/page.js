'use client';
import { useState, useEffect } from 'react';
import api from '@/lib/api';

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState(null);
  const [activeTab, setActiveTab] = useState('real'); // 'real' or 'bot'

  // Edit states
  const [selectedUserForWallet, setSelectedUserForWallet] = useState(null);
  const [walletBalanceInput, setWalletBalanceInput] = useState('');
  const [selectedUserForWinning, setSelectedUserForWinning] = useState(null);
  const [winningBalanceInput, setWinningBalanceInput] = useState('');
  const [selectedUserForPassword, setSelectedUserForPassword] = useState(null);
  const [passwordInput, setPasswordInput] = useState('');

  async function loadUsers() {
    setLoading(true);
    try {
      const data = await api.getUsers(1, search, activeTab === 'bot' ? 'true' : 'false');
      if (data.success) {
        // Arrange users in order: newly first
        const sorted = [...data.data.users].sort((a, b) => {
          return new Date(b.createdAt || 0) - new Date(a.createdAt || 0);
        });
        setUsers(sorted);
      }
    } catch (err) {
      console.error('Load users error:', err);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    const timer = setTimeout(() => loadUsers(), 300);
    return () => clearTimeout(timer);
  }, [search, activeTab]);

  const handleToggle = async (userId) => {
    try {
      const data = await api.toggleUser(userId);
      if (data.success) {
        showToast(data.message, 'success');
        loadUsers();
      }
    } catch (err) {
      showToast(err.message, 'error');
    }
  };

  const handleUpdateWallet = async (e) => {
    e.preventDefault();
    if (!selectedUserForWallet) return;
    try {
      const balance = parseFloat(walletBalanceInput);
      if (isNaN(balance) || balance < 0) {
        showToast('Please enter a valid positive number', 'error');
        return;
      }
      const data = await api.updateUserWallet(selectedUserForWallet._id, balance);
      if (data.success) {
        showToast(data.message, 'success');
        setSelectedUserForWallet(null);
        loadUsers();
      }
    } catch (err) {
      showToast(err.message, 'error');
    }
  };

  const handleUpdatePassword = async (e) => {
    e.preventDefault();
    if (!selectedUserForPassword) return;
    try {
      if (passwordInput.length < 6) {
        showToast('Password must be at least 6 characters', 'error');
        return;
      }
      const data = await api.changeUserPassword(selectedUserForPassword._id, passwordInput);
      if (data.success) {
        showToast(data.message, 'success');
        setSelectedUserForPassword(null);
        setPasswordInput('');
        loadUsers();
      }
    } catch (err) {
      showToast(err.message, 'error');
    }
  };

  const openWalletModal = (user) => {
    setSelectedUserForWallet(user);
    setWalletBalanceInput(user.walletBalance.toString());
  };

  const openWinningModal = (user) => {
    setSelectedUserForWinning(user);
    setWinningBalanceInput((user.winningBalance || 0).toString());
  };

  const handleUpdateWinningWallet = async (e) => {
    e.preventDefault();
    if (!selectedUserForWinning) return;
    try {
      const balance = parseFloat(winningBalanceInput);
      if (isNaN(balance) || balance < 0) {
        showToast('Please enter a valid positive number', 'error');
        return;
      }
      const data = await api.updateUserWinningWallet(selectedUserForWinning._id, balance);
      if (data.success) {
        showToast(data.message, 'success');
        setSelectedUserForWinning(null);
        loadUsers();
      }
    } catch (err) {
      showToast(err.message, 'error');
    }
  };

  const openPasswordModal = (user) => {
    setSelectedUserForPassword(user);
    setPasswordInput(user.plainPassword || '');
  };

  const showToast = (message, type) => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric'
    });
  };

  return (
    <>
      <div className="page-header" style={{ marginBottom: '24px' }}>
        <h2>User Management</h2>
        <p>View and manage registered users, update wallets, and reset passwords</p>
      </div>

      <div className="tabs-container" style={{ display: 'flex', gap: '12px', marginBottom: '24px' }}>
        <button
          onClick={() => setActiveTab('real')}
          className={`tab-btn ${activeTab === 'real' ? 'active' : ''}`}
          style={{
            padding: '12px 24px',
            borderRadius: '12px',
            border: 'none',
            fontSize: '15px',
            fontWeight: '600',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            transition: 'all 0.3s ease',
            background: activeTab === 'real' ? 'linear-gradient(135deg, #E52D27 0%, #B31217 100%)' : 'rgba(255, 255, 255, 0.05)',
            color: activeTab === 'real' ? '#fff' : 'rgba(255, 255, 255, 0.6)',
            boxShadow: activeTab === 'real' ? '0 4px 15px rgba(229, 45, 39, 0.4)' : 'none',
          }}
        >
          👥 Real Users
        </button>
        <button
          onClick={() => setActiveTab('bot')}
          className={`tab-btn ${activeTab === 'bot' ? 'active' : ''}`}
          style={{
            padding: '12px 24px',
            borderRadius: '12px',
            border: 'none',
            fontSize: '15px',
            fontWeight: '600',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            transition: 'all 0.3s ease',
            background: activeTab === 'bot' ? 'linear-gradient(135deg, #10B981 0%, #059669 100%)' : 'rgba(255, 255, 255, 0.05)',
            color: activeTab === 'bot' ? '#fff' : 'rgba(255, 255, 255, 0.6)',
            boxShadow: activeTab === 'bot' ? '0 4px 15px rgba(16, 185, 129, 0.4)' : 'none',
          }}
        >
          🤖 Simulated Bot Players
        </button>
      </div>

      <div className="filter-bar">
        <div className="search-wrapper">
          <input
            type="text"
            className="search-input"
            placeholder={activeTab === 'bot' ? "Search bots by name, email, or phone..." : "Search users by name, email, or phone..."}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <div className="card">
        {loading ? (
          <div className="loading"><div className="loading-spinner"></div>Loading...</div>
        ) : users.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">{activeTab === 'bot' ? '🤖' : '👥'}</div>
            <h4>No {activeTab === 'bot' ? 'bot players' : 'users'} found</h4>
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>User ID</th>
                <th>Name</th>
                <th>Email / Phone</th>
                <th>Plain Password</th>
                <th>Wallet Balance</th>
                <th>Winning Balance</th>
                <th>Status</th>
                <th>Joined</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user._id}>
                  <td style={{ fontFamily: 'monospace', fontSize: '12px', color: 'var(--text-muted)' }}>
                    <div style={{ fontWeight: 'bold', color: '#fff', fontSize: '14px', marginBottom: '2px' }}>{user.uid ? `DL${user.uid}` : 'N/A'}</div>
                    <div style={{ fontSize: '10px', opacity: 0.5 }}>{user._id}</div>
                  </td>
                  <td style={{ fontWeight: 500 }}>
                    <div>{user.name}</div>
                    {user.referredUsersCount > 0 && (
                      <div style={{ fontSize: '11px', fontWeight: 'normal', color: '#10B981', marginTop: '2px' }}>
                        🎁 Referred: {user.referredUsersCount} (Earned: ₹{user.referralEarnings || 0})
                      </div>
                    )}
                  </td>
                  <td>
                    <div style={{ fontWeight: 500 }}>{user.email}</div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '12px' }}>{user.phone}</div>
                    {user.referralCode && (
                      <div style={{ fontSize: '11px', marginTop: '4px' }}>
                        <span style={{ background: 'rgba(229, 45, 39, 0.1)', color: '#E52D27', padding: '2px 5px', borderRadius: '4px', fontWeight: 600 }}>
                          Ref Code: {user.referralCode}
                        </span>
                      </div>
                    )}
                    {user.referredBy && (
                      <div style={{ fontSize: '10px', marginTop: '4px', color: 'var(--text-muted)' }}>
                        Referred By: <span style={{ fontFamily: 'monospace', background: 'rgba(255,255,255,0.05)', padding: '1px 3px', borderRadius: '3px' }}>{user.referredBy}</span>
                      </div>
                    )}
                  </td>
                  <td>
                    <span style={{ fontFamily: 'monospace', background: 'rgba(255,255,255,0.05)', padding: '2px 6px', borderRadius: '4px' }}>
                      {user.plainPassword || 'Encrypted'}
                    </span>
                  </td>
                  <td className="amount positive">
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span>₹{user.walletBalance?.toLocaleString()}</span>
                      <button 
                        className="btn btn-sm" 
                        style={{ padding: '2px 6px', background: 'rgba(255,255,255,0.08)' }} 
                        onClick={() => openWalletModal(user)}
                        title="Edit Wallet Balance"
                      >
                        ✏️
                      </button>
                    </div>
                  </td>
                  <td className="amount positive" style={{ color: '#10B981' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span>₹{(user.winningBalance || 0).toLocaleString()}</span>
                      <button 
                        className="btn btn-sm" 
                        style={{ padding: '2px 6px', background: 'rgba(255,255,255,0.08)' }} 
                        onClick={() => openWinningModal(user)}
                        title="Edit Winning Balance"
                      >
                        ✏️
                      </button>
                    </div>
                  </td>
                  <td>
                    <span className={`badge-status ${user.isActive ? 'approved' : 'rejected'}`}>
                      {user.isActive ? 'Active' : 'Blocked'}
                    </span>
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '13px' }}>{formatDate(user.createdAt)}</td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button
                        className={`btn btn-sm ${user.isActive ? 'btn-danger' : 'btn-success'}`}
                        onClick={() => handleToggle(user._id)}
                      >
                        {user.isActive ? '🚫 Block' : '✓ Activate'}
                      </button>
                      <button
                        className="btn btn-sm"
                        style={{ background: '#5bc0de', color: '#fff' }}
                        onClick={() => openPasswordModal(user)}
                      >
                        🔑 Password
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Wallet Edit Modal */}
      {selectedUserForWallet && (
        <div className="modal-overlay" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div className="card" style={{ width: '400px', padding: '24px', position: 'relative' }}>
            <h3>Edit Wallet Balance</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '16px' }}>
              Updating balance for <strong>{selectedUserForWallet.name}</strong>
            </p>
            <form onSubmit={handleUpdateWallet}>
              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Wallet Balance (₹)</label>
                <input
                  type="number"
                  className="form-control"
                  style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '6px', color: '#fff' }}
                  value={walletBalanceInput}
                  onChange={(e) => setWalletBalanceInput(e.target.value)}
                  required
                  min="0"
                  step="0.01"
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'end', gap: '12px' }}>
                <button type="button" className="btn btn-sm" style={{ background: '#888' }} onClick={() => setSelectedUserForWallet(null)}>Cancel</button>
                <button type="submit" className="btn btn-sm btn-primary">Save Balance</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Winning Wallet Edit Modal */}
      {selectedUserForWinning && (
        <div className="modal-overlay" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div className="card" style={{ width: '400px', padding: '24px', position: 'relative' }}>
            <h3>Edit Winning Balance</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '16px' }}>
              Updating winning balance for <strong>{selectedUserForWinning.name}</strong>
            </p>
            <form onSubmit={handleUpdateWinningWallet}>
              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Winning Balance (₹)</label>
                <input
                  type="number"
                  className="form-control"
                  style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '6px', color: '#fff' }}
                  value={winningBalanceInput}
                  onChange={(e) => setWinningBalanceInput(e.target.value)}
                  required
                  min="0"
                  step="0.01"
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'end', gap: '12px' }}>
                <button type="button" className="btn btn-sm" style={{ background: '#888' }} onClick={() => setSelectedUserForWinning(null)}>Cancel</button>
                <button type="submit" className="btn btn-sm btn-primary">Save Balance</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Password Reset Modal */}
      {selectedUserForPassword && (
        <div className="modal-overlay" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div className="card" style={{ width: '400px', padding: '24px', position: 'relative' }}>
            <h3>Reset User Password</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '16px' }}>
              Resetting password for <strong>{selectedUserForPassword.name}</strong>
            </p>
            <form onSubmit={handleUpdatePassword}>
              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>New Password</label>
                <input
                  type="text"
                  className="form-control"
                  style={{ width: '100%', padding: '10px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '6px', color: '#fff' }}
                  value={passwordInput}
                  onChange={(e) => setPasswordInput(e.target.value)}
                  placeholder="Enter at least 6 characters"
                  required
                  minLength="6"
                />
              </div>
              <div style={{ display: 'flex', justifyContent: 'end', gap: '12px' }}>
                <button type="button" className="btn btn-sm" style={{ background: '#888' }} onClick={() => setSelectedUserForPassword(null)}>Cancel</button>
                <button type="submit" className="btn btn-sm btn-primary">Change Password</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {toast && <div className={`toast ${toast.type}`}>{toast.message}</div>}
    </>
  );
}
