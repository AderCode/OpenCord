import styles from './ChannelItem.module.css';

export default function ChannelItem({ name, isActive, onClick }) {
  return (
    <button
      className={`${styles.item} ${isActive ? styles.active : ''}`}
      onClick={onClick}
    >
      <span className={styles.hash}>#</span>
      <span className={styles.name}>{name}</span>
    </button>
  );
}
