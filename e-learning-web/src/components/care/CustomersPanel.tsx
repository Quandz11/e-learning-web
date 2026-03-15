import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { careApi, type CareCustomerDto } from '../../services/careApi';

interface CustomersPanelProps {
  limit?: number;
}

const CustomersPanel: React.FC<CustomersPanelProps> = ({ limit = 5 }) => {
  const { t } = useTranslation();
  const [customers, setCustomers] = useState<CareCustomerDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');

  useEffect(() => {
    const fetchCustomers = async () => {
      try {
        setLoading(true);
        const result = await careApi.getCustomers(1, limit || 20, search);
        setCustomers(Array.isArray(result.data) ? result.data : []);
      } catch (err) {
        console.error('Failed to fetch customers:', err);
        setError(err instanceof Error ? err.message : 'Failed to load customers');
      } finally {
        setLoading(false);
      }
    };

    // Debounce search
    const timer = setTimeout(() => {
      void fetchCustomers();
    }, 300);

    return () => clearTimeout(timer);
  }, [limit, search]);

  if (error) {
    return <div className="care-panel-error">{error}</div>;
  }

  return (
    <div className="care-panel care-customers-panel">
      <div className="care-panel-header">
        <h2>{t('admin.dashboard.care.customers')}</h2>
        <input
          type="text"
          placeholder={t('admin.dashboard.care.searchPlaceholder')}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="care-search-input"
        />
      </div>

      {loading ? (
        <div className="care-panel-loading">{t('common.loading')}</div>
      ) : (
        <div className="care-customers-list">
          {customers.length === 0 ? (
            <p className="care-no-data">{t('admin.dashboard.care.noCustomers')}</p>
          ) : (
            <div className="care-customer-cards">
              {customers.map((customer) => (
                <div key={customer.id || customer.email} className="care-customer-card">
                  <div className="care-customer-avatar">
                    {(() => {
                      const safeName = customer.fullName || customer.email || 'User';

                      if (customer.avatarUrl) {
                        return <img src={customer.avatarUrl} alt={safeName} />;
                      }

                      return (
                        <div className="care-avatar-placeholder">
                          {safeName.charAt(0).toUpperCase()}
                        </div>
                      );
                    })()}
                  </div>
                  <div className="care-customer-info">
                    <h3>{customer.fullName || customer.email || '-'}</h3>
                    <p className="care-customer-email">{customer.email || '-'}</p>
                    <div className="care-customer-stats">
                      <span className="care-stat">
                        {t('admin.dashboard.care.enrolledCourses')}: {customer.enrolledCourses ?? 0}
                      </span>
                      <span className="care-stat">
                        {t('admin.dashboard.care.supportTickets')}: {customer.supportTickets ?? 0}
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default CustomersPanel;
