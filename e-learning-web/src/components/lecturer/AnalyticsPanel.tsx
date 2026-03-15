import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { lecturerApi, type LecturerAnalyticsDto } from '../../services/lecturerApi';

const AnalyticsPanel: React.FC = () => {
  const { t } = useTranslation();
  const [analytics, setAnalytics] = useState<LecturerAnalyticsDto | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        const data = await lecturerApi.getAnalytics();
        setAnalytics(data);
      } catch (err) {
        console.error('Failed to fetch analytics:', err);
        setError(err instanceof Error ? err.message : 'Failed to load analytics');
      }
    };

    void fetchAnalytics();
  }, []);

  if (error) return <div className="lecturer-panel-error">{error}</div>;
  if (!analytics) return <div className="lecturer-panel-loading">{t('common.loading')}</div>;

  const completionRate = Number.isFinite(analytics.completionRate) ? analytics.completionRate : 0;
  const avgQuizScore = Number.isFinite(analytics.averageQuizScore) ? analytics.averageQuizScore : 0;
  const totalRevenue = Number.isFinite(analytics.totalRevenueGenerated) ? analytics.totalRevenueGenerated : 0;
  const totalEnrollments = Number.isFinite(analytics.totalEnrollments) ? analytics.totalEnrollments : 0;
  const dropoffPoints = Array.isArray(analytics.dropoffPoints) ? analytics.dropoffPoints : [];

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'decimal',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  return (
    <div className="lecturer-panel lecturer-analytics-panel">
      <div className="lecturer-panel-header">
        <h2>{t('admin.dashboard.lecturer.analytics')}</h2>
      </div>

      <div className="lecturer-analytics-cards">
        <div className="lecturer-analytics-card">
          <span className="lecturer-analytics-label">{t('admin.dashboard.lecturer.totalEnrollments')}</span>
          <span className="lecturer-analytics-value">{totalEnrollments}</span>
        </div>
        <div className="lecturer-analytics-card">
          <span className="lecturer-analytics-label">{t('admin.dashboard.lecturer.completionRate')}</span>
          <span className="lecturer-analytics-value">{completionRate.toFixed(1)}%</span>
        </div>
        <div className="lecturer-analytics-card">
          <span className="lecturer-analytics-label">{t('admin.dashboard.lecturer.avgQuizScore')}</span>
          <span className="lecturer-analytics-value">{avgQuizScore.toFixed(1)}/100</span>
        </div>
        <div className="lecturer-analytics-card">
          <span className="lecturer-analytics-label">{t('admin.dashboard.lecturer.totalRevenue')}</span>
          <span className="lecturer-analytics-value">{formatCurrency(totalRevenue)}</span>
        </div>
      </div>

      <div className="lecturer-analytics-details">
        <div className="lecturer-details-section">
          <h3>{t('admin.dashboard.lecturer.topPerformance')}</h3>
          <p><strong>{t('admin.dashboard.lecturer.topCourse')}:</strong> {analytics.topCourse || '-'}</p>
          <p><strong>{t('admin.dashboard.lecturer.topStudent')}:</strong> {analytics.topStudent || '-'}</p>
        </div>

        <div className="lecturer-details-section">
          <h3>{t('admin.dashboard.lecturer.dropoffAnalysis')}</h3>
          {dropoffPoints.length === 0 ? (
            <p className="lecturer-no-data">{t('admin.dashboard.lecturer.noDropoff')}</p>
          ) : (
            <table className="lecturer-dropoff-table">
              <thead>
                <tr>
                  <th>{t('admin.dashboard.lecturer.lesson')}</th>
                  <th>{t('admin.dashboard.lecturer.studentsDropped')}</th>
                  <th>{t('admin.dashboard.lecturer.dropoffRate')}</th>
                </tr>
              </thead>
              <tbody>
                {dropoffPoints.map((point, idx) => (
                  <tr key={idx}>
                    <td>Lesson {point.lessonIndex ?? idx + 1}</td>
                    <td>{Math.max(0, (point.totalStudents ?? 0) - (point.lessonsCompleted ?? 0))}</td>
                    <td>{(point.dropoffPercentage ?? 0).toFixed(1)}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
};

export default AnalyticsPanel;
