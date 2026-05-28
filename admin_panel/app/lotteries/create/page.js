'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api';

export default function CreateLotteryPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [form, setForm] = useState({
    name: '',
    description: '',
    ticketPrice: 50,
    maxNumber: 49,
    pickCount: 6,
    drawDate: '',
    isAutomatic: true,
    prizes: [
      { match: 6, label: 'Jackpot', amount: 50000 },
      { match: 5, label: '2nd Prize', amount: 5000 },
      { match: 4, label: '3rd Prize', amount: 500 },
      { match: 3, label: 'Consolation', amount: 100 }
    ]
  });

  const updateForm = (key, value) => {
    setForm(prev => ({ ...prev, [key]: value }));
  };

  const updatePrize = (index, key, value) => {
    setForm(prev => {
      const prizes = [...prev.prizes];
      prizes[index] = { ...prizes[index], [key]: key === 'amount' || key === 'match' ? Number(value) : value };
      return { ...prev, prizes };
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const data = await api.createLottery({
        ...form,
        ticketPrice: Number(form.ticketPrice),
        maxNumber: Number(form.maxNumber),
        pickCount: Number(form.pickCount)
      });
      if (data.success) {
        router.push('/lotteries');
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Set minimum datetime to now
  const minDateTime = new Date().toISOString().slice(0, 16);

  return (
    <>
      <div className="page-header">
        <h2>Create New Lottery</h2>
        <p>Set up a new lottery draw for users</p>
      </div>

      <div className="card">
        <div className="card-body">
          {error && <div className="login-error" style={{ marginBottom: 24 }}>{error}</div>}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label">Lottery Name *</label>
              <input
                type="text"
                className="form-input"
                placeholder="e.g., Mega Draw #1"
                value={form.name}
                onChange={(e) => updateForm('name', e.target.value)}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Description</label>
              <textarea
                className="form-input form-textarea"
                placeholder="Describe the lottery..."
                value={form.description}
                onChange={(e) => updateForm('description', e.target.value)}
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Ticket Price (₹) *</label>
                <input
                  type="number"
                  className="form-input"
                  min="1"
                  value={form.ticketPrice}
                  onChange={(e) => updateForm('ticketPrice', e.target.value)}
                  required
                />
              </div>
              <div className="form-group">
                <label className="form-label">Draw Date & Time *</label>
                <input
                  type="datetime-local"
                  className="form-input"
                  min={minDateTime}
                  value={form.drawDate}
                  onChange={(e) => updateForm('drawDate', e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Numbers Range (1 to ?)</label>
                <input
                  type="number"
                  className="form-input"
                  min="10"
                  max="99"
                  value={form.maxNumber}
                  onChange={(e) => updateForm('maxNumber', e.target.value)}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Numbers to Pick</label>
                <input
                  type="number"
                  className="form-input"
                  min="1"
                  max="10"
                  value={form.pickCount}
                  onChange={(e) => updateForm('pickCount', e.target.value)}
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Draw Mode</label>
              <div style={{ display: 'flex', gap: 16, marginTop: 8 }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', color: 'var(--text-secondary)' }}>
                  <input
                    type="radio"
                    checked={form.isAutomatic}
                    onChange={() => updateForm('isAutomatic', true)}
                  />
                  ⏰ Automatic (at draw date)
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', color: 'var(--text-secondary)' }}>
                  <input
                    type="radio"
                    checked={!form.isAutomatic}
                    onChange={() => updateForm('isAutomatic', false)}
                  />
                  👤 Manual (admin triggers)
                </label>
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Prize Tiers</label>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginTop: 8 }}>
                {form.prizes.map((prize, i) => (
                  <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                    <input
                      type="number"
                      className="form-input"
                      style={{ width: 80 }}
                      placeholder="Match"
                      value={prize.match}
                      onChange={(e) => updatePrize(i, 'match', e.target.value)}
                    />
                    <input
                      type="text"
                      className="form-input"
                      style={{ width: 140 }}
                      placeholder="Label"
                      value={prize.label}
                      onChange={(e) => updatePrize(i, 'label', e.target.value)}
                    />
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                      <span style={{ color: 'var(--text-muted)' }}>₹</span>
                      <input
                        type="number"
                        className="form-input"
                        style={{ width: 120 }}
                        placeholder="Amount"
                        value={prize.amount}
                        onChange={(e) => updatePrize(i, 'amount', e.target.value)}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div style={{ display: 'flex', gap: 12, marginTop: 32 }}>
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? 'Creating...' : '🎰 Create Lottery'}
              </button>
              <button type="button" className="btn btn-outline" onClick={() => router.back()}>
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </>
  );
}
