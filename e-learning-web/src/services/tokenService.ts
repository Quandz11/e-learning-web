let accessToken: string | null = null;
let generation = 0;
const revoked = new Set<string>();

export function sessionId(token: string | null): string | null {
  try {
    if (!token) return null;
    return JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/'))).sid ?? null;
  } catch { return null; }
}

export const tokenService = {
  getAccessToken: () => accessToken,
  getGeneration: () => generation,
  invalidatePending: () => { generation++; },
  setAccessToken: (token: string | null) => {
    if (token === null) { tokenService.clearToken(); return; }
    const sid = sessionId(token);
    if (sid && revoked.has(sid)) throw new Error('Session revoked');
    if (sid !== sessionId(accessToken)) generation++;
    accessToken = token;
  },
  clearToken: (broadcast = true) => {
    const sid = sessionId(accessToken);
    if (sid) revoked.add(sid);
    generation++;
    accessToken = null;
    if (typeof window !== 'undefined') {
      localStorage.removeItem('auth');
      if (broadcast && sid) localStorage.setItem('session-logout', JSON.stringify({ sid, at: Date.now() }));
      window.dispatchEvent(new Event('session-ended'));
    }
  },
};
