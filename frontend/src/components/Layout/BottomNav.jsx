import styles from './BottomNav.module.css';

const TABS = [
  { id: 'channels', label: 'Channels', icon: 'M3 5h4v14H3V5zm10 0h4v14h-4V5z' },
  { id: 'chat', label: 'Chat', icon: 'M2 4h16v10H5l-3 3V4z' },
  { id: 'members', label: 'Members', icon: 'M12 4a4 4 0 110 8 4 4 0 010-8zM4 18c0-2.7 5.3-4 8-4s8 1.3 8 4v1H4v-1z' },
];

export default function BottomNav({ activeTab, onTabChange }) {
  return (
    <nav className={styles.nav}>
      {TABS.map((tab) => (
        <button
          key={tab.id}
          className={`${styles.tab} ${activeTab === tab.id ? styles.active : ''}`}
          onClick={() => onTabChange(tab.id)}
        >
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none" className={styles.icon}>
            <path d={tab.icon} fill="currentColor" />
          </svg>
          <span className={styles.label}>{tab.label}</span>
        </button>
      ))}
    </nav>
  );
}
