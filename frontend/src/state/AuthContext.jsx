import { createContext, useReducer, useEffect, useCallback, useRef } from 'react';
import { authReducer, initialAuthState, AUTH_ACTIONS } from './AuthReducer';
import { getTokens } from '../services/storage';
import { decodeIdToken, refreshTokens, logout } from '../services/auth';
import { TOKEN_REFRESH_BUFFER_MS } from '../config/constants';

export const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [state, dispatch] = useReducer(authReducer, initialAuthState);
  const refreshTimer = useRef(null);

  const scheduleRefresh = useCallback((expiresAt) => {
    clearTimeout(refreshTimer.current);
    const delay = expiresAt * 1000 - Date.now() - TOKEN_REFRESH_BUFFER_MS;
    if (delay <= 0) return;

    refreshTimer.current = setTimeout(async () => {
      try {
        const tokens = await refreshTokens();
        const user = decodeIdToken(tokens.idToken);
        dispatch({ type: AUTH_ACTIONS.TOKEN_REFRESH, payload: { tokens } });
        if (user?.exp) scheduleRefresh(user.exp);
      } catch {
        logout();
        dispatch({ type: AUTH_ACTIONS.LOGOUT });
      }
    }, delay);
  }, []);

  // Check for existing tokens on mount
  useEffect(() => {
    const tokens = getTokens();
    if (tokens.idToken) {
      const user = decodeIdToken(tokens.idToken);
      if (user && user.exp * 1000 > Date.now()) {
        dispatch({
          type: AUTH_ACTIONS.LOGIN_SUCCESS,
          payload: { user, tokens },
        });
        scheduleRefresh(user.exp);
      } else if (tokens.refreshToken) {
        // Token expired, try refresh
        refreshTokens()
          .then((newTokens) => {
            const newUser = decodeIdToken(newTokens.idToken);
            dispatch({
              type: AUTH_ACTIONS.LOGIN_SUCCESS,
              payload: { user: newUser, tokens: newTokens },
            });
            if (newUser?.exp) scheduleRefresh(newUser.exp);
          })
          .catch(() => {
            dispatch({ type: AUTH_ACTIONS.SET_LOADING, payload: false });
          });
        return;
      } else {
        dispatch({ type: AUTH_ACTIONS.SET_LOADING, payload: false });
      }
    } else {
      dispatch({ type: AUTH_ACTIONS.SET_LOADING, payload: false });
    }

    return () => clearTimeout(refreshTimer.current);
  }, [scheduleRefresh]);

  const handleLoginSuccess = useCallback(
    (tokens) => {
      const user = decodeIdToken(tokens.idToken);
      dispatch({
        type: AUTH_ACTIONS.LOGIN_SUCCESS,
        payload: { user, tokens },
      });
      if (user?.exp) scheduleRefresh(user.exp);
    },
    [scheduleRefresh]
  );

  const handleLogout = useCallback(() => {
    clearTimeout(refreshTimer.current);
    logout();
    dispatch({ type: AUTH_ACTIONS.LOGOUT });
  }, []);

  return (
    <AuthContext.Provider
      value={{
        ...state,
        loginSuccess: handleLoginSuccess,
        logout: handleLogout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
