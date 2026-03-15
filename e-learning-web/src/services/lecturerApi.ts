import { apiClient } from './apiClient';

type ApiObject = Record<string, unknown>;

const isApiObject = (value: unknown): value is ApiObject =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const toString = (value: unknown, fallback = ''): string => {
  if (typeof value === 'string') {
    return value;
  }

  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }

  return fallback;
};

const toNumber = (value: unknown, fallback = 0): number => {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === 'string') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  }

  return fallback;
};

const toArray = (payload: unknown): unknown[] => {
  if (Array.isArray(payload)) {
    return payload;
  }

  if (!isApiObject(payload)) {
    return [];
  }

  const data = payload['data'];
  if (Array.isArray(data)) {
    return data;
  }

  const items = payload['items'];
  if (Array.isArray(items)) {
    return items;
  }

  return [];
};

const toPagedList = <T>(
  payload: unknown,
  mapper: (item: unknown, index: number) => T
): { data: T[]; total: number } => {
  const data = toArray(payload).map((item, index) => mapper(item, index));

  if (!isApiObject(payload)) {
    return { data, total: data.length };
  }

  const rawTotal = payload['total'] ?? payload['totalCount'] ?? payload['count'];
  return {
    data,
    total: toNumber(rawTotal, data.length),
  };
};

// DTOs from backend
export interface LecturerDashboardStatsDto {
  totalCoursesTeaching: number;
  totalStudentsActive: number;
  averageCompletionRate: number;
  courseRevenueThisMonth: number;
  completionRateTrendPercentage: number;
  unreviewedQuizzes: number;
}

export interface LecturerCourseDto {
  id: string;
  title: string;
  description?: string;
  enrolledStudents: number;
  completionRate: number;
  rating: number;
  revenue: number;
  isPublished: boolean;
  createdAt: string;
}

export interface LecturerLessonDto {
  id: string;
  title: string;
  courseId: string;
  courseName: string;
  duration: number;
  completionRate: number;
}

export interface PendingQuizDto {
  id: string;
  title: string;
  courseId: string;
  courseName: string;
  studentCount: number;
  submissionCount: number;
}

export interface QuizSubmissionDto {
  id: string;
  studentId: string;
  studentName: string;
  quizTitle: string;
  score: number;
  maxScore: number;
  submittedAt: string;
  status: 'PENDING' | 'GRADED';
}

export interface StudentProgressDto {
  studentId: string;
  email: string;
  fullName: string;
  courseProgress: CourseProgressDetailDto[];
}

export interface CourseProgressDetailDto {
  courseId: string;
  courseName: string;
  completionPercentage: number;
  lessonsCompleted: number;
  totalLessons: number;
  averageQuizScore?: number;
  enrolledDate: string;
  completedDate?: string;
}

export interface LecturerAnalyticsDto {
  totalEnrollments: number;
  completionRate: number;
  averageQuizScore: number;
  totalRevenueGenerated: number;
  topCourse: string;
  topStudent: string;
  engagementTrend: EngagementPointDto[];
  dropoffPoints: DropoffPointDto[];
}

export interface EngagementPointDto {
  date: string;
  enrollments: number;
  completions: number;
}

export interface DropoffPointDto {
  lessonIndex: number;
  lessonsCompleted: number;
  totalStudents: number;
  dropoffPercentage: number;
}

export interface LecturerMessageDto {
  id: string;
  senderId: string;
  senderName: string;
  message: string;
  timestamp: string;
  isRead: boolean;
}

export interface GradeQuizSubmissionDto {
  score: number;
  feedback?: string;
}

export interface ZoomClassDto {
  id: string;
  title: string;
  courseId: string;
  courseName: string;
  zoomMeetingId: string;
  startTime: string;
  endTime: string;
  studentsAttended: number;
  recordingUrl?: string;
}

