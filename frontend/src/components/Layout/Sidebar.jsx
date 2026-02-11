import useAuth from '../../hooks/useAuth';
import ChannelList from '../Channels/ChannelList';
import Avatar from '../Shared/Avatar';
import glass from '../../styles/glass.module.css';
import styles from './Sidebar.module.css';

export default function Sidebar({ activeChannel, onSelectChannel }) {
  const { user, logout } = useAuth();

  return (
    <aside className={`${glass.panel} ${styles.sidebar}`}>
      <div className={styles.brand}>
        <svg viewBox="0 0 32 32" className={styles.logo}>
          <defs>
            <linearGradient id="sidebarGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="#00d2ff" />
              <stop offset="100%" stopColor="#7b2ff7" />
            </linearGradient>
          </defs>
          <text x="16" y="23" fontFamily="Inter,sans-serif" fontSize="20" fontWeight="bold" fill="url(#sidebarGrad)" textAnchor="middle">O</text>
        </svg>
        <span className={styles.brandName}>OpenCord</span>
      </div>
      <ChannelList
        activeChannel={activeChannel}
        onSelectChannel={onSelectChannel}
      />
      <div className={styles.userCard}>
        <Avatar username={user?.username || 'user'} size={32} />
        <div className={styles.userInfo}>
          <span className={styles.username}>{user?.username}</span>
          <span className={styles.email}>{user?.email}</span>
        </div>
        <button className={styles.logoutBtn} onClick={logout} aria-label="Logout">
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path d="M6 2H3a1 1 0 00-1 1v10a1 1 0 001 1h3M11 11l3-3-3-3M14 8H6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </div>
    </aside>
  );
}
