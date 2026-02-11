import Avatar from '../Shared/Avatar';
import styles from './Message.module.css';

const timeFormatter = new Intl.DateTimeFormat(undefined, {
  hour: 'numeric',
  minute: '2-digit',
});

export default function Message({ username, content, timestamp }) {
  return (
    <div className={styles.message}>
      <Avatar username={username} size={36} />
      <div className={styles.body}>
        <div className={styles.header}>
          <span className={styles.username}>{username}</span>
          <span className={styles.time}>
            {timeFormatter.format(new Date(timestamp))}
          </span>
        </div>
        <p className={styles.content}>{content}</p>
      </div>
    </div>
  );
}