const mapStats = (payload: unknown): LecturerDashboardStatsDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    totalCoursesTeaching: toNumber(source['totalCoursesTeaching'], toNumber(source['TotalCoursesTeaching'])),
    totalStudentsActive: toNumber(source['totalStudentsActive'], toNumber(source['TotalStudentsActive'])),
    averageCompletionRate: toNumber(source['averageCompletionRate'], toNumber(source['AverageCompletionRate'])),
    courseRevenueThisMonth: toNumber(source['courseRevenueThisMonth'], toNumber(source['CourseRevenueThisMonth'])),
    completionRateTrendPercentage: toNumber(source['completionRateTrendPercentage'], toNumber(source['CompletionRateTrendPercentage'])),
    unreviewedQuizzes: toNumber(source['unreviewedQuizzes'], toNumber(source['UnreviewedQuizzes'])),
  };
};

const mapCourse = (payload: unknown, index = 0): LecturerCourseDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], toString(source['Id'], `course-${index + 1}`)),
    title: toString(source['title'], toString(source['Title'], '-')),
    description: toString(source['description'], toString(source['Description'])) || undefined,
    enrolledStudents: toNumber(source['enrolledStudents'], toNumber(source['EnrolledStudents'])),
    completionRate: toNumber(source['completionRate'], toNumber(source['CompletionRate'])),
    rating: toNumber(source['rating'], toNumber(source['Rating'])),
    revenue: toNumber(source['revenue'], toNumber(source['Revenue'])),
    isPublished: Boolean(source['isPublished'] ?? source['IsPublished']),
    createdAt: toString(source['createdAt'], toString(source['CreatedAt'], new Date().toISOString())),
  };
};

const mapLesson = (payload: unknown, index = 0): LecturerLessonDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], toString(source['Id'], `lesson-${index + 1}`)),
    title: toString(source['title'], toString(source['Title'], '-')),
    courseId: toString(source['courseId'], toString(source['CourseId'])),
    courseName: toString(source['courseName'], toString(source['CourseName'], '-')),
    duration: toNumber(source['duration']),
    completionRate: toNumber(source['completionRate'], toNumber(source['EngagementRate'])),
  };
};

const mapPendingQuiz = (payload: unknown, index = 0): PendingQuizDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], toString(source['Id'], `quiz-${index + 1}`)),
    title: toString(source['title'], toString(source['quizTitle'], toString(source['QuizTitle'], '-'))),
    courseId: toString(source['courseId'], toString(source['CourseId'])),
    courseName: toString(source['courseName'], toString(source['CourseName'], '-')),
    studentCount: toNumber(source['studentCount'], toNumber(source['PendingSubmissions'])),
    submissionCount: toNumber(source['submissionCount'], toNumber(source['GradedSubmissions'])),
  };
};

const mapQuizSubmission = (payload: unknown, index = 0): QuizSubmissionDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], toString(source['Id'], `submission-${index + 1}`)),
    studentId: toString(source['studentId']),
    studentName: toString(source['studentName'], toString(source['StudentName'], 'Unknown')),
    quizTitle: toString(source['quizTitle'], toString(source['QuizTitle'], '-')),
    score: toNumber(source['score'], toNumber(source['Score'])),
    maxScore: toNumber(source['maxScore'], 100),
    submittedAt: toString(source['submittedAt'], toString(source['SubmittedAt'], new Date().toISOString())),
    status: toString(source['status'], toString(source['Status'], 'PENDING')).toUpperCase() === 'GRADED' ? 'GRADED' : 'PENDING',
  };
};

