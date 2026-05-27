'use client';
import { useState, useEffect } from 'react';
import api from '@/lib/api';

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [recentTxns, setRecentTxns] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    try {
      const data = await api.getDashboard();
      if (data.success) {
        setStats(data.data.stats);
        setRecentTxns(data.data.recentTransactions);
      }
    } catch (err) {
      console.error('Dashboard error:', err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="loading">
        <div className="loading-spinner"></div>
        Loading dashboard...
      </div>
    );
  }

  const statCards = [
    { icon: '👥', label: 'Total Users', value: stats?.totalUsers || 0, color: 'purple' },
    { icon: '💰', label: 'Pending Deposits', value: stats?.pendingDeposits || 0, color: 'yellow' },
    { icon: '💸', label: 'Pending Withdrawals', value: stats?.pendingWithdrawals || 0, color: 'red' },
    { icon: '🎰', label: 'Active Lotteries', value: stats?.activeLotteries || 0, color: 'blue' },
    { icon: '✅', label: 'Completed Draws', value: stats?.completedLotteries || 0, color: 'green' },
    { icon: '💎', label: 'Total Revenue', value: `₹${(stats?.totalRevenue || 0).toLocaleString()}`, color: 'purple' },
  ];

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  };

  return (
    <>
      <div className="page-header">
        <h2>Dashboard</h2>
        <p>Overview of your lottery platform</p>
      </div>

      <div className="stats-grid">
        {statCards.map((card, i) => (
          <div key={i} className="stat-card">
            <div className={`stat-icon ${card.color}`}>{card.icon}</div>
            <div className="stat-value">{card.value}</div>
            <div className="stat-label">{card.label}</div>
          </div>
        ))}
      </div>

      <div className="card">
        <div className="card-header">
          <h3>Recent Transactions</h3>
        </div>
        {recentTxns.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📭</div>
            <h4>No transactions yet</h4>
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Type</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {recentTxns.map((txn) => (
                <tr key={txn._id}>
                  <td>{txn.userId?.name || 'Unknown'}</td>
                  <td style={{ textTransform: 'capitalize' }}>{txn.type?.replace('_', ' ')}</td>
                  <td className={`amount ${txn.type === 'winnings' ? 'positive' : ''}`}>
                    ₹{txn.amount?.toLocaleString()}
                  </td>
                  <td><span className={`badge-status ${txn.status}`}>{txn.status}</span></td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '13px' }}>{formatDate(txn.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </>
  );
}
