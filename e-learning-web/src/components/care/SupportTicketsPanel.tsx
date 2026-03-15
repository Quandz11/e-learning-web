import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { careApi, type SupportTicketDto } from '../../services/careApi';

interface SupportTicketsPanelProps {
  limit?: number;
}

const SupportTicketsPanel: React.FC<SupportTicketsPanelProps> = ({ limit = 5 }) => {
  const { t } = useTranslation();
  const [tickets, setTickets] = useState<SupportTicketDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchTickets = async () => {
      try {
        setLoading(true);
        const result = await careApi.getSupportTickets(1, limit || 10);
        setTickets(Array.isArray(result.data) ? result.data : []);
      } catch (err) {
        console.error('Failed to fetch support tickets:', err);
        setError(err instanceof Error ? err.message : 'Failed to load tickets');
      } finally {
        setLoading(false);
      }
    };

    void fetchTickets();
  }, [limit]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'OPEN':
        return '#2196F3';
      case 'IN_PROGRESS':
        return '#FF9800';
      case 'RESOLVED':
        return '#4CAF50';
      case 'CLOSED':
        return '#9E9E9E';
      default:
        return '#757575';
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'CRITICAL':
        return '#D32F2F';
      case 'HIGH':
        return '#F57C00';
      case 'MEDIUM':
        return '#FBC02D';
      case 'LOW':
        return '#388E3C';
      default:
        return '#757575';
    }
  };

  const formatDate = (value: string) => {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? '-' : parsed.toLocaleDateString();
  };

  if (error) {
    return <div className="care-panel-error">{error}</div>;
  }

  return (
    <div className="care-panel care-tickets-panel">
      <div className="care-panel-header">
        <h2>{t('admin.dashboard.care.supportTickets')}</h2>
      </div>

      {loading ? (
        <div className="care-panel-loading">{t('common.loading')}</div>
      ) : (
        <div className="care-tickets-list">
          {tickets.length === 0 ? (
            <p className="care-no-data">{t('admin.dashboard.care.noTickets')}</p>
          ) : (
            <table className="care-tickets-table">
              <thead>
                <tr>
                  <th>{t('admin.dashboard.care.table.ticketId')}</th>
                  <th>{t('admin.dashboard.care.table.title')}</th>
                  <th>{t('admin.dashboard.care.table.customer')}</th>
                  <th>{t('admin.dashboard.care.table.status')}</th>
                  <th>{t('admin.dashboard.care.table.priority')}</th>
                  <th>{t('admin.dashboard.care.table.createdAt')}</th>
                </tr>
              </thead>
              <tbody>
                {tickets.map((ticket) => (
                  <tr key={ticket.id || `${ticket.createdAt}-${ticket.title}`}>
                    <td className="care-ticket-id">#{(ticket.id || '').slice(0, 8)}</td>
                    <td>{ticket.title || '-'}</td>
                    <td>{ticket.customerName || '-'}</td>
                    <td>
                      <span
                        className="care-status-badge"
                        style={{ backgroundColor: getStatusColor(ticket.status || 'OPEN') }}
                      >
                        {ticket.status || 'OPEN'}
                      </span>
                    </td>
                    <td>
                      <span
                        className="care-priority-badge"
                        style={{ backgroundColor: getPriorityColor(ticket.priority || 'MEDIUM') }}
                      >
                        {ticket.priority || 'MEDIUM'}
                      </span>
                    </td>
                    <td>{formatDate(ticket.createdAt)}</td>
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

export default SupportTicketsPanel;
