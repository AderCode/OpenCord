import { WS_URL } from '../config/endpoints';
import { WS_RECONNECT_BASE, WS_RECONNECT_MAX } from '../config/constants';

export default class WebSocketManager {
  constructor({ channel, onMessage, onStatusChange, getToken }) {
    this.channel = channel;
    this.onMessage = onMessage;
    this.onStatusChange = onStatusChange;
    this.getToken = getToken;
    this.ws = null;
    this.reconnectDelay = WS_RECONNECT_BASE;
    this.reconnectTimer = null;
    this.intentionallyClosed = false;
  }

  connect() {
    this.intentionallyClosed = false;
    this.onStatusChange('connecting');

    const token = this.getToken?.();
    let url = `${WS_URL}?channel=${encodeURIComponent(this.channel)}`;
    if (token) {
      url += `&token=${encodeURIComponent(token)}`;
    }

    this.ws = new WebSocket(url);

    this.ws.onopen = () => {
      this.reconnectDelay = WS_RECONNECT_BASE;
      this.onStatusChange('connected');
    };

    this.ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        this.onMessage(data);
      } catch {
        // ignore malformed messages
      }
    };

    this.ws.onclose = () => {
      this.onStatusChange('disconnected');
      if (!this.intentionallyClosed) {
        this.scheduleReconnect();
      }
    };

    this.ws.onerror = () => {
      // onclose will fire after onerror
    };
  }

  scheduleReconnect() {
    this.reconnectTimer = setTimeout(() => {
      this.reconnectDelay = Math.min(this.reconnectDelay * 2, WS_RECONNECT_MAX);
      this.connect();
    }, this.reconnectDelay);
  }

  send(data) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data));
    }
  }

  close() {
    this.intentionallyClosed = true;
    clearTimeout(this.reconnectTimer);
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}
