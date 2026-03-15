import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { agentApi, type CommissionBreakdownDto } from '../../services/agentApi';

const CommissionPanel: React.FC = () => {
  const { t } = useTranslation();
  const [commission, setCommission] = useState<CommissionBreakdownDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchCommission = async () => {
      try {
        setLoading(true);
        const data = await agentApi.getCommission();
        setCommission(data);
      } catch (err) {
        console.error('Failed to fetch commission:', err);
        setError(err instanceof Error ? err.message : 'Failed to load commission data');
      } finally {
        setLoading(false);
      }
    };

    void fetchCommission();
  }, []);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'decimal',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  if (error) {
    return <div className="agent-panel-error">{error}</div>;
  }

  if (!commission) {
    return <div className="agent-panel-loading">{t('common.loading')}</div>;
  }

  const paidPercentage = commission.totalCommission > 0 
    ? (commission.paidCommission / commission.totalCommission) * 100 
    : 0;

  return (
    <div className="agent-panel agent-commission-panel">
      <div className="agent-panel-header">
        <h2>{t('admin.dashboard.agent.commission')}</h2>
      </div>

      {loading ? (
        <div className="agent-panel-loading">{t('common.loading')}</div>
      ) : (
        <div className="agent-commission-content">
          <div className="agent-commission-cards">
            <div className="agent-commission-card">
              <div className="agent-commission-label">{t('admin.dashboard.agent.totalCommission')}</div>
              <div className="agent-commission-value">
                {formatCurrency(commission.totalCommission)} VND
              </div>
            </div>

            <div className="agent-commission-card">
              <div className="agent-commission-label">{t('admin.dashboard.agent.paidCommission')}</div>
              <div className="agent-commission-value agent-commission-paid">
                {formatCurrency(commission.paidCommission)} VND
              </div>
            </div>

            <div className="agent-commission-card">
              <div className="agent-commission-label">{t('admin.dashboard.agent.pendingCommission')}</div>
              <div className="agent-commission-value agent-commission-pending">
                {formatCurrency(commission.pendingCommission)} VND
              </div>
            </div>

            <div className="agent-commission-card">
              <div className="agent-commission-label">{t('admin.dashboard.agent.monthlyAverage')}</div>
              <div className="agent-commission-value">
                {formatCurrency(commission.monthlyAverage)} VND
              </div>
            </div>
          </div>

          <div className="agent-commission-progress">
            <h3>{t('admin.dashboard.agent.payoutStatus')}</h3>
            <div className="agent-progress-bar">
              <div
                className="agent-progress-fill"
                style={{ width: `${paidPercentage}%` }}
              />
            </div>
            <div className="agent-progress-stats">
              <span>{formatCurrency(commission.paidCommission)} / {formatCurrency(commission.totalCommission)}</span>
              <span>{paidPercentage.toFixed(1)}% {t('admin.dashboard.agent.paid')}</span>
            </div>
          </div>

          <div className="agent-commission-history">
            <h3>{t('admin.dashboard.agent.payoutHistory')}</h3>
            <table className="agent-history-table">
              <thead>
                <tr>
                  <th>{t('admin.dashboard.agent.table.period')}</th>
                  <th>{t('admin.dashboard.agent.table.amount')}</th>
                  <th>{t('admin.dashboard.agent.table.status')}</th>
                  <th>{t('admin.dashboard.agent.table.payoutDate')}</th>
                </tr>
              </thead>
              <tbody>
                {commission.payoutHistory.map((history) => (
                  <tr key={history.id}>
                    <td>
                      {new Date(history.fromDate).toLocaleDateString()} -
                      {new Date(history.toDate).toLocaleDateString()}
                    </td>
                    <td>{formatCurrency(history.amount)} VND</td>
                    <td>
                      <span
                        className={`agent-payout-status ${history.status.toLowerCase()}`}
                      >
                        {history.status}
                      </span>
                    </td>
                    <td>
                      {history.payoutDate
                        ? new Date(history.payoutDate).toLocaleDateString()
                        : '-'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default CommissionPanel;
