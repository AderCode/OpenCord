import styles from './Avatar.module.css';

const COLORS = [
  '#00d2ff', '#7b2ff7', '#22c55e', '#f59e0b',
  '#ef4444', '#ec4899', '#8b5cf6', '#06b6d4',
];

function getColor(name) {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return COLORS[Math.abs(hash) % COLORS.length];
}

function getInitials(name) {
  return name.slice(0, 2).toUpperCase();
}

export default function Avatar({ username, size = 36 }) {
  return (
    <div
      className={styles.avatar}
      style={{
        width: size,
        height: size,
        fontSize: size * 0.4,
        backgroundColor: getColor(username),
      }}
    >
      {getInitials(username)}
    </div>
  );
}
