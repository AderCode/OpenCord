import { useCallback } from 'react';
import useChat from '../../hooks/useChat';
import useAuth from '../../hooks/useAuth';
import useWebSocket from '../../hooks/useWebSocket';
import MessageList from './MessageList';
import MessageInput from './MessageInput';
import TypingIndicator from './TypingIndicator';
import ConnectionStatus from '../Shared/ConnectionStatus';
import styles from './ChatArea.module.css';

export default function ChatArea() {
  const { user, tokens } = useAuth();
  const {
    activeChannel,
    messages,
    wsStatus,
    hasMore,
    addMessage,
    setWsStatus,
    loadMore,
  } = useChat();

  const handleWsMessage = useCallback(
    (data) => {
      addMessage(data);
    },
    [addMessage]
  );

  const handleStatusChange = useCallback(
    (status) => {
      setWsStatus(status);
    },
    [setWsStatus]
  );

  const getToken = useCallback(() => tokens?.idToken, [tokens]);

  const { send } = useWebSocket({
    channel: activeChannel,
    onMessage: handleWsMessage,
    onStatusChange: handleStatusChange,
    getToken,
  });

  const handleSend = useCallback(
    (content) => {
      const msg = {
        action: 'sendMessage',
        channel: activeChannel,
        content,
      };
      send(msg);
      // Optimistic add — use local username for immediate display
      addMessage({
        channel: activeChannel,
        content,
        username: user?.username || 'anonymous',
        timestamp: new Date().toISOString(),
      });
    },
    [activeChannel, user, send, addMessage]
  );

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <h2 className={styles.channelName}># {activeChannel}</h2>
        <ConnectionStatus status={wsStatus} />
      </div>
      <MessageList
        messages={messages}
        hasMore={hasMore}
        onLoadMore={loadMore}
      />
      <TypingIndicator />
      <MessageInput onSend={handleSend} channel={activeChannel} />
    </div>
  );
}
