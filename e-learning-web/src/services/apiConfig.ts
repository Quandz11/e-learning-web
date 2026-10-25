/**
 * Central API Configuration & High-Availability Failover Service
 * 
 * Primary: https://api.cabinthaidoc.com/api
 * Fallback: https://skvi-e-learning-api-service-arh3g4dsbxh5cna7.southeastasia-01.azurewebsites.net/api
 */

const normalizeUrl = (url?: string) => (url ? url.trim().replace(/\/+$/, '') : '');

export const DEFAULT_PRIMARY_API_URL = 'https://api.cabinthaidoc.com/api';
export const DEFAULT_FALLBACK_API_URL =
  'https://skvi-e-learning-api-service-arh3g4dsbxh5cna7.southeastasia-01.azurewebsites.net/api';

const resolvedPrimaryEnv = normalizeUrl(import.meta.env.VITE_API_PRIMARY_URL);
const resolvedLegacyEnv = normalizeUrl(import.meta.env.VITE_API_URL);
const resolvedFallbackEnv = normalizeUrl(import.meta.env.VITE_API_FALLBACK_URL);

// If legacy VITE_API_URL points to Azure, use it as fallback instead of overriding primary
const isLegacyAzure = resolvedLegacyEnv.includes('azurewebsites.net');

export const PRIMARY_API_URL =
  resolvedPrimaryEnv ||
  (!isLegacyAzure && resolvedLegacyEnv ? resolvedLegacyEnv : '') ||
  DEFAULT_PRIMARY_API_URL;

export const FALLBACK_API_URL =
  resolvedFallbackEnv ||
  (isLegacyAzure ? resolvedLegacyEnv : '') ||
  DEFAULT_FALLBACK_API_URL;

const FAILOVER_COOLDOWN_MS = 30_000; // 30s cooldown before retrying primary
let primaryUnavailableUntil = 0;

export const isUsingFallback = (): boolean => {
  return PRIMARY_API_URL !== FALLBACK_API_URL && Date.now() < primaryUnavailableUntil;
};

export const getActiveApiBaseUrl = (): string => {
  return isUsingFallback() ? FALLBACK_API_URL : PRIMARY_API_URL;
};

export const getRootUrl = (apiBase?: string): string => {
  const base = apiBase || getActiveApiBaseUrl();
  return base.replace(/\/api\/?$/, '');
};

export const getAssetUrl = (path?: string): string => {
  if (!path) return '';
  if (
    path.startsWith('http://') ||
    path.startsWith('https://') ||
    path.startsWith('blob:') ||
    path.startsWith('data:')
  ) {
    return path;
  }
  const root = getRootUrl();
  return `${root}${path.startsWith('/') ? '' : '/'}${path}`;
};

export const getHubUrl = (hubName: string, preferFallback = false): string => {
  const base = preferFallback ? FALLBACK_API_URL : getActiveApiBaseUrl();
  const root = getRootUrl(base);
  const cleanHub = hubName.replace(/^\/+/, '');
  const hubPath = cleanHub.startsWith('hubs/') ? cleanHub : `hubs/${cleanHub}`;
  return `${root}/${hubPath}`;
};

export const markPrimaryFailed = (reason?: unknown) => {
  if (PRIMARY_API_URL === FALLBACK_API_URL) return;
  primaryUnavailableUntil = Date.now() + FAILOVER_COOLDOWN_MS;
  console.warn(
    `[API Failover] Primary server (${PRIMARY_API_URL}) is unavailable (${String(reason)}). ` +
    `Switching to fallback: ${FALLBACK_API_URL} (cooldown: ${FAILOVER_COOLDOWN_MS / 1000}s)`
  );
};

export const markPrimaryHealthy = () => {
  if (primaryUnavailableUntil > 0) {
    console.info(
      `[API Failover] Primary server (${PRIMARY_API_URL}) recovered. Restored as active API.`
    );
    primaryUnavailableUntil = 0;
  }
};

export const isServerDownStatus = (status: number): boolean => {
  return status === 502 || status === 503 || status === 504;
};

export const shouldTriggerFallback = (error: unknown): boolean => {
  if (!error) return false;
  if (typeof error === 'object' && 'name' in error) {
    const errObj = error as { name?: string; message?: string };
    if (errObj.name === 'AbortError' || errObj.name === 'TypeError') return true;
  }
  const msg = String((error as { message?: string })?.message || error).toLowerCase();
  return (
    msg.includes('failed to fetch') ||
    msg.includes('network') ||
    msg.includes('timeout') ||
    msg.includes('connection') ||
    msg.includes('offline') ||
    msg.includes('err_')
  );
};

export interface FetchWithFallbackOptions extends RequestInit {
  timeoutMs?: number;
}

const executeSingleFetch = async (
  url: string,
  options: RequestInit,
  timeoutMs: number
): Promise<Response> => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  const originalSignal = options.signal;
  if (originalSignal) {
    if (originalSignal.aborted) {
      clearTimeout(timeoutId);
      throw new DOMException('Aborted', 'AbortError');
    }
    originalSignal.addEventListener('abort', () => controller.abort(), { once: true });
  }

  try {
    return await fetch(url, {
      ...options,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeoutId);
  }
};

export const fetchWithFallback = async (
  endpoint: string,
  options: FetchWithFallbackOptions = {}
): Promise<Response> => {
  const { timeoutMs = 60_000, ...fetchOptions } = options;

  const buildTargetUrl = (base: string) => {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      if (endpoint.startsWith(PRIMARY_API_URL)) {
        return endpoint.replace(PRIMARY_API_URL, base);
      }
      if (endpoint.startsWith(FALLBACK_API_URL)) {
        return endpoint.replace(FALLBACK_API_URL, base);
      }
      return endpoint;
    }
    const cleanEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
    return `${base}${cleanEndpoint}`;
  };

  const hasFallback = FALLBACK_API_URL && FALLBACK_API_URL !== PRIMARY_API_URL;
  const currentlyFailingOver = isUsingFallback();

  if (currentlyFailingOver && hasFallback) {
    const fallbackUrl = buildTargetUrl(FALLBACK_API_URL);
    try {
      return await executeSingleFetch(fallbackUrl, fetchOptions, timeoutMs);
    } catch (fallbackError) {
      console.warn('[API Failover] Fallback request failed, probing primary...', fallbackError);
      const primaryUrl = buildTargetUrl(PRIMARY_API_URL);
      const response = await executeSingleFetch(primaryUrl, fetchOptions, timeoutMs);
      markPrimaryHealthy();
      return response;
    }
  }

  const primaryUrl = buildTargetUrl(PRIMARY_API_URL);
  try {
    const response = await executeSingleFetch(primaryUrl, fetchOptions, timeoutMs);

    if (isServerDownStatus(response.status) && hasFallback) {
      markPrimaryFailed(`HTTP ${response.status}`);
      const fallbackUrl = buildTargetUrl(FALLBACK_API_URL);
      return await executeSingleFetch(fallbackUrl, fetchOptions, timeoutMs);
    }

    markPrimaryHealthy();
    return response;
  } catch (primaryError: unknown) {
    if (shouldTriggerFallback(primaryError) && hasFallback) {
      const errorMsg =
        (primaryError as { message?: string })?.message || 'Network error';
      markPrimaryFailed(errorMsg);
      const fallbackUrl = buildTargetUrl(FALLBACK_API_URL);
      return await executeSingleFetch(fallbackUrl, fetchOptions, timeoutMs);
    }
    throw primaryError;
  }
};
