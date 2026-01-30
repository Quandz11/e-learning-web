import { createSlice } from '@reduxjs/toolkit';
import type { PayloadAction } from '@reduxjs/toolkit';

export interface User {
  id: string;
  email: string;
  fullName: string;
  role: string;
  avatarUrl?: string;
  phone?: string;
}

export interface AuthState {
  user: User | null;
  accessToken: string | null;
  expiresAt: string | null;
  isLoading: boolean;
  error: string | null;
  isAuthenticated: boolean;
  requiresTwoFactor: boolean;
}

const initialState: AuthState = {
  user: null,
  accessToken: null,
  expiresAt: null,
  isLoading: false,
  error: null,
  isAuthenticated: false,
  requiresTwoFactor: false,
};

export const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    // Login actions
    loginStart: (state) => {
      state.isLoading = true;
      state.error = null;
    },
    loginSuccess: (state, action: PayloadAction<{ user: User | null; accessToken: string; expiresAt: string; requiresTwoFactor?: boolean }>) => {
      state.isLoading = false;
      state.accessToken = action.payload.accessToken;
      state.expiresAt = action.payload.expiresAt;
      state.error = null;

      if (action.payload.requiresTwoFactor) {
        state.requiresTwoFactor = true;
        state.isAuthenticated = false; // Not fully authenticated yet
        state.user = null; // User details might be partial or hidden
      } else {
        state.requiresTwoFactor = false;
        state.isAuthenticated = true;
        state.user = action.payload.user;
      }
    },
    loginFailure: (state, action: PayloadAction<string>) => {
      state.isLoading = false;
      state.error = action.payload;
      state.isAuthenticated = false;
    },

    // Logout
    logout: (state) => {
      state.user = null;
      state.accessToken = null;
      state.expiresAt = null;
      state.isAuthenticated = false;
      state.error = null;
    },

    // Set auth state (for persistence)
    setAuthState: (state, action: PayloadAction<Partial<AuthState>>) => {
      return { ...state, ...action.payload };
    },

    // Clear error
    clearError: (state) => {
      state.error = null;
    },

    // Update user action
    updateUser: (state, action: PayloadAction<Partial<User>>) => {
      if (state.user) {
        state.user = { ...state.user, ...action.payload };
      }
    },
  },
});

export const { loginStart, loginSuccess, loginFailure, logout, setAuthState, clearError, updateUser } = authSlice.actions;
export default authSlice.reducer;
