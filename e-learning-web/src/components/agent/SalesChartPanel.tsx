import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { agentApi, type SalesDataDto } from '../../services/agentApi';

interface SalesChartPanelProps {
  fullscreen?: boolean;
}

const SalesChartPanel: React.FC<SalesChartPanelProps> = ({ fullscreen = false }) => {
  const { t } = useTranslation();
  const [salesData, setSalesData] = useState<SalesDataDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [month, setMonth] = useState(new Date().getMonth());

  useEffect(() => {
    const fetchSalesData = async () => {
      try {
        setLoading(true);
        const data = await agentApi.getSalesChart(month);
        setSalesData(data);
      } catch (err) {
        console.error('Failed to fetch sales chart:', err);
        setError(err instanceof Error ? err.message : 'Failed to load sales data');
      } finally {
        setLoading(false);
      }
    };

    void fetchSalesData();
  }, [month]);

  const maxAmount = Math.max(...salesData.map(d => d.amount), 1);
  const avgAmount = salesData.length > 0 ? salesData.reduce((sum, d) => sum + d.amount, 0) / salesData.length : 0;

  const formatChartLabel = (value: string, index: number) => {
    const parsedDate = new Date(value);
    if (!Number.isNaN(parsedDate.getTime())) {
      return parsedDate.getDate();
    }

    return value || index + 1;
  };

  if (error) {
    return <div className="agent-panel-error">{error}</div>;
  }

  return (
    <div className={`agent-panel agent-sales-panel ${fullscreen ? 'fullscreen' : ''}`}>
      <div className="agent-panel-header">
        <h2>{t('admin.dashboard.agent.salesChart')}</h2>
        <select value={month} onChange={(e) => setMonth(parseInt(e.target.value))} className="agent-month-select">
          {Array.from({ length: 12 }, (_, i) => (
            <option key={i} value={i}>
              {new Date(2024, i).toLocaleString('default', { month: 'long' })}
            </option>
          ))}
        </select>
      </div>

      {loading ? (
        <div className="agent-panel-loading">{t('common.loading')}</div>
      ) : (
        <div className="agent-sales-chart">
          {salesData.length === 0 ? (
            <p className="agent-no-data">{t('admin.dashboard.agent.noData')}</p>
          ) : (
            <>
              <div className="agent-chart-bars">
                {salesData.map((item, index) => {
                  const height = maxAmount > 0 ? (item.amount / maxAmount) * 100 : 0;
                  return (
                    <div key={index} className="agent-chart-bar-container">
                      <div
                        className="agent-chart-bar"
                        style={{ height: `${height}%` }}
                        title={`${item.date || `Point ${index + 1}`}: ${item.amount.toLocaleString()} VND (${item.count} sales)`}
                      />
                      <span className="agent-chart-label">{formatChartLabel(item.date, index)}</span>
                    </div>
                  );
                })}
              </div>
              <div className="agent-chart-stats">
                <div className="agent-chart-stat">
                  <span className="agent-chart-stat-label">{t('admin.dashboard.agent.max')}:</span>
                  <span className="agent-chart-stat-value">{maxAmount.toLocaleString()} VND</span>
                </div>
                <div className="agent-chart-stat">
                  <span className="agent-chart-stat-label">{t('admin.dashboard.agent.average')}:</span>
                  <span className="agent-chart-stat-value">{avgAmount.toLocaleString()} VND</span>
                </div>
                <div className="agent-chart-stat">
                  <span className="agent-chart-stat-label">{t('admin.dashboard.agent.total')}:</span>
                  <span className="agent-chart-stat-value">
                    {salesData.reduce((sum, d) => sum + d.amount, 0).toLocaleString()} VND
                  </span>
                </div>
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
};

export default SalesChartPanel;
