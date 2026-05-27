'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import api from '@/lib/api';

export default function LotteriesPage() {
  const [lotteries, setLotteries] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadLotteries();
  }, []);

  const loadLotteries = async () => {
    try {
      const data = await api.getLotteries();
      if (data.success) setLotteries(data.data.lotteries);
    } catch (err) {
      console.error('Load lotteries error:', err);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  };

  return (
    <>
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <h2>Lotteries</h2>
          <p>Manage lottery draws and results</p>
        </div>
        <Link href="/lotteries/create" className="btn btn-primary">
          ➕ Create Lottery
        </Link>
      </div>

      <div className="card">
        {loading ? (
          <div className="loading"><div className="loading-spinner"></div>Loading...</div>
        ) : lotteries.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">🎰</div>
            <h4>No lotteries created yet</h4>
            <p style={{ marginTop: 8 }}>Create your first lottery to get started</p>
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Ticket Price</th>
                <th>Tickets Sold</th>
                <th>Revenue</th>
                <th>Draw Date</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {lotteries.map((lottery) => (
                <tr key={lottery._id}>
                  <td>
                    <div style={{ fontWeight: 600 }}>{lottery.name}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                      Pick {lottery.pickCount} from 1-{lottery.maxNumber}
                    </div>
                  </td>
                  <td className="amount">₹{lottery.ticketPrice}</td>
                  <td>{lottery.totalTicketsSold}</td>
                  <td className="amount positive">₹{lottery.totalRevenue?.toLocaleString()}</td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '13px' }}>{formatDate(lottery.drawDate)}</td>
                  <td><span className={`badge-status ${lottery.status}`}>{lottery.status}</span></td>
                  <td>
                    <Link href={`/lotteries/${lottery._id}`} className="btn btn-outline btn-sm">
                      View Details
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </>
  );
}
