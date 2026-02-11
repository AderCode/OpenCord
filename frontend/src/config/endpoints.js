const BASE_DOMAIN = import.meta.env.VITE_BASE_DOMAIN;

export const API_URL = `https://api.${BASE_DOMAIN}`;
export const WS_URL = `wss://ws.${BASE_DOMAIN}`;
export const AUTH_URL = `https://auth.${BASE_DOMAIN}`;
export const CDN_URL = `https://cdn.${BASE_DOMAIN}`;
export const COGNITO_CLIENT_ID = import.meta.env.VITE_COGNITO_CLIENT_ID;
export const REDIRECT_URI = `${CDN_URL}/callback`;
