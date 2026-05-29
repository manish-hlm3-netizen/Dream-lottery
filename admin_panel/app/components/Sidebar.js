'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

export default function Sidebar({ stats, onLogout }) {
  const pathname = usePathname();

  const navItems = [
    { href: '/', icon: '📊', label: 'Dashboard' },
    { href: '/deposits', icon: '💰', label: 'Deposits', badge: stats?.pendingDeposits },
    { href: '/withdrawals', icon: '💸', label: 'Withdrawals', badge: stats?.pendingWithdrawals },
    { href: '/lotteries', icon: '🎰', label: 'Lotteries' },
    { href: '/users', icon: '👥', label: 'Users' },
    { href: '/support', icon: '💬', label: 'Support Chat', badge: stats?.unreadChats },
    { href: '/announcements', icon: '📢', label: 'Announcements' },
    { href: '/settings', icon: '⚙️', label: 'Settings' },
  ];

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-icon">🎲</div>
        <div>
          <h1>LottoAdmin</h1>
          <span>Control Panel</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`nav-item ${pathname === item.href ? 'active' : ''}`}
          >
            <span className="nav-icon">{item.icon}</span>
            {item.label}
            {item.badge > 0 && <span className="badge">{item.badge}</span>}
          </Link>
        ))}
      </nav>

      <div className="sidebar-footer">
        <button className="logout-btn" onClick={onLogout}>
          <span>🚪</span>
          Logout
        </button>
      </div>
    </aside>
  );
}
