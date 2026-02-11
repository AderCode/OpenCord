export const CHAT_ACTIONS = {
  SET_CHANNEL: 'SET_CHANNEL',
  ADD_MESSAGE: 'ADD_MESSAGE',
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
      // Dedup by timestamp + username
      const msg = action.payload;
      const isDup = state.messages.some(
        (m) => m.timestamp === msg.timestamp && m.username === msg.username
      );
      if (isDup) return state;
      return { ...state, messages: [...state.messages, msg] };
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
