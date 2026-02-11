import { API_URL } from '../config/endpoints';
import { getTokens } from './storage';
import { MESSAGE_LIMIT } from '../config/constants';

async function authFetch(path, options = {}) {
  const { accessToken } = getTokens();
  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      ...options.headers,
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    throw new Error(`API error: ${response.status}`);
  }

  return response.json();
}

export function fetchMessages(channel, { limit = MESSAGE_LIMIT, before } = {}) {
  const params = new URLSearchParams({ channel, limit: String(limit) });
  if (before) params.set('before', before);
  return authFetch(`/messages?${params}`);
}
