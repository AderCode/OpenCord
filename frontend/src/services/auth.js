import { AUTH_URL, COGNITO_CLIENT_ID, REDIRECT_URI } from '../config/endpoints';
import { setTokens, getTokens, clearTokens } from './storage';

export function getLoginUrl() {
  const params = new URLSearchParams({
    client_id: COGNITO_CLIENT_ID,
    response_type: 'code',
    scope: 'openid email profile',
    redirect_uri: REDIRECT_URI,
  });
  return `${AUTH_URL}/login?${params}`;
}

export async function exchangeCode(code) {
  const response = await fetch(`${AUTH_URL}/oauth2/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: COGNITO_CLIENT_ID,
      code,
      redirect_uri: REDIRECT_URI,
    }),
  });

  if (!response.ok) {
    throw new Error('Token exchange failed');
  }

  const data = await response.json();
  const tokens = {
    idToken: data.id_token,
    accessToken: data.access_token,
    refreshToken: data.refresh_token,
  };
  setTokens(tokens);
  return tokens;
}

export async function refreshTokens() {
  const { refreshToken } = getTokens();
  if (!refreshToken) throw new Error('No refresh token');

  const response = await fetch(`${AUTH_URL}/oauth2/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      client_id: COGNITO_CLIENT_ID,
      refresh_token: refreshToken,
    }),
  });

  if (!response.ok) {
    throw new Error('Token refresh failed');
  }

  const data = await response.json();
  const tokens = {
    idToken: data.id_token,
    accessToken: data.access_token,
    refreshToken: refreshToken, // Cognito doesn't return a new refresh token
  };
  setTokens(tokens);
  return tokens;
}

export function decodeIdToken(idToken) {
  try {
    const payload = JSON.parse(atob(idToken.split('.')[1]));
    return {
      sub: payload.sub,
      email: payload.email,
      username: payload.email?.split('@')[0] || payload['cognito:username'] || 'user',
      exp: payload.exp,
    };
  } catch {
    return null;
  }
}

export function getLogoutUrl() {
  const params = new URLSearchParams({
    client_id: COGNITO_CLIENT_ID,
    logout_uri: REDIRECT_URI.replace('/callback', '/login'),
  });
  return `${AUTH_URL}/logout?${params}`;
}

export function logout() {
  clearTokens();
  window.location.href = getLogoutUrl();
}
