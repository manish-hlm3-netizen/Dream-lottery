'use client';
import { useState, useEffect, createContext, useContext } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Sidebar from './components/Sidebar';
import api from '@/lib/api';
import './globals.css';

const AuthContext = createContext(null);

export function useAuth() {
  return useContext(AuthContext);
}

function AuthenticatedLayout({ children }) {
  const router = useRouter();
  const [stats, setStats] = useState({});
  const [user, setUser] = useState(null);

  useEffect(() => {
    loadData();
    // Refresh stats every 30 seconds
    const interval = setInterval(loadData, 30000);
    return () => clearInterval(interval);
  }, []);

  const loadData = async () => {
    try {
      const [dashRes, meRes] = await Promise.all([
        api.getDashboard(),
        api.getMe()
      ]);
      if (dashRes.success) setStats(dashRes.data.stats);
      if (meRes.success) setUser(meRes.data);
    } catch (err) {
      console.error('Error loading data:', err);
    }
  };

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
