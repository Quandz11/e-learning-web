import React from 'react';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import LeadRegistrationsPanel from '../../../components/leads/LeadRegistrationsPanel';

const AdminLeadRegistrationsPage: React.FC = () => {
  const { t } = useTranslation();

  return (
    <AdminLayout>
      <LeadRegistrationsPanel
        title={t('leadRegistrations.title', { defaultValue: 'Form đăng ký tư vấn' })}
        subtitle={t('leadRegistrations.subtitle', {
          defaultValue: 'Theo dõi và xử lý các đăng ký tư vấn từ trang chủ.',
        })}
      />
    </AdminLayout>
  );
};

export default AdminLeadRegistrationsPage;
