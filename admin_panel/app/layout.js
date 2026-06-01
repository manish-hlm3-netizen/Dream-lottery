'use client';
import { useState, useEffect, createContext, useContext, useRef } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Sidebar from './components/Sidebar';
import api from '@/lib/api';
import './globals.css';

const AuthContext = createContext(null);

export function useAuth() {
  return useContext(AuthContext);
}

// Web Audio API custom synthesizer to play premium clean double-beep notification sound
const playNotificationSound = () => {
  try {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const playBeep = (time, freq) => {
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, time);
      
      gain.gain.setValueAtTime(0, time);
      gain.gain.linearRampToValueAtTime(0.2, time + 0.05);
      gain.gain.exponentialRampToValueAtTime(0.001, time + 0.25);
      
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      
      osc.start(time);
      osc.stop(time + 0.25);
    };

    const now = audioCtx.currentTime;
    playBeep(now, 587.33); // D5
    playBeep(now + 0.08, 880); // A5
  } catch (err) {
    console.error('Failed to play notification sound:', err);
  }
};

// HTML5 Browser Push Notification Helper
const showNotification = (title, body) => {
  if (typeof window !== 'undefined' && 'Notification' in window) {
    if (Notification.permission === 'granted') {
      new Notification(title, {
        body,
        icon: '/favicon.ico'
      });
      playNotificationSound();
    } else if (Notification.permission !== 'denied') {
      Notification.requestPermission().then((permission) => {
        if (permission === 'granted') {
          new Notification(title, {
            body,
            icon: '/favicon.ico'
          });
          playNotificationSound();
        }
      });
    }
  }
};

function AuthenticatedLayout({ children }) {
  const router = useRouter();
  const [stats, setStats] = useState({});
  const [user, setUser] = useState(null);
  
  const prevDeposits = useRef(0);
  const prevWithdrawals = useRef(0);
  const isFirstLoad = useRef(true);

  async function loadData() {
    try {
      const [dashRes, meRes] = await Promise.all([
        api.getDashboard(),
        api.getMe()
      ]);
      
      if (dashRes.success) {
        const newStats = dashRes.data.stats;
        setStats(newStats);
        
        // Notify if new requests received since first load
        if (!isFirstLoad.current) {
          if (newStats.pendingDeposits > prevDeposits.current) {
            showNotification(
              '💰 New Deposit Request Received!',
              `There is a new deposit request waiting. Total pending: ${newStats.pendingDeposits}`
            );
          }
          if (newStats.pendingWithdrawals > prevWithdrawals.current) {
            showNotification(
              '💸 New Withdrawal Request!',
              `There is a new withdrawal request waiting. Total pending: ${newStats.pendingWithdrawals}`
            );
          }
        } else {
          isFirstLoad.current = false;
        }
        
        prevDeposits.current = newStats.pendingDeposits || 0;
        prevWithdrawals.current = newStats.pendingWithdrawals || 0;
      }
      
      if (meRes.success) setUser(meRes.data);
    } catch (err) {
      console.error('Error loading data:', err);
    }
  }

  useEffect(() => {
    // Request permission immediately on mount if supported
    if (typeof window !== 'undefined' && 'Notification' in window) {
      if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
        Notification.requestPermission();
      }
    }

    const timer = setTimeout(() => {
      loadData();
    }, 0);
    // Refresh stats every 10 seconds for real-time responsiveness
    const interval = setInterval(loadData, 10000);
    return () => {
      clearTimeout(timer);
      clearInterval(interval);
    };
  }, []);

  const handleLogout = () => {
    api.clearToken();
    router.push('/login');
  };

  return (
    <AuthContext.Provider value={{ user, stats, refreshStats: loadData }}>
      <div className="app-layout">
        <Sidebar stats={stats} onLogout={handleLogout} />
        <main className="main-content">
          {children}
        </main>
      </div>
    </AuthContext.Provider>
  );
}

export default function RootLayout({ children }) {
  const pathname = usePathname();
  const isLoginPage = pathname === '/login';

  return (
    <html lang="en">
      <head>
        <title>LottoAdmin - Lottery Management Dashboard</title>
        <meta name="description" content="Admin dashboard for managing lottery operations, user deposits, withdrawals, and draws." />
      </head>
      <body>
        {isLoginPage ? children : <AuthenticatedLayout>{children}</AuthenticatedLayout>}
      </body>
    </html>
  );
}
