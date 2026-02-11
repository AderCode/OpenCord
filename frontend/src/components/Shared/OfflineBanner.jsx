import useOnlineStatus from '../../hooks/useOnlineStatus';
import styles from './OfflineBanner.module.css';

export default function OfflineBanner() {
  const isOnline = useOnlineStatus();

  if (isOnline) return null;

  return (
    <div className={styles.banner}>
      You are offline — messages may not send or load
    </div>
  );
}
