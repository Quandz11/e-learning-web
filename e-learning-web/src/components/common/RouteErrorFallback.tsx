import { Link, isRouteErrorResponse, useRouteError } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const RouteErrorFallback = () => {
  const error = useRouteError();
  const { t } = useTranslation();

  let statusCode: number | null = null;
  let statusText = t('common.error');

  if (isRouteErrorResponse(error)) {
    statusCode = error.status;
    statusText = error.statusText || statusText;
  } else if (error instanceof Error && error.message) {
    statusText = error.message;
  }

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center px-4">
      <div className="w-full max-w-lg rounded-2xl border border-slate-200 bg-white p-8 shadow-sm text-center">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">
          {statusCode ? `Error ${statusCode}` : 'Unexpected Error'}
        </p>
        <h1 className="mt-4 text-2xl font-semibold text-slate-900">
          {t('common.error')}
        </h1>
        <p className="mt-3 text-slate-600 break-words">{statusText}</p>

        <div className="mt-8 flex flex-col sm:flex-row gap-3 justify-center">
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="px-4 py-2 rounded-lg bg-slate-900 text-white hover:bg-slate-800 transition-colors"
          >
            {t('common.reload', 'Reload page')}
          </button>
          <Link
            to="/"
            className="px-4 py-2 rounded-lg border border-slate-300 text-slate-700 hover:bg-slate-100 transition-colors"
          >
            {t('common.home', 'Home')}
          </Link>
        </div>
      </div>
    </div>
  );
};

export default RouteErrorFallback;
