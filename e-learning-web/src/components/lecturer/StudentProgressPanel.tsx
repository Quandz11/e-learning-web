import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { lecturerApi, type StudentProgressDto } from '../../services/lecturerApi';

interface StudentProgressPanelProps {
  limit?: number;
}

const StudentProgressPanel: React.FC<StudentProgressPanelProps> = ({ limit = 5 }) => {
  const { t } = useTranslation();
  const [students, setStudents] = useState<StudentProgressDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchProgress = async () => {
      try {
        setLoading(true);
        const data = await lecturerApi.getStudentProgress();
        setStudents(Array.isArray(data) ? data.slice(0, limit || 100) : []);
      } catch (err) {
        console.error('Failed to fetch student progress:', err);
        setError(err instanceof Error ? err.message : 'Failed to load student progress');
      } finally {
        setLoading(false);
      }
    };

    void fetchProgress();
  }, [limit]);

  if (error) return <div className="lecturer-panel-error">{error}</div>;

  return (
    <div className="lecturer-panel lecturer-students-panel">
      <div className="lecturer-panel-header">
        <h2>{t('admin.dashboard.lecturer.studentProgress')}</h2>
      </div>

      {loading ? (
        <div className="lecturer-panel-loading">{t('common.loading')}</div>
      ) : (
        <div className="lecturer-students-list">
          {students.length === 0 ? (
            <p className="lecturer-no-data">{t('admin.dashboard.lecturer.noStudents')}</p>
          ) : (
            <div className="lecturer-student-cards">
              {students.map((student) => (
                <div key={student.studentId || student.email} className="lecturer-student-card">
                  <h4>{student.fullName || student.email || '-'}</h4>
                  <p className="lecturer-student-email">{student.email || '-'}</p>
                  <div className="lecturer-student-courses">
                    {(student.courseProgress || []).slice(0, 3).map((course, idx) => (
                      <div key={idx} className="lecturer-course-item">
                        <span className="lecturer-course-name">{course.courseName || '-'}</span>
                        <div className="lecturer-mini-progress">
                          <div
                            className="lecturer-mini-progress-fill"
                            style={{ width: `${Math.max(0, Math.min(100, course.completionPercentage ?? 0))}%` }}
                          />
                        </div>
                        <span className="lecturer-course-percent">{(course.completionPercentage ?? 0).toFixed(0)}%</span>
                      </div>
                    ))}
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

export default StudentProgressPanel;
