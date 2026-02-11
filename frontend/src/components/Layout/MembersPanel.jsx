import Avatar from '../Shared/Avatar';
import glass from '../../styles/glass.module.css';
import styles from './MembersPanel.module.css';

export default function MembersPanel({ channel }) {
  // In v1, members list is a placeholder since there's no members API.
  // We show the channel info and a note.
  return (
    <aside className={`${glass.panel} ${styles.panel}`}>
      <div className={styles.header}>
        <h3 className={styles.title}>Members</h3>
      </div>
      <div className={styles.section}>
        <span className={styles.sectionLabel}>Online</span>
        <div className={styles.placeholder}>
          <Avatar username={channel} size={28} />
          <span className={styles.note}>
            Member list will populate from WebSocket presence data
          </span>
        </div>
      </div>
    </aside>
  );
}
