'use client';
import { useState, useEffect } from 'react';
import api from '@/lib/api';

export default function SettingsPage() {
  const [upiId, setUpiId] = useState('');
  const [qrCodeUrl, setQrCodeUrl] = useState('');
  const [appVersion, setAppVersion] = useState('1.0.0');
  const [appDownloadUrl, setAppDownloadUrl] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);

  function showToast(message, type) {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  }

  async function loadUPISettings() {
    setLoading(true);
    try {
      const res = await api.getUPISettings();
      if (res.success) {
        setUpiId(res.data.upiId || '');
        setQrCodeUrl(res.data.qrCodeUrl || '');
        setAppVersion(res.data.appVersion || '1.0.0');
        setAppDownloadUrl(res.data.appDownloadUrl || '');
      }
    } catch (err) {
      console.error('Load settings error:', err);
      showToast('Failed to load system settings', 'error');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    const timer = setTimeout(() => {
      loadUPISettings();
    }, 0);
    return () => clearTimeout(timer);
  }, []);

  const handleSave = async (e) => {
    e.preventDefault();
    if (!upiId.trim()) {
      showToast('UPI ID is required', 'error');
      return;
    }
    if (!appVersion.trim()) {
      showToast('App version is required', 'error');
      return;
    }

    setSaving(true);
    try {
      const res = await api.updateUPISettings({ 
        upiId, 
        qrCodeUrl, 
        appVersion: appVersion.trim(), 
        appDownloadUrl: appDownloadUrl.trim() 
      });
      if (res.success) {
        showToast('System settings saved successfully!', 'success');
      }
    } catch (err) {
      showToast(err.message || 'Failed to save settings', 'error');
    } finally {
      setSaving(false);
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

  return (
    <>
      <div className="page-header">
        <h2>System Settings</h2>
        <p>Manage system payment gateways, active UPI accounts, app version settings, and QR codes</p>
      </div>

      {loading ? (
        <div className="loading">
          <div className="loading-spinner"></div>Loading Settings...
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '24px', alignItems: 'start' }}>
          
          {/* UPI Settings Form */}
          <div className="card" style={{ padding: '24px' }}>
            <h3 style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>💳 UPI Payment Details</h3>
            <form onSubmit={handleSave}>
              <div className="form-group" style={{ marginBottom: '20px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Active UPI ID</label>
                <input
                  type="text"
                  className="form-control"
                  style={{
                    width: '100%',
                    padding: '12px',
                    background: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '8px',
                    color: '#fff',
                    fontSize: '15px'
                  }}
                  placeholder="e.g. merchant@upi or pay@upi"
                  value={upiId}
                  onChange={(e) => setUpiId(e.target.value)}
                  required
                />
              </div>

              <div className="form-group" style={{ marginBottom: '24px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Upload QR Code Image</label>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleImageUpload}
                  style={{
                    width: '100%',
                    padding: '12px',
                    background: 'rgba(255,255,255,0.02)',
                    border: '2px dashed rgba(255,255,255,0.15)',
                    borderRadius: '8px',
                    color: '#ccc',
                    cursor: 'pointer'
                  }}
                />
                <small style={{ color: 'var(--text-muted)', display: 'block', marginTop: '6px' }}>
                  Recommended: Clear square JPG or PNG format. File size must be under 1MB.
                </small>
              </div>

              <button
                type="submit"
                className="btn btn-primary"
                style={{ width: '100%', padding: '14px', fontSize: '15px', fontWeight: '600' }}
                disabled={saving}
              >
                {saving ? 'Saving changes...' : '💾 Save Payments'}
              </button>
            </form>
          </div>

          {/* App Update Settings Form */}
          <div className="card" style={{ padding: '24px' }}>
            <h3 style={{ marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>📱 App Update Controls</h3>
            <form onSubmit={handleSave}>
              <div className="form-group" style={{ marginBottom: '20px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>Latest App Version</label>
                <input
                  type="text"
                  className="form-control"
                  style={{
                    width: '100%',
                    padding: '12px',
                    background: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '8px',
                    color: '#fff',
                    fontSize: '15px'
                  }}
                  placeholder="e.g. 1.0.0"
                  value={appVersion}
                  onChange={(e) => setAppVersion(e.target.value)}
                  required
                />
                <small style={{ color: 'var(--text-muted)', display: 'block', marginTop: '6px' }}>
                  Note: Users with a client version different from this code will be prompted to update.
                </small>
              </div>

              <div className="form-group" style={{ marginBottom: '24px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: 500 }}>APK Download URL</label>
                <input
                  type="text"
                  className="form-control"
                  style={{
                    width: '100%',
                    padding: '12px',
                    background: 'rgba(255,255,255,0.05)',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '8px',
                    color: '#fff',
                    fontSize: '15px'
                  }}
                  placeholder="e.g. https://dream-lottery.onrender.com/api/app/download"
                  value={appDownloadUrl}
                  onChange={(e) => setAppDownloadUrl(e.target.value)}
                />
                <small style={{ color: 'var(--text-muted)', display: 'block', marginTop: '6px' }}>
                  Direct APK download link. Leave empty to use default server host.
                </small>
              </div>

              <button
                type="submit"
                className="btn btn-primary"
                style={{ width: '100%', padding: '14px', fontSize: '15px', fontWeight: '600' }}
                disabled={saving}
              >
                {saving ? 'Saving changes...' : '💾 Save Version Info'}
              </button>
            </form>
          </div>

          {/* QR Preview Card */}
          <div className="card" style={{ padding: '24px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', minHeight: '340px' }}>
            <h3 style={{ marginBottom: '16px', alignSelf: 'flex-start' }}>📸 Live Scan Preview</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '13px', marginBottom: '20px', alignSelf: 'flex-start' }}>
              This QR code and UPI ID will be rendered live inside the user&apos;s mobile deposit screen:
            </p>

            {qrCodeUrl ? (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '16px' }}>
                <div style={{ padding: '16px', background: '#fff', borderRadius: '16px', boxShadow: '0 8px 30px rgba(0,0,0,0.3)', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                  <img src={qrCodeUrl} alt="UPI QR Code" style={{ width: '180px', height: '180px', objectFit: 'contain' }} />
                </div>
                <div style={{ fontFamily: 'monospace', background: 'rgba(255,255,255,0.05)', padding: '6px 12px', borderRadius: '6px', fontSize: '14px', border: '1px solid rgba(255,255,255,0.1)' }}>
                  {upiId || 'No UPI ID'}
                </div>
              </div>
            ) : (
              <div style={{ width: '180px', height: '180px', borderRadius: '16px', border: '2px dashed rgba(255,255,255,0.1)', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', color: 'var(--text-muted)' }}>
                <span style={{ fontSize: '36px', marginBottom: '8px' }}>📸</span>
                <span style={{ fontSize: '12px' }}>No QR Uploaded</span>
              </div>
            )}
          </div>
        </div>
      )}

      {toast && <div className={`toast ${toast.type}`}>{toast.message}</div>}
    </>
  );
}
