import { useEffect, useRef, useCallback } from 'react';
import WebSocketManager from '../services/websocket';
import { showNotification, requestPermission } from '../services/notifications';

export default function useWebSocket({ channel, onMessage, onStatusChange, getToken }) {
  const wsRef = useRef(null);
  const getTokenRef = useRef(getToken);
  getTokenRef.current = getToken;

  useEffect(() => {
    requestPermission();
  }, []);

  useEffect(() => {
    if (!channel) return;

    const ws = new WebSocketManager({
      channel,
      onMessage: (data) => {
        onMessage(data);
        showNotification(`#${channel}`, `${data.username}: ${data.content}`);
      },
      onStatusChange,
      getToken: () => getTokenRef.current?.(),
    });

    ws.connect();
    wsRef.current = ws;

    return () => {
      ws.close();
      wsRef.current = null;
    };
  }, [channel, onMessage, onStatusChange]);

  const send = useCallback(
    (data) => {
      wsRef.current?.send(data);
    },
    []
  );

  return { send };
}
