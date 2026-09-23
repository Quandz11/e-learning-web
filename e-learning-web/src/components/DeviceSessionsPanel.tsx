import { useCallback, useEffect, useRef, useState } from 'react';
import { sessionApi, type ActiveSession } from '../services/sessionApi';
import { authApi } from '../services/authApi';

export default function DeviceSessionsPanel({ userId }: { userId?: string }) {
  const [sessions, setSessions] = useState<ActiveSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const version = useRef(0);
  const load = useCallback(async () => {
    const request = ++version.current;
    setLoading(true); setError('');
    try {
      const rows = userId ? await sessionApi.getUserSessions(userId) : await sessionApi.getActiveSessions();
      if (version.current === request) setSessions(rows);
    } catch { if (version.current === request) setError('Không thể tải danh sách phiên. Vui lòng thử lại.'); }
    finally { if (version.current === request) setLoading(false); }
  }, [userId]);
  useEffect(() => { void load(); return () => { version.current++; }; }, [load]);

  const revoke = async (session?: ActiveSession) => {
    if (busy) return;
    const message = session ? `Đăng xuất ${session.deviceName}?` : userId
      ? 'Đăng xuất tất cả thiết bị của người dùng này?' : 'Đăng xuất tất cả thiết bị khác?';
    if (!window.confirm(message)) return;
    setBusy(true); setError('');
    try {
      if (userId) await sessionApi.revokeUserSessions(userId, session?.sessionId);
      else if (session?.isCurrentSession) { await authApi.logout(); return; }
      else if (session) await sessionApi.revokeSession(session.sessionId);
      else await sessionApi.revokeAllSessions();
      await load();
    } catch { setError('Không thể thu hồi phiên. Vui lòng thử lại.'); }
    finally { setBusy(false); }
  };

  return <section className="my-6 rounded-xl border border-slate-200 bg-white p-5 dark:border-slate-700 dark:bg-slate-800">
    <h2 className="text-lg font-semibold">{userId ? 'Phiên đăng nhập của người dùng' : 'Thiết bị đăng nhập'}</h2>
    {error && <p role="alert" className="my-3 text-red-600">{error}</p>}
    {loading ? <p role="status">Đang tải…</p> : <>
      {!sessions.length && <p className="my-4">Không có phiên đăng nhập còn hiệu lực.</p>}
      <ul className="divide-y divide-slate-200 dark:divide-slate-700">
        {sessions.map(session => <li key={session.sessionId} className="flex flex-wrap items-center justify-between gap-3 py-4">
          <div>
            <p className="font-medium">{session.deviceName} {session.isCurrentSession && '• Thiết bị này'}</p>
            <p className="text-sm">{session.platform} • {session.browser} • IP: {session.ipAddress}</p>
            <p className="text-sm">Đăng nhập: {new Date(session.loginTime).toLocaleString()}</p>
            <p className="text-sm">Hoạt động gần nhất: {new Date(session.lastActiveAt || session.loginTime).toLocaleString()}</p>
          </div>
          <button disabled={busy} onClick={() => void revoke(session)} className="rounded-lg border px-3 py-2 disabled:opacity-50">Đăng xuất</button>
        </li>)}
      </ul>
      {(userId ? sessions.length > 0 : sessions.some(s => !s.isCurrentSession)) &&
        <button disabled={busy} onClick={() => void revoke()} className="mr-3 rounded-lg bg-red-700 px-4 py-2 text-white disabled:opacity-50">
          {userId ? 'Đăng xuất tất cả thiết bị' : 'Đăng xuất các thiết bị khác'}
        </button>}
    </>}
    <button disabled={busy || loading} onClick={() => void load()} className="mt-3 rounded-lg border px-3 py-2 disabled:opacity-50">Làm mới</button>
  </section>;
}
