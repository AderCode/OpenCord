const KEYS = {
  ID_TOKEN: 'opencord_id_token',
  ACCESS_TOKEN: 'opencord_access_token',
  REFRESH_TOKEN: 'opencord_refresh_token',
  LAST_CHANNEL: 'opencord_last_channel',
};

export function getTokens() {
  return {
    idToken: localStorage.getItem(KEYS.ID_TOKEN),
    accessToken: localStorage.getItem(KEYS.ACCESS_TOKEN),
    refreshToken: localStorage.getItem(KEYS.REFRESH_TOKEN),
  };
}

export function setTokens({ idToken, accessToken, refreshToken }) {
  if (idToken) localStorage.setItem(KEYS.ID_TOKEN, idToken);
  if (accessToken) localStorage.setItem(KEYS.ACCESS_TOKEN, accessToken);
  if (refreshToken) localStorage.setItem(KEYS.REFRESH_TOKEN, refreshToken);
}

export function clearTokens() {
  localStorage.removeItem(KEYS.ID_TOKEN);
  localStorage.removeItem(KEYS.ACCESS_TOKEN);
  localStorage.removeItem(KEYS.REFRESH_TOKEN);
}

export function getLastChannel() {
  return localStorage.getItem(KEYS.LAST_CHANNEL);
}

export function setLastChannel(channel) {
  localStorage.setItem(KEYS.LAST_CHANNEL, channel);
}
