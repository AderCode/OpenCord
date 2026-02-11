import styles from './DateDivider.module.css';

const formatter = new Intl.DateTimeFormat(undefined, {
  year: 'numeric',
  month: 'long',
  day: 'numeric',
});

function getLabel(dateStr) {
  const date = new Date(dateStr);
  const today = new Date();
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);

  if (date.toDateString() === today.toDateString()) return 'Today';
  if (date.toDateString() === yesterday.toDateString()) return 'Yesterday';
  return formatter.format(date);
}

export default function DateDivider({ date }) {
  return (
    <div className={styles.divider}>
      <span className={styles.line} />
      <span className={styles.label}>{getLabel(date)}</span>
      <span className={styles.line} />
    </div>
  );
}
