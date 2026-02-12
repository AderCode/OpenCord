export const CHAT_ACTIONS = {
  SET_CHANNEL: 'SET_CHANNEL',
  ADD_MESSAGE: 'ADD_MESSAGE',
  EDIT_MESSAGE: 'EDIT_MESSAGE',
  DELETE_MESSAGE: 'DELETE_MESSAGE',
  PREPEND_MESSAGES: 'PREPEND_MESSAGES',
  SET_MESSAGES: 'SET_MESSAGES',
  SET_WS_STATUS: 'SET_WS_STATUS',
  SET_HAS_MORE: 'SET_HAS_MORE',
};

export const initialChatState = {
  activeChannel: 'general',
  messages: [],
  wsStatus: 'disconnected', // 'connected' | 'connecting' | 'disconnected'
  hasMore: true,
};

export function chatReducer(state, action) {
  switch (action.type) {
    case CHAT_ACTIONS.SET_CHANNEL:
      return {
        ...state,
        activeChannel: action.payload,
        messages: [],
        hasMore: true,
      };
    case CHAT_ACTIONS.ADD_MESSAGE: {
      const msg = action.payload;
      const isDup = state.messages.some((m) =>
        msg.message_id
          ? m.message_id === msg.message_id
          : m.timestamp === msg.timestamp && m.username === msg.username
      );
      if (isDup) return state;
      return { ...state, messages: [...state.messages, msg] };
    }
    case CHAT_ACTIONS.EDIT_MESSAGE: {
      const { message_id, content, edited_at } = action.payload;
      return {
        ...state,
        messages: state.messages.map((m) =>
          m.message_id === message_id ? { ...m, content, editedAt: edited_at } : m
        ),
      };
    }
    case CHAT_ACTIONS.DELETE_MESSAGE: {
      const { message_id } = action.payload;
      return {
        ...state,
        messages: state.messages.filter((m) => m.message_id !== message_id),
      };
    }
    case CHAT_ACTIONS.PREPEND_MESSAGES:
      return {
        ...state,
        messages: [...action.payload, ...state.messages],
      };
    case CHAT_ACTIONS.SET_MESSAGES:
      return { ...state, messages: action.payload };
    case CHAT_ACTIONS.SET_WS_STATUS:
      return { ...state, wsStatus: action.payload };
    case CHAT_ACTIONS.SET_HAS_MORE:
      return { ...state, hasMore: action.payload };
    default:
      return state;
  }
}
