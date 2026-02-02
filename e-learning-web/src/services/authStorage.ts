export interface PersistedAuth {
  user: any; // Use App User type if needed
  accessToken: string;
  expiresAt: string;
}

const KEY = 'auth';

export function saveAuth(auth: PersistedAuth) {
  localStorage.setItem(KEY, JSON.stringify(auth));
}

export function clearAuth() {
  localStorage.removeItem(KEY);
}

export function loadAuth(): PersistedAuth | null {
  const raw = localStorage.getItem(KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as PersistedAuth;
  } catch {
    return null;
  }
}
