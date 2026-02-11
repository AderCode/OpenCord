import styles from './ConnectionStatus.module.css';

const STATUS_LABELS = {
  connected: 'Connected',
  connecting: 'Connecting...',
  disconnected: 'Disconnected',
};

export default function ConnectionStatus({ status }) {
  return (
    <div className={styles.container}>
      <span className={`${styles.dot} ${styles[status]}`} />
      <span className={styles.label}>{STATUS_LABELS[status]}</span>
    </div>
  );
}