const mapCourseProgress = (payload: unknown): CourseProgressDetailDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    courseId: toString(source['courseId'], toString(source['CourseId'])),
    courseName: toString(source['courseName'], toString(source['CourseName'], '-')),
    completionPercentage: toNumber(source['completionPercentage'], toNumber(source['CompletionPercentage'])),
    lessonsCompleted: toNumber(source['lessonsCompleted'], toNumber(source['LessonsCompleted'])),
    totalLessons: toNumber(source['totalLessons'], toNumber(source['TotalLessons'])),
    averageQuizScore: source['averageQuizScore'] !== undefined || source['AverageQuizScore'] !== undefined
      ? toNumber(source['averageQuizScore'], toNumber(source['AverageQuizScore']))
      : undefined,
    enrolledDate: toString(source['enrolledDate'], toString(source['EnrolledDate'], new Date().toISOString())),
    completedDate: source['completedDate'] || source['CompletedDate']
      ? toString(source['completedDate'] ?? source['CompletedDate'])
      : undefined,
  };
};

const mapStudentProgress = (payload: unknown, index = 0): StudentProgressDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    studentId: toString(source['studentId'], toString(source['StudentId'], `student-${index + 1}`)),
    email: toString(source['email'], toString(source['Email'])),
    fullName: toString(source['fullName'], toString(source['FullName'], 'Unknown')),
    courseProgress: toArray(source['courseProgress'] ?? source['CourseProgress']).map(mapCourseProgress),
  };
};

const mapAnalytics = (payload: unknown): LecturerAnalyticsDto => {
  const source = isApiObject(payload) ? payload : {};
  const lessonEngagement = toArray(source['lessonEngagement'] ?? source['LessonEngagement']);
  const dropoffSource = toArray(source['dropoffPoints'] ?? source['DropoffPoints']);
  const overallEngagementRate = toNumber(source['overallEngagementRate'], toNumber(source['OverallEngagementRate']));

  const engagementTrend = lessonEngagement.map((item, index) => {
    const lesson = isApiObject(item) ? item : {};
    const enrollments = toNumber(lesson['viewCount'], toNumber(lesson['ViewCount']));
    const lessonCompletionRate = toNumber(lesson['engagementRate'], toNumber(lesson['EngagementRate'], overallEngagementRate));

    return {
      date: toString(lesson['date'], `Lesson ${index + 1}`),
      enrollments,
      completions: Math.round((enrollments * lessonCompletionRate) / 100),
    };
  });

  const dropoffPoints = dropoffSource.map((item, index) => {
    const point = isApiObject(item) ? item : {};
    const dropped = toNumber(point['dropoffCount'], toNumber(point['DropoffCount']));

    return {
      lessonIndex: toNumber(point['lessonIndex'], index + 1),
      lessonsCompleted: 0,
      totalStudents: dropped,
      dropoffPercentage: toNumber(point['dropoffPercentage'], toNumber(point['dropoffRate'], toNumber(point['DropoffRate']))),
    };
  });

  const topLesson = lessonEngagement
    .map((item) => (isApiObject(item) ? item : {}))
    .sort((a, b) => toNumber(b['viewCount'], toNumber(b['ViewCount'])) - toNumber(a['viewCount'], toNumber(a['ViewCount'])))[0];

  return {
    totalEnrollments: engagementTrend.reduce((sum, point) => sum + point.enrollments, 0),
    completionRate: overallEngagementRate,
    averageQuizScore: 0,
    totalRevenueGenerated: 0,
    topCourse: toString(topLesson?.['lessonTitle'], toString(topLesson?.['LessonTitle'], '-')),
    topStudent: '-',
    engagementTrend,
    dropoffPoints,
  };
};

const mapMessage = (payload: unknown, index = 0): LecturerMessageDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], toString(source['Id'], `message-${index + 1}`)),
    senderId: toString(source['senderId'], toString(source['studentId'], toString(source['StudentId']))),
    senderName: toString(source['senderName'], toString(source['studentName'], toString(source['StudentName'], 'Student'))),
    message: toString(source['message'], toString(source['Message'])),
    timestamp: toString(source['timestamp'], toString(source['createdAt'], toString(source['CreatedAt'], new Date().toISOString()))),
    isRead: Boolean(source['isRead'] ?? source['IsRead']),
  };
};

