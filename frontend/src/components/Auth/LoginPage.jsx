import { getLoginUrl } from '../../services/auth';
import glass from '../../styles/glass.module.css';
import styles from './LoginPage.module.css';

export default function LoginPage() {
  return (
    <div className={styles.page}>
      <div className={`${glass.panel} ${styles.card}`}>
        <div className={styles.logo}>
          <svg viewBox="0 0 64 64" className={styles.logoIcon}>
            <defs>
              <linearGradient id="loginGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#00d2ff" />
                <stop offset="100%" stopColor="#7b2ff7" />
              </linearGradient>
            </defs>
            <rect width="64" height="64" rx="16" fill="rgba(255,255,255,0.05)" />
            <text x="32" y="44" fontFamily="Inter,sans-serif" fontSize="32" fontWeight="bold" fill="url(#loginGrad)" textAnchor="middle">O</text>
          </svg>
          <h1 className={styles.title}>OpenCord</h1>
        </div>
        <p className={styles.subtitle}>Open-source community platform</p>
        <a href={getLoginUrl()} className={styles.button}>
          Sign In
        </a>
      </div>
    </div>
  );
}
