import { useRef, useEffect, useState, useCallback } from 'react';
import useInfiniteScroll from '../../hooks/useInfiniteScroll';
import Message from './Message';
import DateDivider from './DateDivider';
import ScrollToBottom from './ScrollToBottom';
import LoadingSpinner from '../Shared/LoadingSpinner';
import styles from './MessageList.module.css';

function shouldShowDate(messages, index) {
  if (index === 0) return true;
  const prev = new Date(messages[index - 1].timestamp).toDateString();
  const curr = new Date(messages[index].timestamp).toDateString();
  return prev !== curr;
}

export default function MessageList({ messages, hasMore, onLoadMore, onEdit, onDelete, currentUsername }) {
  const listRef = useRef(null);
  const [isAtBottom, setIsAtBottom] = useState(true);
  const prevLengthRef = useRef(0);

  const sentinelRef = useInfiniteScroll(onLoadMore, hasMore);

  const handleScroll = useCallback(() => {
    const el = listRef.current;
    if (!el) return;
    const threshold = 100;
    setIsAtBottom(el.scrollHeight - el.scrollTop - el.clientHeight < threshold);
  }, []);

  // Auto-scroll on new messages if at bottom
  useEffect(() => {
    if (messages.length > prevLengthRef.current && isAtBottom) {
      const el = listRef.current;
      if (el) el.scrollTop = el.scrollHeight;
    }
    prevLengthRef.current = messages.length;
  }, [messages.length, isAtBottom]);

  const scrollToBottom = useCallback(() => {
    const el = listRef.current;
    if (el) {
      el.scrollTop = el.scrollHeight;
      setIsAtBottom(true);
    }
  }, []);

  return (
    <div className={styles.container}>
      <div
        ref={listRef}
        className={styles.list}
        onScroll={handleScroll}
      >
        {hasMore && (
          <div ref={sentinelRef} className={styles.sentinel}>
            <LoadingSpinner size={20} />
          </div>
        )}
        {messages.map((msg, i) => (
          <div key={msg.message_id || `${msg.timestamp}-${msg.username}`}>
            {shouldShowDate(messages, i) && (
              <DateDivider date={msg.timestamp} />
            )}
            <Message
              messageId={msg.message_id}
              username={msg.username}
              content={msg.content}
              timestamp={msg.timestamp}
              editedAt={msg.editedAt || msg.edited_at}
              isOwn={msg.username === currentUsername}
              onEdit={onEdit}
              onDelete={onDelete}
            />
          </div>
        ))}
        {messages.length === 0 && (
          <div className={styles.empty}>
            No messages yet. Start the conversation!
          </div>
        )}
      </div>
      {!isAtBottom && <ScrollToBottom onClick={scrollToBottom} />}
    </div>
  );
}