const mapZoomClass = (payload: unknown, index = 0): ZoomClassDto => {
  const source = isApiObject(payload) ? payload : {};

  return {
    id: toString(source['id'], toString(source['Id'], `zoom-${index + 1}`)),
    title: toString(source['title'], toString(source['topic'], toString(source['Topic'], 'Zoom Class'))),
    courseId: toString(source['courseId'], toString(source['CourseId'])),
    courseName: toString(source['courseName'], toString(source['CourseName'], '-')),
    zoomMeetingId: toString(source['zoomMeetingId'], toString(source['id'], toString(source['Id']))),
    startTime: toString(source['startTime'], toString(source['scheduledAt'], toString(source['ScheduledAt'], new Date().toISOString()))),
    endTime: toString(source['endTime'], toString(source['scheduledAt'], toString(source['ScheduledAt'], new Date().toISOString()))),
    studentsAttended: toNumber(source['studentsAttended'], toNumber(source['expectedStudents'], toNumber(source['ExpectedStudents']))),
    recordingUrl: toString(source['recordingUrl']) || undefined,
  };
};

export const lecturerApi = {
  async getStats(): Promise<LecturerDashboardStatsDto> {
    const response = await apiClient('/lecturer/dashboard/stats', { method: 'GET' });
    return mapStats(response);
  },

  async getCourses(page: number = 1, pageSize: number = 20): Promise<{ data: LecturerCourseDto[]; total: number }> {
    const params = new URLSearchParams({
      page: page.toString(),
      pageSize: pageSize.toString(),
    });

    const response = await apiClient(`/lecturer/dashboard/courses?${params}`, { method: 'GET' });
    return toPagedList(response, mapCourse);
  },

  async getLessons(): Promise<LecturerLessonDto[]> {
    const response = await apiClient('/lecturer/dashboard/lessons', { method: 'GET' });
    return toArray(response).map(mapLesson);
  },

  async getPendingQuizzes(): Promise<PendingQuizDto[]> {
    const response = await apiClient('/lecturer/dashboard/pending-quizzes', { method: 'GET' });
    return toArray(response).map(mapPendingQuiz);
  },

  async getQuizSubmissions(quizId: string, status?: string): Promise<QuizSubmissionDto[]> {
    const params = status ? `?status=${status}` : '';

    const response = await apiClient(`/lecturer/dashboard/quizzes/${quizId}/submissions${params}`, { method: 'GET' });
    return toArray(response).map(mapQuizSubmission);
  },

  async getStudentProgress(): Promise<StudentProgressDto[]> {
    const response = await apiClient('/lecturer/dashboard/student-progress', { method: 'GET' });
    return toArray(response).map(mapStudentProgress);
  },

  async getStudentProgressDetail(studentId: string): Promise<StudentProgressDto | null> {
    const response = await apiClient(`/lecturer/dashboard/student-progress/${studentId}`, { method: 'GET' });

    if (!response) {
      return null;
    }

    return mapStudentProgress(response);
  },

  async getAnalytics(): Promise<LecturerAnalyticsDto> {
    const response = await apiClient('/lecturer/dashboard/analytics', { method: 'GET' });
    return mapAnalytics(response);
  },

  async getMessages(): Promise<LecturerMessageDto[]> {
    const response = await apiClient('/lecturer/dashboard/messages', { method: 'GET' });
    return toArray(response).map(mapMessage);
  },

  async gradeQuizSubmission(submissionId: string, data: GradeQuizSubmissionDto): Promise<void> {
    await apiClient(`/lecturer/dashboard/quizzes/${submissionId}/grade`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async getZoomSchedule(): Promise<ZoomClassDto[]> {
    const response = await apiClient('/lecturer/dashboard/zoom-schedule', { method: 'GET' });
    return toArray(response).map(mapZoomClass);
  },
};
