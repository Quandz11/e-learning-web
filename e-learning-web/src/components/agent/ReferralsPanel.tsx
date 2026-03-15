import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { agentApi, type ReferralDto } from '../../services/agentApi';

interface ReferralsPanelProps {
  limit?: number;
}

const ReferralsPanel: React.FC<ReferralsPanelProps> = ({ limit = 5 }) => {
  const { t } = useTranslation();
  const [referrals, setReferrals] = useState<ReferralDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('');

  useEffect(() => {
    const fetchReferrals = async () => {
      try {
        setLoading(true);
        const result = await agentApi.getReferrals(1, limit || 10, statusFilter || undefined);
        setReferrals(Array.isArray(result.data) ? result.data : []);
      } catch (err) {
        console.error('Failed to fetch referrals:', err);
        setError(err instanceof Error ? err.message : 'Failed to load referrals');
      } finally {
        setLoading(false);
      }
    };

    void fetchReferrals();
  }, [limit, statusFilter]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'PENDING':
        return '#FF9800';
      case 'APPROVED':
      case 'PAID':
        return '#4CAF50';
      case 'REJECTED':
        return '#F44336';
      default:
        return '#757575';
    }
  };

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

  return (
    <div className="agent-panel agent-referrals-panel">
      <div className="agent-panel-header">
        <h2>{t('admin.dashboard.agent.referrals')}</h2>
        <select 
          value={statusFilter} 
          onChange={(e) => setStatusFilter(e.target.value)}
          className="agent-filter-select"
        >
          <option value="">{t('admin.dashboard.agent.allStatuses')}</option>
          <option value="PENDING">{t('admin.dashboard.agent.pending')}</option>
          <option value="APPROVED">{t('admin.dashboard.agent.approved')}</option>
          <option value="REJECTED">{t('admin.dashboard.agent.rejected')}</option>
        </select>
      </div>

      {loading ? (
        <div className="agent-panel-loading">{t('common.loading')}</div>
      ) : (
        <div className="agent-referrals-list">
          {referrals.length === 0 ? (
            <p className="agent-no-data">{t('admin.dashboard.agent.noReferrals')}</p>
          ) : (
            <table className="agent-referrals-table">
              <thead>
                <tr>
                  <th>{t('admin.dashboard.agent.table.student')}</th>
                  <th>{t('admin.dashboard.agent.table.course')}</th>
                  <th>{t('admin.dashboard.agent.table.status')}</th>
                  <th>{t('admin.dashboard.agent.table.commission')}</th>
                  <th>{t('admin.dashboard.agent.table.date')}</th>
                </tr>
              </thead>
              <tbody>
                {referrals.map((referral) => (
                  <tr key={referral.id}>
                    <td>
                      <div className="agent-referral-student">
                        <div className="agent-referral-name">{referral.studentName}</div>
                        <div className="agent-referral-email">{referral.studentEmail}</div>
                        <div className="agent-referral-email">
                          {t('admin.dashboard.agent.table.agent')}: {referral.referrerName || '-'}
                        </div>
                      </div>
                    </td>
                    <td>{referral.enrolledCourseName}</td>
                    <td>
                      <span
                        className="agent-status-badge"
                        style={{ backgroundColor: getStatusColor(referral.status) }}
                      >
                        {referral.status}
                      </span>
                    </td>
                    <td className="agent-commission-amount">
                      {formatCurrency(referral.commissionAmount)} VND
                    </td>
                    <td>{new Date(referral.createdAt).toLocaleDateString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
};

export default ReferralsPanel;
