'use client';
import { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';

export default function LotteryDetailPage({ params }) {
  const { id } = use(params);
  const router = useRouter();
  const [lottery, setLottery] = useState(null);
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [drawing, setDrawing] = useState(false);
  const [drawResult, setDrawResult] = useState(null);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    loadLottery();
  }, [id]);

  const loadLottery = async () => {
    try {
      const data = await api.getLotteryDetail(id);
      if (data.success) {
        setLottery(data.data.lottery);
        setTickets(data.data.tickets);
      }
    } catch (err) {
      console.error('Load lottery error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDraw = async () => {
    if (!confirm('Are you sure you want to conduct the draw? This action cannot be undone.')) return;
    setDrawing(true);
    try {
      const data = await api.drawLottery(id);
      if (data.success) {
        setDrawResult(data.data);
        showToast('Draw completed successfully!', 'success');
        loadLottery();
      }
    } catch (err) {
      showToast(err.message, 'error');
    } finally {
      setDrawing(false);
    }
  };

  const showToast = (message, type) => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  };

  if (loading) {
    return <div className="loading"><div className="loading-spinner"></div>Loading lottery details...</div>;
  }

  if (!lottery) {
    return (
      <div className="empty-state">
        <div className="empty-icon">❌</div>
        <h4>Lottery not found</h4>
      </div>
    );
  }

  return (
    <>
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <h2>{lottery.name}</h2>
          <p>{lottery.description || `Pick ${lottery.pickCount} numbers from 1-${lottery.maxNumber}`}</p>
        </div>
        <div className="btn-group">
          {['upcoming', 'active'].includes(lottery.status) && (
            <button
              className="btn btn-primary"
              onClick={handleDraw}
              disabled={drawing}
            >
              {drawing ? '🎲 Drawing...' : '🎲 Conduct Draw'}
            </button>
          )}
          <button className="btn btn-outline" onClick={() => router.back()}>
            ← Back
          </button>
        </div>
      </div>

      {/* Lottery Info Cards */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon yellow">🎫</div>
          <div className="stat-value">{lottery.totalTicketsSold}</div>
          <div className="stat-label">Tickets Sold</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon green">💰</div>
          <div className="stat-value">₹{lottery.totalRevenue?.toLocaleString()}</div>
          <div className="stat-label">Total Revenue</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon purple">🏆</div>
          <div className="stat-value">₹{lottery.totalPrizesPaid?.toLocaleString()}</div>
          <div className="stat-label">Prizes Paid</div>
        </div>
        <div className="stat-card">
          <div className="stat-icon blue">📅</div>
          <div className="stat-value" style={{ fontSize: 18 }}>{formatDate(lottery.drawDate)}</div>
          <div className="stat-label">Draw Date</div>
        </div>
      </div>

      {/* Winning Numbers */}
      {lottery.winningNumbers && lottery.winningNumbers.length > 0 && (
        <div className="card" style={{ marginBottom: 24 }}>
          <div className="card-header">
            <h3>🎲 Winning Numbers</h3>
            <span className="badge-status completed">Draw Complete</span>
          </div>
          <div className="card-body">
            <div className="winning-numbers">
              {lottery.winningNumbers.map((num, i) => (
                <div key={i} className="number-ball">{num}</div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Draw Result (shown after manual draw) */}
      {drawResult && (
        <div className="card" style={{ marginBottom: 24, border: '1px solid var(--accent-success)' }}>
          <div className="card-header">
            <h3>🎉 Draw Result</h3>
          </div>
          <div className="card-body">
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, marginBottom: 16 }}>
              <div>
                <div style={{ color: 'var(--text-muted)', fontSize: 12 }}>Total Tickets</div>
                <div style={{ fontSize: 24, fontWeight: 700 }}>{drawResult.totalTickets}</div>
              </div>
              <div>
                <div style={{ color: 'var(--text-muted)', fontSize: 12 }}>Total Winners</div>
                <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--accent-success)' }}>{drawResult.totalWinners}</div>
              </div>
              <div>
                <div style={{ color: 'var(--text-muted)', fontSize: 12 }}>Prizes Paid</div>
                <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--accent-warning)' }}>₹{drawResult.totalPrizesPaid?.toLocaleString()}</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Prize Tiers */}
      <div className="card" style={{ marginBottom: 24 }}>
        <div className="card-header">
          <h3>🏆 Prize Tiers</h3>
        </div>
        <table className="data-table">
          <thead>
            <tr>
              <th>Match</th>
              <th>Label</th>
              <th>Prize Amount</th>
            </tr>
          </thead>
          <tbody>
            {lottery.prizes?.map((prize, i) => (
              <tr key={i}>
                <td>{prize.match} numbers</td>
                <td style={{ fontWeight: 600 }}>{prize.label}</td>
                <td className="amount positive">₹{prize.amount?.toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Tickets */}
      <div className="card">
        <div className="card-header">
          <h3>🎫 Purchased Tickets ({tickets.length})</h3>
        </div>
        {tickets.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">🎫</div>
            <h4>No tickets purchased yet</h4>
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Selected Numbers</th>
                <th>Status</th>
                {lottery.status === 'completed' && (
                  <>
                    <th>Matched</th>
                    <th>Prize Won</th>
                  </>
                )}
                <th>Purchased At</th>
              </tr>
            </thead>
            <tbody>
              {tickets.map((ticket) => (
                <tr key={ticket._id}>
                  <td>
                    <div>{ticket.userId?.name || 'Unknown'}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{ticket.userId?.email}</div>
                  </td>
                  <td>
                    <div className="winning-numbers" style={{ gap: 4 }}>
                      {ticket.selectedNumbers?.map((num, i) => (
                        <div
                          key={i}
                          className={`number-ball ${ticket.matchedNumbers?.includes(num) ? 'matched' : ''}`}
                          style={{ width: 32, height: 32, fontSize: 12 }}
                        >
                          {num}
                        </div>
                      ))}
                    </div>
                  </td>
                  <td>
                    <span className={`badge-status ${ticket.status === 'won' ? 'approved' : ticket.status === 'lost' ? 'rejected' : 'active'}`}>
                      {ticket.status}
                    </span>
                  </td>
                  {lottery.status === 'completed' && (
                    <>
                      <td>{ticket.matchCount}</td>
                      <td className={`amount ${ticket.prizeWon > 0 ? 'positive' : ''}`}>
                        {ticket.prizeWon > 0 ? `₹${ticket.prizeWon.toLocaleString()}` : '-'}
                      </td>
                    </>
                  )}
                  <td style={{ color: 'var(--text-muted)', fontSize: '13px' }}>{formatDate(ticket.purchasedAt)}</td>
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
