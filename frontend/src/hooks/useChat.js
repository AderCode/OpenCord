import { useContext, useCallback } from 'react';
import { ChatContext } from '../state/ChatContext';
import { CHAT_ACTIONS } from '../state/ChatReducer';
import { fetchMessages } from '../services/api';
import { setLastChannel } from '../services/storage';
import { MESSAGE_LIMIT } from '../config/constants';

export default function useChat() {
  const { state, dispatch } = useContext(ChatContext);
  if (!dispatch) throw new Error('useChat must be used within ChatProvider');

  const setChannel = useCallback(
    (channel) => {
      setLastChannel(channel);
      dispatch({ type: CHAT_ACTIONS.SET_CHANNEL, payload: channel });
    },
    [dispatch]
  );

  const loadMessages = useCallback(
    async (channel) => {
      try {
        const messages = await fetchMessages(channel);
        dispatch({ type: CHAT_ACTIONS.SET_MESSAGES, payload: messages });
        if (messages.length < MESSAGE_LIMIT) {
          dispatch({ type: CHAT_ACTIONS.SET_HAS_MORE, payload: false });
        }
      } catch (err) {
        console.error('Failed to load messages:', err);
      }
    },
    [dispatch]
  );

  const loadMore = useCallback(async () => {
    if (!state.hasMore || state.messages.length === 0) return;
    const oldest = state.messages[0]?.timestamp;
    try {
      const older = await fetchMessages(state.activeChannel, { before: oldest });
      if (older.length === 0) {
        dispatch({ type: CHAT_ACTIONS.SET_HAS_MORE, payload: false });
        return;
      }
      dispatch({ type: CHAT_ACTIONS.PREPEND_MESSAGES, payload: older });
      if (older.length < MESSAGE_LIMIT) {
        dispatch({ type: CHAT_ACTIONS.SET_HAS_MORE, payload: false });
      }
    } catch (err) {
      console.error('Failed to load more messages:', err);
    }
  }, [state.hasMore, state.messages, state.activeChannel, dispatch]);

  const addMessage = useCallback(
    (message) => {
      dispatch({ type: CHAT_ACTIONS.ADD_MESSAGE, payload: message });
    },
    [dispatch]
  );

  const editMessage = useCallback(
    (message_id, content, edited_at) => {
      dispatch({
        type: CHAT_ACTIONS.EDIT_MESSAGE,
        payload: { message_id, content, edited_at },
      });
    },
    [dispatch]
  );

  const deleteMessage = useCallback(
    (message_id) => {
      dispatch({
        type: CHAT_ACTIONS.DELETE_MESSAGE,
        payload: { message_id },
      });
    },
    [dispatch]
  );

  const setWsStatus = useCallback(
    (status) => {
      dispatch({ type: CHAT_ACTIONS.SET_WS_STATUS, payload: status });
    },
    [dispatch]
  );

  return {
    ...state,
    setChannel,
    loadMessages,
    loadMore,
    addMessage,
    editMessage,
    deleteMessage,
    setWsStatus,
  };
}
