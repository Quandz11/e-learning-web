import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { lecturerApi, type LecturerCourseDto } from '../../services/lecturerApi';

interface CoursesPanelProps {
  limit?: number;
}

const CoursesPanel: React.FC<CoursesPanelProps> = ({ limit = 5 }) => {
  const { t } = useTranslation();
  const [courses, setCourses] = useState<LecturerCourseDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchCourses = async () => {
      try {
        setLoading(true);
        const result = await lecturerApi.getCourses(1, limit || 20);
        setCourses(Array.isArray(result.data) ? result.data : []);
      } catch (err) {
        console.error('Failed to fetch courses:', err);
        setError(err instanceof Error ? err.message : 'Failed to load courses');
      } finally {
        setLoading(false);
      }
    };

    void fetchCourses();
  }, [limit]);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'decimal',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  if (error) return <div className="lecturer-panel-error">{error}</div>;

  return (
    <div className="lecturer-panel lecturer-courses-panel">
      <div className="lecturer-panel-header">
        <h2>{t('admin.dashboard.lecturer.courses')}</h2>
      </div>

      {loading ? (
        <div className="lecturer-panel-loading">{t('common.loading')}</div>
      ) : (
        <div className="lecturer-courses-list">
          {courses.length === 0 ? (
            <p className="lecturer-no-data">{t('admin.dashboard.lecturer.noCourses')}</p>
          ) : (
            <table className="lecturer-courses-table">
              <thead>
                <tr>
                  <th>{t('admin.dashboard.lecturer.table.course')}</th>
                  <th>{t('admin.dashboard.lecturer.table.students')}</th>
                  <th>{t('admin.dashboard.lecturer.table.completion')}</th>
                  <th>{t('admin.dashboard.lecturer.table.revenue')}</th>
                </tr>
              </thead>
              <tbody>
                {courses.map((course) => (
                  <tr key={course.id || course.title}>
                    <td><strong>{course.title || '-'}</strong></td>
                    <td>{course.enrolledStudents ?? 0}</td>
                    <td>
                      <div className="lecturer-progress-bar">
                        <div
                          className="lecturer-progress-fill"
                          style={{ width: `${Math.max(0, Math.min(100, course.completionRate ?? 0))}%` }}
                        />
                      </div>
                      <span>{(course.completionRate ?? 0).toFixed(1)}%</span>
                    </td>
                    <td>{formatCurrency(course.revenue ?? 0)} VND</td>
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

export default CoursesPanel;
