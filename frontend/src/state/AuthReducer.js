export const AUTH_ACTIONS = {
  LOGIN_SUCCESS: 'LOGIN_SUCCESS',
  LOGOUT: 'LOGOUT',
  TOKEN_REFRESH: 'TOKEN_REFRESH',
  SET_USER: 'SET_USER',
  SET_LOADING: 'SET_LOADING',
};

export const initialAuthState = {
  isAuthenticated: false,
  isLoading: true,
  user: null,
  tokens: null,
};

export function authReducer(state, action) {
  switch (action.type) {
    case AUTH_ACTIONS.LOGIN_SUCCESS:
      return {
        ...state,
        isAuthenticated: true,
        isLoading: false,
        user: action.payload.user,
        tokens: action.payload.tokens,
      };
    case AUTH_ACTIONS.LOGOUT:
      return { ...initialAuthState, isLoading: false };
    case AUTH_ACTIONS.TOKEN_REFRESH:
      return {
        ...state,
        tokens: action.payload.tokens,
      };
    case AUTH_ACTIONS.SET_USER:
      return { ...state, user: action.payload.user };
    case AUTH_ACTIONS.SET_LOADING:
      return { ...state, isLoading: action.payload };
    default:
      return state;
  }
}
