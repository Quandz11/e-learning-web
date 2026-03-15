import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { agentApi, type LeaderboardEntryDto } from '../../services/agentApi';

interface LeaderboardPanelProps {
  limit?: number;
}

const LeaderboardPanel: React.FC<LeaderboardPanelProps> = ({ limit = 5 }) => {
  const { t } = useTranslation();
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntryDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchLeaderboard = async () => {
      try {
        setLoading(true);
        const data = await agentApi.getLeaderboard();
        setLeaderboard(data.slice(0, limit || 100));
      } catch (err) {
        console.error('Failed to fetch leaderboard:', err);
        setError(err instanceof Error ? err.message : 'Failed to load leaderboard');
      } finally {
        setLoading(false);
      }
    };

    void fetchLeaderboard();
  }, [limit]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'decimal',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const getMedalEmoji = (rank: number) => {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '✢';
    }
  };

  if (error) {
    return <div className="agent-panel-error">{error}</div>;
  }

  return (
    <div className="agent-panel agent-leaderboard-panel">
      <div className="agent-panel-header">
        <h2>{t('admin.dashboard.agent.leaderboard')}</h2>
      </div>

      {loading ? (
        <div className="agent-panel-loading">{t('common.loading')}</div>
      ) : (
        <div className="agent-leaderboard-list">
          {leaderboard.length === 0 ? (
            <p className="agent-no-data">{t('admin.dashboard.agent.noLeaderboardData')}</p>
          ) : (
            <table className="agent-leaderboard-table">
              <thead>
                <tr>
                  <th>{t('admin.dashboard.agent.table.rank')}</th>
                  <th>{t('admin.dashboard.agent.table.agent')}</th>
                  <th>{t('admin.dashboard.agent.table.sales')}</th>
                  <th>{t('admin.dashboard.agent.table.students')}</th>
                  <th>{t('admin.dashboard.agent.table.commission')}</th>
                </tr>
              </thead>
              <tbody>
                {leaderboard.map((entry) => (
                  <tr key={entry.agentId} className={`rank-${entry.rank}`}>
                    <td className="agent-rank-cell">
                      <span className="agent-medal">{getMedalEmoji(entry.rank)}</span>
                      <span className="agent-rank-number">#{entry.rank}</span>
                    </td>
                    <td className="agent-agent-name">{entry.agentName}</td>
                    <td>{formatCurrency(entry.totalSales)} VND</td>
                    <td>{entry.studentCount}</td>
                    <td className="agent-commission-amount">
                      {formatCurrency(entry.commissionEarned)} VND
                    </td>
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

export default LeaderboardPanel;
