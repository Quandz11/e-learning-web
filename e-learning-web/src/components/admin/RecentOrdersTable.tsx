import React from 'react';
import { useTranslation } from 'react-i18next';

type OrderRow = {
  id: string;
  student: string;
  avatarUrl?: string;
  initials?: string;
  course: string;
  amount: string;
  status: 'paid' | 'pending' | 'failed';
  date: string;
};

const RecentOrdersTable: React.FC = () => {
  const { t } = useTranslation();

  const rows: OrderRow[] = [
    {
      id: '#1024',
      student: 'Mark Otto',
      avatarUrl:
        "https://lh3.googleusercontent.com/aida-public/AB6AXuBbSg_veYapDaEXFwzEaGgmISDLvROZgD0LWGySZxhWRLX3U02KYbe7q5Bcq3TzRYz5Si8UU-sZgvF5u8UHknCcevIyax-yiHGvWGgw5IGORg13odV3GcpBM91HXFnOGg_PZGCtgvczgFHC1FaYTpZRFKInOts7MQzHPoEQhpLV46h2T0opG7jgGChbx4DRDTnUsF85sPO4Gw91ngpYE2qU3R5-vN-S9NqF6PyzQYkdJxnkjRWMv32S8snx7SI9qTE0UI0Vwu4i6Q",
      course: 'Advanced React Patterns',
      amount: '49.000 VND',
      status: 'paid',
      date: 'Oct 24',
    },
    {
      id: '#1023',
      student: 'Sarah Connor',
      avatarUrl:
        "https://lh3.googleusercontent.com/aida-public/AB6AXuD_OoNcxe9pJquERjP4as0Wb15bTRa1vMR02aR2JhmxR7vpme5Nieohskiv4g62sBz3Mh5zTNdiF2zUIGBVsibz9nklo4PsYfJy0DEbDbMZq9IBu6fVv2DIa2cWvYZrasQZphnRPbG-QPeT2ZfzAaxGlTfBNrXnyzsIRFHnO2RQebtm84I0uPuGzzvD5Naw_FTIZ-JZqjKEIi42wE0Glj3Sfgl_nI8rS9IrcYRLQ4ql8rt-OO9m4IdJMME0N7RHRYyquYOQu2sDjg",
      course: 'UX Design Fundamentals',
      amount: '89.000 VND',
      status: 'pending',
      date: 'Oct 24',
    },
    {
      id: '#1022',
      student: 'Jacob Jones',
      avatarUrl:
        "https://lh3.googleusercontent.com/aida-public/AB6AXuC1QEDkywrtkoC_OPXc-dC3kzb54nAbClOfvEZQzdlokT1EgTAzpiqvef2YL7q_lPju-txBnYeL6zHtdU11o5CQwsXpIVe9NbYU-eYUFegcmxrZojS0YPjGPiVwTN81W0Jq6z-YAt6mfUjU5JhbrnYDFzVfRoSWxuIzcDl4eu8-Ul3BpjY2KTT-sYrpeMX4Mll2x2ErbtsuyhUVamBXqY-0GuaNpkGt7ArV9upFG2lyNyAwfSek75oaB_uT73yQaFrOe3vvM9KeGA",
      course: 'Python for Data Science',
      amount: '120.000 VND',
      status: 'paid',
      date: 'Oct 23',
    },
    {
      id: '#1021',
      student: 'Emily Davis',
      initials: 'ED',
      course: 'Digital Marketing 101',
      amount: '35.000 VND',
      status: 'failed',
      date: 'Oct 23',
    },
  ];

  const renderStatus = (status: OrderRow['status']) => {
    if (status === 'paid') {
      return (
        <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-100 bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-400">
          <span className="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>
          {t('admin.recentOrders.status.paid')}
        </span>
      );
    }

    if (status === 'pending') {
      return (
        <span className="inline-flex items-center gap-1.5 rounded-full border border-amber-100 bg-amber-50 px-2.5 py-1 text-xs font-medium text-amber-700 dark:border-amber-800 dark:bg-amber-900/20 dark:text-amber-400">
          <span className="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
          {t('admin.recentOrders.status.pending')}
        </span>
      );
    }

    return (
      <span className="inline-flex items-center gap-1.5 rounded-full border border-red-100 bg-red-50 px-2.5 py-1 text-xs font-medium text-red-700 dark:border-red-800 dark:bg-red-900/20 dark:text-red-400">
        <span className="h-1.5 w-1.5 rounded-full bg-red-500"></span>
        {t('admin.recentOrders.status.failed')}
      </span>
    );
  };

  return (
    <div className="flex flex-col gap-4 lg:col-span-2">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-bold text-slate-900 dark:text-white">{t('admin.recentOrders.title')}</h3>
        <a className="text-sm font-medium text-dashboard-primary hover:text-dashboard-primary-dark dark:text-blue-400 dark:hover:text-blue-300" href="#">{t('admin.recentOrders.viewAll')}</a>
      </div>
      <div className="overflow-hidden rounded-xl border border-slate-200 bg-dashboard-surface-light shadow-dashboard-subtle dark:border-slate-800 dark:bg-dashboard-surface-dark">
        <div className="md:hidden divide-y divide-slate-100 dark:divide-slate-800">
          {rows.map((row) => (
            <div key={row.id} className="p-4 space-y-3">
              <div className="flex items-start justify-between gap-2">
                <div>
                  <p className="font-semibold text-slate-900 dark:text-white">{row.id}</p>
                  <p className="text-xs text-slate-500">{row.date}</p>
                </div>
                {renderStatus(row.status)}
              </div>

              <div className="flex items-center gap-3">
                {row.avatarUrl ? (
                  <div className="h-9 w-9 rounded-full bg-slate-200 bg-cover" style={{ backgroundImage: `url('${row.avatarUrl}')` }}></div>
                ) : (
                  <div className="flex h-9 w-9 items-center justify-center rounded-full border border-dashboard-primary/20 bg-dashboard-primary/10 text-xs font-bold text-dashboard-primary">
                    {row.initials || row.student.charAt(0)}
                  </div>
                )}
                <div className="min-w-0">
                  <p className="text-sm font-medium text-slate-900 dark:text-white truncate">{row.student}</p>
                  <p className="text-xs text-slate-500 truncate">{row.course}</p>
                </div>
              </div>

              <p className="text-sm font-semibold text-dashboard-primary">{row.amount}</p>
            </div>
          ))}
        </div>

        <div className="hidden md:block overflow-x-auto">
          <table className="w-full text-left text-sm min-w-[760px]">
            <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500 dark:border-slate-800 dark:bg-slate-800/50">
              <tr>
                <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.orderId')}</th>
                <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.student')}</th>
                <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.course')}</th>
                <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.amount')}</th>
                <th className="px-6 py-4 font-semibold" scope="col">{t('admin.recentOrders.table.status')}</th>
                <th className="px-6 py-4 font-semibold text-right" scope="col">{t('admin.recentOrders.table.date')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
              {rows.map((row) => (
                <tr key={row.id} className="transition-colors hover:bg-slate-50 dark:hover:bg-slate-800/50">
                  <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">{row.id}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      {row.avatarUrl ? (
                        <div className="h-8 w-8 rounded-full bg-slate-200 bg-cover" style={{ backgroundImage: `url('${row.avatarUrl}')` }}></div>
                      ) : (
                        <div className="flex h-8 w-8 items-center justify-center rounded-full border border-dashboard-primary/20 bg-dashboard-primary/10 text-xs font-bold text-dashboard-primary">
                          {row.initials || row.student.charAt(0)}
                        </div>
                      )}
                      <span className="text-slate-700 dark:text-slate-300">{row.student}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-slate-600 dark:text-slate-400">{row.course}</td>
                  <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">{row.amount}</td>
                  <td className="px-6 py-4">{renderStatus(row.status)}</td>
                  <td className="px-6 py-4 text-right text-slate-500">{row.date}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default RecentOrdersTable;
