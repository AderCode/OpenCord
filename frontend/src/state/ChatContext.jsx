import { createContext, useReducer } from 'react';
import { chatReducer, initialChatState } from './ChatReducer';

export const ChatContext = createContext(null);

export function ChatProvider({ children }) {
  const [state, dispatch] = useReducer(chatReducer, initialChatState);

  return (
    <ChatContext.Provider value={{ state, dispatch }}>
      {children}
    </ChatContext.Provider>
  );
}
