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

  // Custom Draw state
  const [showDrawModal, setShowDrawModal] = useState(false);
  const [drawMode, setDrawMode] = useState('random'); // 'random' or 'manual'
  const [manualNumbers, setManualNumbers] = useState([]);

  // Custom Rank Selections
  const [rankSelections, setRankSelections] = useState(Array(10).fill(''));
  const [rankCustoms, setRankCustoms] = useState(Array(10).fill([]));

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

  const handleDrawClick = () => {
    setManualNumbers(Array(lottery.pickCount).fill(''));
    setRankSelections(Array(10).fill(''));
    setRankCustoms(Array(10).fill(Array(lottery.pickCount).fill('')));
    setDrawMode('random');
    setShowDrawModal(true);
  };

  const updateRankSelection = (rankIdx, value) => {
    setRankSelections(prev => {
      const copy = [...prev];
      copy[rankIdx] = value;
      return copy;
    });
  };

  const updateRankCustom = (rankIdx, numIdx, value) => {
    setRankCustoms(prev => {
      const copy = [...prev];
      const customCopy = [...copy[rankIdx]];
      customCopy[numIdx] = value;
      copy[rankIdx] = customCopy;
      return copy;
    });
  };

  const getRankNumbers = (selection, customNums) => {
    if (selection === 'custom') {
      const parsed = customNums.map(n => parseInt(n));
      const invalid = parsed.some(n => isNaN(n) || n < 1 || n > lottery.maxNumber);
      if (invalid) {
        throw new Error(`All numbers must be valid integers between 1 and ${lottery.maxNumber}`);
      }
      const unique = new Set(parsed);
      if (unique.size !== parsed.length) {
        throw new Error('All numbers must be unique');
      }
      return parsed;
    } else if (selection && selection !== '') {
      return selection.split(',').map(n => parseInt(n));
    }
    return null;
  };

  const handleDrawSubmit = async (e) => {
    e.preventDefault();
    
    let drawData = {};
    if (drawMode === 'manual') {
      try {
        const rankWinningNumbers = [];
        let hasAnySelection = false;

        for (let i = 0; i < 10; i++) {
          const selection = rankSelections[i];
          const customVal = rankCustoms[i];
          
          const nums = getRankNumbers(selection, customVal);
          rankWinningNumbers.push(nums);
          if (nums) hasAnySelection = true;
        }

        if (!hasAnySelection) {
          showToast('Please select/enter at least one winner rank combination or use Random Draw.', 'error');
          return;
        }

        drawData.rankWinningNumbers = rankWinningNumbers;
      } catch (err) {
        showToast(err.message, 'error');
        return;
      }
    }

    if (!confirm('Are you sure you want to conduct the draw? This action cannot be undone.')) return;
    
    setDrawing(true);
    setShowDrawModal(false);
    try {
      const data = await api.drawLottery(id, drawMode === 'manual' ? drawData : null);
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
              onClick={handleDrawClick}
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
              <th>Rank</th>
              <th>Label</th>
              <th>Prize Amount</th>
            </tr>
          </thead>
          <tbody>
            {lottery.prizes?.map((prize, i) => (
              <tr key={i}>
                <td>{prize.match <= 3 ? `Rank ${prize.match}` : `Ranks 4-10`}</td>
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
                    <span className={`badge-status ${ticket.status === 'won' ? 'approved' : ticket.status === 'lost' ? 'rejected' : 'active'}`} style={{ textTransform: 'capitalize' }}>
                      {ticket.status === 'won' && ticket.rank > 0 ? `won (Rank ${ticket.rank})` : ticket.status}
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

      {/* Conduct Draw Modal */}
      {showDrawModal && (
        <div className="modal-overlay" style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div className="card" style={{ width: '550px', padding: '24px', position: 'relative' }}>
            <h3>Conduct Lottery Draw</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '16px' }}>
              Choose draw method for <strong>{lottery.name}</strong>
            </p>
            
            <form onSubmit={handleDrawSubmit}>
              <div className="form-group" style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Draw Mode</label>
                <div style={{ display: 'flex', gap: '16px' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                    <input
                      type="radio"
                      name="drawMode"
                      value="random"
                      checked={drawMode === 'random'}
                      onChange={() => setDrawMode('random')}
                    />
                    <span>Random Draw (Generate Auto)</span>
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                    <input
                      type="radio"
                      name="drawMode"
                      value="manual"
                      checked={drawMode === 'manual'}
                      onChange={() => setDrawMode('manual')}
                    />
                    <span>Self Select Winner Numbers</span>
                  </label>
                </div>
              </div>

              {drawMode === 'manual' && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', maxHeight: '380px', overflowY: 'auto', paddingRight: '4px', marginBottom: '20px' }}>
                  {(() => {
                    const uniqueCombinations = [];
                    const seen = new Set();
                    for (const t of tickets) {
                      const key = t.selectedNumbers.join(',');
                      if (!seen.has(key)) {
                        seen.add(key);
                        uniqueCombinations.push({
                          numbers: t.selectedNumbers,
                          label: `${t.userId?.name || 'User'} - Numbers: [${t.selectedNumbers.join(', ')}]`,
                          key
                        });
                      }
                    }

                    const fields = [];
                    for (let rankNum = 1; rankNum <= 10; rankNum++) {
                      const rankIdx = rankNum - 1;
                      const selection = rankSelections[rankIdx] || '';
                      const customVal = rankCustoms[rankIdx] || [];

                      const rankEmoji = rankNum === 1 ? '🏆' : rankNum === 2 ? '🥈' : rankNum === 3 ? '🥉' : '🎟️';
                      const label = `${rankEmoji} Rank ${rankNum} Winner${rankNum >= 4 ? ' (4-10 Tier)' : ''}`;

                      fields.push(
                        <div key={rankNum} className="form-group" style={{ background: 'rgba(255,255,255,0.02)', padding: '12px', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.05)' }}>
                          <label style={{ display: 'block', fontWeight: 600, fontSize: '13px', marginBottom: '8px', color: 'var(--accent-warning)' }}>
                            {label}
                          </label>
                          <select
                            className="form-input"
                            style={{ width: '100%', marginBottom: selection === 'custom' ? '10px' : '0' }}
                            value={selection}
                            onChange={(e) => updateRankSelection(rankIdx, e.target.value)}
                          >
                            <option value="">-- Random / Raffle Shuffled --</option>
                            <option value="custom">✍️ Custom Combination</option>
                            {uniqueCombinations.map((combo) => (
                              <option key={combo.key} value={combo.key}>
                                {combo.label}
                              </option>
                            ))}
                          </select>

                          {selection === 'custom' && (
                            <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', marginTop: '6px' }}>
                              {Array(lottery.pickCount).fill(0).map((_, i) => (
                                <input
                                  key={i}
                                  type="number"
                                  min="1"
                                  max={lottery.maxNumber}
                                  required
                                  style={{
                                    width: '45px',
                                    padding: '6px',
                                    background: 'rgba(255,255,255,0.05)',
                                    border: '1px solid rgba(255,255,255,0.1)',
                                    borderRadius: '4px',
                                    color: '#fff',
                                    textAlign: 'center',
                                    fontSize: '12px'
                                  }}
                                  value={customVal[i] || ''}
                                  onChange={(e) => updateRankCustom(rankIdx, i, e.target.value)}
                                />
                              ))}
                            </div>
                          )}
                        </div>
                      );
                    }
                    return fields;
                  })()}
                </div>
              )}

              <div style={{ display: 'flex', justifyContent: 'end', gap: '12px', marginTop: '24px' }}>
                <button type="button" className="btn btn-sm" style={{ background: '#888' }} onClick={() => setShowDrawModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-sm btn-primary">
                  Draw Now
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {toast && <div className={`toast ${toast.type}`}>{toast.message}</div>}
    </>
  );
}
