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
    editMessage,
    deleteMessage,
    setWsStatus,
    loadMore,
  } = useChat();

  const handleWsMessage = useCallback(
    (data) => {
      switch (data.type) {
        case 'editMessage':
          editMessage(data.message_id, data.content, data.edited_at);
          break;
        case 'deleteMessage':
          deleteMessage(data.message_id);
          break;
        case 'newMessage':
        default:
          addMessage(data);
          break;
      }
    },
    [addMessage, editMessage, deleteMessage]
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
      const placeholderId = crypto.randomUUID();
      const msg = {
        action: 'sendMessage',
        channel: activeChannel,
        content,
      };
      send(msg);
      addMessage({
        message_id: placeholderId,
        channel: activeChannel,
        content,
        username: user?.username || 'anonymous',
        timestamp: new Date().toISOString(),
      });
    },
    [activeChannel, user, send, addMessage]
  );

  const handleEdit = useCallback(
    (messageId, content) => {
      send({
        action: 'editMessage',
        message_id: messageId,
        content,
      });
      editMessage(messageId, content, new Date().toISOString());
    },
    [send, editMessage]
  );

  const handleDelete = useCallback(
    (messageId) => {
      send({
        action: 'deleteMessage',
        message_id: messageId,
      });
      deleteMessage(messageId);
    },
    [send, deleteMessage]
  );

  const currentUsername = user?.username || 'anonymous';
  const currentUserRole = user?.role || 'member';

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
        onEdit={handleEdit}
        onDelete={handleDelete}
        currentUsername={currentUsername}
        currentUserRole={currentUserRole}
      />
      <TypingIndicator />
      <MessageInput onSend={handleSend} channel={activeChannel} />
    </div>
  );
}
