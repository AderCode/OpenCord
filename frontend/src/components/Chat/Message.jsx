import { useState, useCallback } from 'react';
import Avatar from '../Shared/Avatar';
import styles from './Message.module.css';

const timeFormatter = new Intl.DateTimeFormat(undefined, {
  hour: 'numeric',
  minute: '2-digit',
});

export default function Message({ messageId, username, content, timestamp, editedAt, isOwn, onEdit, onDelete }) {
  const [editing, setEditing] = useState(false);
  const [editContent, setEditContent] = useState(content);

  const handleEditStart = useCallback(() => {
    setEditContent(content);
    setEditing(true);
  }, [content]);

  const handleEditSave = useCallback(() => {
    const trimmed = editContent.trim();
    if (trimmed && trimmed !== content) {
      onEdit(messageId, trimmed);
    }
    setEditing(false);
  }, [editContent, content, messageId, onEdit]);

  const handleEditCancel = useCallback(() => {
    setEditing(false);
    setEditContent(content);
  }, [content]);

  const handleEditKeyDown = useCallback(
    (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleEditSave();
      } else if (e.key === 'Escape') {
        handleEditCancel();
      }
    },
    [handleEditSave, handleEditCancel]
  );

  const handleDelete = useCallback(() => {
    onDelete(messageId);
  }, [messageId, onDelete]);

  return (
    <div className={styles.message}>
      <Avatar username={username} size={36} />
      <div className={styles.body}>
        <div className={styles.header}>
          <span className={styles.username}>{username}</span>
          <span className={styles.time}>
            {timeFormatter.format(new Date(timestamp))}
          </span>
          {editedAt && <span className={styles.editedLabel}>(edited)</span>}
        </div>
        {editing ? (
          <div className={styles.editing}>
            <textarea
              className={styles.editTextarea}
              value={editContent}
              onChange={(e) => setEditContent(e.target.value)}
              onKeyDown={handleEditKeyDown}
              autoFocus
            />
            <div className={styles.editButtons}>
              <button className={styles.saveBtn} onClick={handleEditSave}>
                Save
              </button>
              <button className={styles.cancelBtn} onClick={handleEditCancel}>
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <p className={styles.content}>{content}</p>
        )}
      </div>
      {isOwn && !editing && (
        <div className={styles.actions}>
          <button
            className={styles.actionBtn}
            onClick={handleEditStart}
            title="Edit"
            aria-label="Edit message"
          >
            &#9998;
          </button>
          <button
            className={styles.actionBtn}
            onClick={handleDelete}
            title="Delete"
            aria-label="Delete message"
          >
            &#128465;
          </button>
        </div>
      )}
    </div>
  );
}
